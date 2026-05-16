-- ============================================================
-- Pharma R&D Pipeline & Clinical Trial Success Analysis
-- Dataset: ClinicalTrials.gov Data (Kaggle)
-- Author: Rachit Bhatt | MBA Finance & Business Analytics, DTU
-- Tool: SQLite / PostgreSQL / MySQL compatible
-- ============================================================
-- HOW TO USE:
-- 1. Run clinical_trials_analysis.py first to generate
--    clinical_trials_analysis.db with clean data loaded
-- 2. Open in DB Browser for SQLite or DBeaver
-- 3. Run each query block individually
-- ============================================================


-- ============================================================
-- QUERY 1: TRIAL VOLUME & COMPLETION RATE BY PHASE
-- Business Question: How does the R&D pipeline narrow across phases?
-- Insight: Identifies where most attrition occurs in the funnel
-- ============================================================

SELECT
    phase_clean                                                         AS phase,
    COUNT(*)                                                            AS total_trials,
    SUM(CASE WHEN status_clean = 'Completed'  THEN 1 ELSE 0 END)       AS completed,
    SUM(CASE WHEN status_clean = 'Terminated' THEN 1 ELSE 0 END)       AS terminated,
    SUM(CASE WHEN status_clean = 'Active'     THEN 1 ELSE 0 END)       AS active,
    ROUND(
        SUM(CASE WHEN status_clean = 'Completed' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS completion_rate_pct,
    ROUND(
        SUM(CASE WHEN status_clean = 'Terminated' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS termination_rate_pct
FROM clinical_trials
WHERE phase_clean IN ('Phase 1','Phase 2','Phase 3','Phase 4')
GROUP BY phase_clean
ORDER BY phase_clean;


-- ============================================================
-- QUERY 2: THERAPEUTIC AREA — TRIAL VOLUME & PHASE 3 SUCCESS
-- Business Question: Which disease areas have the best shot at approval?
-- Insight: R&D investment allocation by risk-adjusted success rate
-- ============================================================

SELECT
    therapeutic_area,
    COUNT(*)                                                            AS total_trials,
    SUM(CASE WHEN phase_clean = 'Phase 1' THEN 1 ELSE 0 END)           AS phase1_trials,
    SUM(CASE WHEN phase_clean = 'Phase 2' THEN 1 ELSE 0 END)           AS phase2_trials,
    SUM(CASE WHEN phase_clean = 'Phase 3' THEN 1 ELSE 0 END)           AS phase3_trials,
    SUM(CASE WHEN phase_clean = 'Phase 3'
             AND status_clean = 'Completed' THEN 1 ELSE 0 END)         AS phase3_completed,
    ROUND(
        SUM(CASE WHEN phase_clean = 'Phase 3'
                 AND status_clean = 'Completed' THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN phase_clean = 'Phase 3' THEN 1 ELSE 0 END), 0)
        * 100, 1
    )                                                                   AS phase3_success_pct
FROM clinical_trials
GROUP BY therapeutic_area
ORDER BY total_trials DESC
LIMIT 12;


-- ============================================================
-- QUERY 3: PIPELINE FUNNEL — PHASE PROGRESSION RATES
-- Business Question: What % of Phase 1 trials make it to Phase 3?
-- Insight: Classic pharma funnel — used in R&D budget modelling
-- ============================================================

WITH phase_counts AS (
    SELECT
        phase_clean,
        COUNT(*) AS trials
    FROM clinical_trials
    WHERE phase_clean IN ('Phase 1','Phase 2','Phase 3','Phase 4')
    GROUP BY phase_clean
),
phase1_total AS (
    SELECT trials AS p1 FROM phase_counts WHERE phase_clean = 'Phase 1'
)
SELECT
    pc.phase_clean                                                      AS phase,
    pc.trials                                                           AS total_trials,
    ROUND(pc.trials * 100.0 / pt.p1, 1)                                AS pct_of_phase1,
    ROUND(
        pc.trials * 100.0
        / NULLIF(LAG(pc.trials) OVER (ORDER BY pc.phase_clean), 0), 1
    )                                                                   AS progression_from_prior_pct
FROM phase_counts pc, phase1_total pt
ORDER BY pc.phase_clean;


-- ============================================================
-- QUERY 4: SPONSOR CONCENTRATION ANALYSIS
-- Business Question: Which companies run the most trials?
-- Insight: Market concentration and R&D competitiveness
-- ============================================================

WITH sponsor_stats AS (
    SELECT
        sponsor,
        COUNT(*)                                                            AS total_trials,
        SUM(CASE WHEN status_clean = 'Completed'  THEN 1 ELSE 0 END)       AS completed,
        SUM(CASE WHEN status_clean = 'Terminated' THEN 1 ELSE 0 END)       AS terminated,
        ROUND(AVG(enrollment), 0)                                           AS avg_enrollment,
        COUNT(DISTINCT therapeutic_area)                                    AS therapy_areas_covered
    FROM clinical_trials
    WHERE sponsor != 'Unknown' AND sponsor IS NOT NULL
    GROUP BY sponsor
),
grand_total AS (SELECT SUM(total_trials) AS gt FROM sponsor_stats)
SELECT
    sponsor,
    total_trials,
    completed,
    terminated,
    avg_enrollment,
    therapy_areas_covered,
    ROUND(total_trials * 100.0 / (SELECT gt FROM grand_total), 2)           AS market_share_pct,
    CASE
        WHEN total_trials >= 100 THEN 'Large Pharma'
        WHEN total_trials >= 20  THEN 'Mid-size Biotech'
        ELSE 'Small / Academic'
    END                                                                     AS sponsor_tier
FROM sponsor_stats
ORDER BY total_trials DESC
LIMIT 15;


-- ============================================================
-- QUERY 5: ENROLLMENT SIZE ANALYSIS BY THERAPEUTIC AREA
-- Business Question: Which trials require the most participants?
-- Insight: Trial complexity and cost estimation
-- ============================================================

SELECT
    therapeutic_area,
    COUNT(*)                                AS total_trials,
    ROUND(AVG(enrollment), 0)              AS avg_enrollment,
    ROUND(MIN(enrollment), 0)              AS min_enrollment,
    ROUND(MAX(enrollment), 0)              AS max_enrollment,
    ROUND(SUM(enrollment) / 1000.0, 1)    AS total_participants_k,
    CASE
        WHEN AVG(enrollment) >= 1000 THEN 'Large Scale (1000+)'
        WHEN AVG(enrollment) >= 200  THEN 'Mid Scale (200-999)'
        WHEN AVG(enrollment) >= 50   THEN 'Small Scale (50-199)'
        ELSE 'Very Small (<50)'
    END                                    AS trial_scale
FROM clinical_trials
WHERE enrollment IS NOT NULL AND enrollment > 0
GROUP BY therapeutic_area
ORDER BY avg_enrollment DESC;


-- ============================================================
-- QUERY 6: TERMINATION RATE BY AREA & PHASE
-- Business Question: Where does R&D investment go to waste?
-- Insight: Risk flags for biotech investors and R&D allocators
-- ============================================================

SELECT
    therapeutic_area,
    phase_clean                                                             AS phase,
    COUNT(*)                                                                AS total_trials,
    SUM(CASE WHEN status_clean = 'Terminated' THEN 1 ELSE 0 END)           AS terminated_trials,
    ROUND(
        SUM(CASE WHEN status_clean = 'Terminated' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                       AS termination_rate_pct,
    CASE
        WHEN SUM(CASE WHEN status_clean = 'Terminated' THEN 1.0 ELSE 0 END)
             / COUNT(*) * 100 >= 40 THEN 'High Risk'
        WHEN SUM(CASE WHEN status_clean = 'Terminated' THEN 1.0 ELSE 0 END)
             / COUNT(*) * 100 >= 20 THEN 'Medium Risk'
        ELSE 'Lower Risk'
    END                                                                     AS risk_tier
FROM clinical_trials
WHERE phase_clean IN ('Phase 2','Phase 3')
GROUP BY therapeutic_area, phase_clean
HAVING total_trials >= 5
ORDER BY termination_rate_pct DESC
LIMIT 15;


-- ============================================================
-- QUERY 7: YEAR-OVER-YEAR TRIAL STARTS TREND
-- Business Question: Is clinical trial activity growing?
-- Insight: Industry R&D investment trend over time
-- ============================================================

SELECT
    start_year,
    COUNT(*)                                                            AS trials_started,
    COUNT(DISTINCT therapeutic_area)                                    AS areas_active,
    COUNT(DISTINCT sponsor)                                             AS sponsors_active,
    ROUND(AVG(enrollment), 0)                                          AS avg_enrollment,
    LAG(COUNT(*)) OVER (ORDER BY start_year)                           AS prior_year_count,
    ROUND(
        (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY start_year)) * 100.0
        / NULLIF(LAG(COUNT(*)) OVER (ORDER BY start_year), 0), 1
    )                                                                   AS yoy_growth_pct
FROM clinical_trials
WHERE start_year IS NOT NULL
  AND start_year BETWEEN 2000 AND 2024
GROUP BY start_year
ORDER BY start_year;


-- ============================================================
-- QUERY 8: RARE DISEASE vs COMMON DISEASE — RISK COMPARISON
-- Business Question: Do orphan drug incentives offset higher risk?
-- Insight: Policy and investment implications for biotech clients
-- ============================================================

SELECT
    CASE
        WHEN therapeutic_area = 'Rare Disease' THEN 'Rare Disease'
        ELSE 'Common Disease'
    END                                                                 AS disease_type,
    COUNT(*)                                                            AS total_trials,
    ROUND(AVG(enrollment), 0)                                          AS avg_enrollment,
    ROUND(
        SUM(CASE WHEN status_clean = 'Completed' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS completion_rate_pct,
    ROUND(
        SUM(CASE WHEN status_clean = 'Terminated' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS termination_rate_pct,
    ROUND(
        SUM(CASE WHEN phase_clean = 'Phase 3'
                 AND status_clean = 'Completed' THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN phase_clean = 'Phase 3' THEN 1 ELSE 0 END), 0)
        * 100, 1
    )                                                                   AS phase3_success_pct
FROM clinical_trials
GROUP BY disease_type;


-- ============================================================
-- EXECUTIVE SUMMARY VIEW — for Power BI or stakeholder deck
-- ============================================================

SELECT 'Total Trials Analysed'         AS metric, COUNT(*)                      AS value FROM clinical_trials
UNION ALL
SELECT 'Unique Sponsors',               COUNT(DISTINCT sponsor)                  FROM clinical_trials
UNION ALL
SELECT 'Therapeutic Areas Covered',     COUNT(DISTINCT therapeutic_area)         FROM clinical_trials
UNION ALL
SELECT 'Overall Completion Rate %',     ROUND(SUM(CASE WHEN status_clean = 'Completed' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) FROM clinical_trials
UNION ALL
SELECT 'Overall Termination Rate %',    ROUND(SUM(CASE WHEN status_clean = 'Terminated' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) FROM clinical_trials
UNION ALL
SELECT 'Avg Phase 3 Enrollment',        ROUND(AVG(enrollment), 0)               FROM clinical_trials WHERE phase_clean = 'Phase 3' AND enrollment > 0;
