-- ============================================================
-- FINANCIAL BUDGET & EXPENSE VARIANCE ANALYSIS
-- MySQL
-- ============================================================

CREATE DATABASE IF NOT EXISTS financial_budget_analysis;
USE financial_budget_analysis;


-- ============================================================
-- 1. RAW TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS budget_expenses (
    transaction_id VARCHAR(50),
    transaction_date DATE,
    department VARCHAR(50),
    category VARCHAR(50),
    region VARCHAR(50),
    budget_amount DECIMAL(15,2),
    actual_amount DECIMAL(15,2),
    payment_method VARCHAR(50)
);


-- ============================================================
-- 2. RAW DATA VALIDATION
-- ============================================================

SELECT COUNT(*) AS raw_records
FROM budget_expenses;

-- Check duplicate records
SELECT
    transaction_id,
    transaction_date,
    department,
    category,
    region,
    budget_amount,
    actual_amount,
    payment_method,
    COUNT(*) AS duplicate_count
FROM budget_expenses
GROUP BY
    transaction_id,
    transaction_date,
    department,
    category,
    region,
    budget_amount,
    actual_amount,
    payment_method
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Check missing / blank values
SELECT
    SUM(transaction_id IS NULL OR TRIM(transaction_id) = '') AS missing_transaction_id,
    SUM(transaction_date IS NULL) AS missing_date,
    SUM(department IS NULL OR TRIM(department) = '') AS missing_department,
    SUM(category IS NULL OR TRIM(category) = '') AS missing_category,
    SUM(region IS NULL OR TRIM(region) = '') AS missing_region,
    SUM(budget_amount IS NULL) AS missing_budget,
    SUM(actual_amount IS NULL) AS missing_actual,
    SUM(payment_method IS NULL OR TRIM(payment_method) = '') AS missing_payment_method
FROM budget_expenses;


-- ============================================================
-- 3. CLEAN ANALYTICAL TABLE
-- ============================================================

DROP TABLE IF EXISTS budget_expenses_clean;

CREATE TABLE budget_expenses_clean AS
SELECT DISTINCT
    NULLIF(TRIM(transaction_id), '') AS transaction_id,
    transaction_date,
    COALESCE(NULLIF(TRIM(department), ''), 'Unknown') AS department,
    COALESCE(NULLIF(TRIM(category), ''), 'Unknown') AS category,
    COALESCE(NULLIF(TRIM(region), ''), 'Unknown') AS region,
    budget_amount,
    actual_amount,
    COALESCE(NULLIF(TRIM(payment_method), ''), 'Unknown') AS payment_method
FROM budget_expenses;


-- ============================================================
-- 4. CLEAN DATA VALIDATION
-- ============================================================

SELECT COUNT(*) AS clean_records
FROM budget_expenses_clean;


SELECT
    transaction_id,
    transaction_date,
    department,
    category,
    region,
    budget_amount,
    actual_amount,
    payment_method,
    COUNT(*) AS duplicate_count
FROM budget_expenses_clean
GROUP BY
    transaction_id,
    transaction_date,
    department,
    category,
    region,
    budget_amount,
    actual_amount,
    payment_method
HAVING COUNT(*) > 1;


SELECT
    SUM(department = 'Unknown') AS unknown_department,
    SUM(category = 'Unknown') AS unknown_category,
    SUM(region = 'Unknown') AS unknown_region,
    SUM(payment_method = 'Unknown') AS unknown_payment_method
FROM budget_expenses_clean;


-- ============================================================
-- BUSINESS ANALYSIS
-- ============================================================


-- ============================================================
-- Q1. HOW MANY CLEANED RECORDS ARE IN THE DATASET?
-- ============================================================

SELECT
    COUNT(*) AS total_records
FROM budget_expenses_clean;


-- ============================================================
-- Q2. WHAT IS THE TOTAL BUDGET, ACTUAL SPENDING,
--     VARIANCE AND VARIANCE PERCENTAGE?
-- ============================================================

SELECT
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    SUM(actual_amount - budget_amount) AS total_variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct,
    ROUND(
        SUM(actual_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS budget_utilization_pct
FROM budget_expenses_clean;


-- ============================================================
-- Q3. HOW MANY TRANSACTIONS WERE OVER BUDGET
--     VERSUS UNDER BUDGET?
-- ============================================================

SELECT
    CASE
        WHEN actual_amount > budget_amount THEN 'Unfavorable'
        WHEN actual_amount < budget_amount THEN 'Favorable'
        ELSE 'On Budget'
    END AS variance_status,
    COUNT(*) AS transaction_count
FROM budget_expenses_clean
GROUP BY variance_status
ORDER BY transaction_count DESC;


-- ============================================================
-- Q4. WHICH DEPARTMENTS HAVE THE HIGHEST BUDGET VARIANCE?
-- ============================================================

SELECT
    department,
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    SUM(actual_amount - budget_amount) AS variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
GROUP BY department
ORDER BY variance DESC;


-- ============================================================
-- Q5. WHICH DEPARTMENT HAS THE HIGHEST
--     BUDGET UTILIZATION?
-- ============================================================

SELECT
    department,
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    ROUND(
        SUM(actual_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS budget_utilization_pct
FROM budget_expenses_clean
GROUP BY department
ORDER BY budget_utilization_pct DESC;


-- ============================================================
-- Q6. WHICH EXPENSE CATEGORIES CONTRIBUTE MOST
--     TO OVERSPENDING?
-- ============================================================

SELECT
    category,
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    SUM(actual_amount - budget_amount) AS variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
GROUP BY category
ORDER BY variance DESC;


-- ============================================================
-- Q7. WHAT PERCENTAGE OF TOTAL UNFAVORABLE VARIANCE
--     COMES FROM EACH CATEGORY?
-- ============================================================

WITH category_variance AS (
    SELECT
        category,
        SUM(actual_amount - budget_amount) AS variance
    FROM budget_expenses_clean
    GROUP BY category
),
unfavorable_total AS (
    SELECT
        SUM(variance) AS total_unfavorable_variance
    FROM category_variance
    WHERE variance > 0
)
SELECT
    cv.category,
    cv.variance,
    ROUND(
        cv.variance
        / NULLIF(ut.total_unfavorable_variance, 0) * 100,
        2
    ) AS contribution_pct
FROM category_variance cv
CROSS JOIN unfavorable_total ut
WHERE cv.variance > 0
ORDER BY contribution_pct DESC;


-- ============================================================
-- Q8. WHICH REGIONS ARE EXCEEDING THEIR BUDGETS?
-- ============================================================

SELECT
    region,
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    SUM(actual_amount - budget_amount) AS variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
GROUP BY region
HAVING SUM(actual_amount - budget_amount) > 0
ORDER BY variance DESC;


-- ============================================================
-- Q9. HOW DOES BUDGET VS ACTUAL SPENDING
--     CHANGE EACH MONTH?
-- ============================================================

SELECT
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS month,
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    SUM(actual_amount - budget_amount) AS variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY
    year,
    month;


-- ============================================================
-- Q10. WHICH MONTHS HAD THE LARGEST
--      UNFAVORABLE VARIANCE?
-- ============================================================

SELECT
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS month,
    SUM(budget_amount) AS budget,
    SUM(actual_amount) AS actual,
    SUM(actual_amount - budget_amount) AS variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date)
HAVING SUM(actual_amount - budget_amount) > 0
ORDER BY variance DESC
LIMIT 10;


-- ============================================================
-- Q11. WHICH DEPARTMENT-CATEGORY COMBINATIONS
--      HAVE THE HIGHEST VARIANCE?
-- ============================================================

SELECT
    department,
    category,
    SUM(budget_amount) AS total_budget,
    SUM(actual_amount) AS total_actual,
    SUM(actual_amount - budget_amount) AS variance,
    ROUND(
        SUM(actual_amount - budget_amount)
        / NULLIF(SUM(budget_amount), 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
GROUP BY
    department,
    category
ORDER BY variance DESC
LIMIT 10;


-- ============================================================
-- Q12. RANK DEPARTMENTS BASED ON UNFAVORABLE VARIANCE
-- ============================================================

WITH department_summary AS (
    SELECT
        department,
        SUM(budget_amount) AS total_budget,
        SUM(actual_amount) AS total_actual,
        SUM(actual_amount - budget_amount) AS variance
    FROM budget_expenses_clean
    GROUP BY department
)
SELECT
    department,
    total_budget,
    total_actual,
    variance,
    RANK() OVER (ORDER BY variance DESC) AS variance_rank
FROM department_summary
WHERE variance > 0
ORDER BY variance_rank;


-- ============================================================
-- Q13. WHICH DEPARTMENTS CONSISTENTLY EXCEED
--      THEIR MONTHLY BUDGETS?
-- ============================================================

WITH monthly_department AS (
    SELECT
        department,
        YEAR(transaction_date) AS year,
        MONTH(transaction_date) AS month,
        SUM(budget_amount) AS budget,
        SUM(actual_amount) AS actual
    FROM budget_expenses_clean
    GROUP BY
        department,
        YEAR(transaction_date),
        MONTH(transaction_date)
)
SELECT
    department,
    COUNT(*) AS months_observed,
    SUM(
        CASE
            WHEN actual > budget THEN 1
            ELSE 0
        END
    ) AS months_over_budget,
    ROUND(
        SUM(
            CASE
                WHEN actual > budget THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS pct_months_over_budget
FROM monthly_department
GROUP BY department
ORDER BY pct_months_over_budget DESC;


-- ============================================================
-- Q14. TOP 10 INDIVIDUAL TRANSACTIONS
--      WITH THE LARGEST OVERSPEND
-- ============================================================

SELECT
    transaction_id,
    transaction_date,
    department,
    category,
    region,
    budget_amount,
    actual_amount,
    actual_amount - budget_amount AS variance,
    ROUND(
        (actual_amount - budget_amount)
        / NULLIF(budget_amount, 0) * 100,
        2
    ) AS variance_pct
FROM budget_expenses_clean
WHERE actual_amount > budget_amount
ORDER BY variance DESC
LIMIT 10;


-- ============================================================
-- Q15. COMPARE EACH DEPARTMENT'S ACTUAL SPENDING
--      WITH THE PREVIOUS MONTH
-- ============================================================

WITH monthly_department AS (
    SELECT
        department,
        DATE_FORMAT(transaction_date, '%Y-%m') AS month,
        SUM(actual_amount) AS actual
    FROM budget_expenses_clean
    GROUP BY
        department,
        DATE_FORMAT(transaction_date, '%Y-%m')
),
department_with_previous AS (
    SELECT
        department,
        month,
        actual,
        LAG(actual) OVER (
            PARTITION BY department
            ORDER BY month
        ) AS previous_month_actual
    FROM monthly_department
)
SELECT
    department,
    month,
    actual,
    previous_month_actual,
    ROUND(
        (actual - previous_month_actual)
        / NULLIF(previous_month_actual, 0) * 100,
        2
    ) AS mom_growth_pct
FROM department_with_previous
ORDER BY
    department,
    month;


-- ============================================================
-- Q16. WHICH CATEGORIES CONTRIBUTE MOST
--      TO TOTAL ACTUAL SPENDING?
-- ============================================================

SELECT
    category,
    SUM(actual_amount) AS total_actual,
    ROUND(
        SUM(actual_amount)
        / NULLIF(
            (SELECT SUM(actual_amount)
             FROM budget_expenses_clean),
            0
        ) * 100,
        2
    ) AS spending_contribution_pct
FROM budget_expenses_clean
GROUP BY category
ORDER BY total_actual DESC;


