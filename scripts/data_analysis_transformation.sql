``` MySQL

-- -----------------------------------------------------------------------
-- Monthly Agregation ----------------------------------------------------
-- -----------------------------------------------------------------------

CREATE TABLE monthly_data AS
WITH monthly_data AS (
	SELECT
		CAST(DATE_FORMAT(date, '%Y-%m-01') AS DATE) AS month_date,
		branch_id,
		employee_id,
		MAX(salary) AS monthly_salary,
        MAX(resign_date) AS resign_date,
		DATEDIFF(MAX(resign_date), MIN(join_date)) AS tenure,
		SUM(working_hours) AS total_working_hours,
		AVG(working_hours) AS avg_working_hours,
		COUNT(DISTINCT date) AS active_days,
		COUNT(DISTINCT date)/22 AS attendance_rate
	FROM mekari_cleansed_data
	GROUP BY month_date, branch_id, employee_id
),
norm_monthly AS(
	SELECT
		*,
		((total_working_hours - MIN(total_working_hours)OVER(PARTITION BY month_date)) / 
			NULLIF((MAX(total_working_hours) OVER(PARTITION BY month_date) - MIN(total_working_hours) OVER(PARTITION BY month_date)), 0)) 
            AS norm_hours,
		((attendance_rate - MIN(attendance_rate) OVER(PARTITION BY month_date)) / 
			NULLIF((MAX(attendance_rate) OVER(PARTITION BY month_date) - MIN(attendance_rate) OVER(PARTITION BY month_date)), 0)) 
            AS norm_attendance_rate
	FROM monthly_data
)
SELECT
	*,
    (norm_hours * 0.5) + (norm_attendance_rate * 0.5) AS monthly_employee_score
FROM norm_monthly;


-- -----------------------------------------------------------------------
-- Layoff Decision -------------------------------------------------------
-- -----------------------------------------------------------------------

CREATE TABLE layoff_result AS
WITH overall_data AS (
	SELECT
		branch_id,
		employee_id,
		MAX(monthly_salary) AS salary,
		MAX(tenure) AS tenure,
		AVG(monthly_employee_score) as avg_score,
		CASE 
            WHEN MAX(resign_date) < (SELECT MAX(resign_date) FROM mekari_cleansed_data)
            THEN 'Already Resigned'
            ELSE 'Active'
        END AS employment_status
	FROM monthly_data
	GROUP BY branch_id, employee_id
),
norm_overall AS (
	SELECT 
		*,
		(tenure - MIN(tenure) OVER()) /
			NULLIF((MAX(tenure) OVER() - MIN(tenure) OVER()), 0) 
			AS norm_tenure,
		(avg_score - MIN(avg_score) OVER()) /
			NULLIF((MAX(avg_score) OVER() - MIN(avg_score) OVER()), 0)
			AS norm_score
	FROM overall_data
),
overall_score AS (
	SELECT
		*,
		(norm_tenure * 0.2 + norm_score *0.8) AS overall_score
	FROM norm_overall
),
employee_status AS (
	SELECT
		*,
		CASE 
			WHEN PERCENT_RANK() OVER(ORDER BY overall_score) >= 0.8 THEN 'High Performer'
			WHEN PERCENT_RANK() OVER(ORDER BY overall_score) >= 0.2 THEN 'Standard'
			ELSE 'Low Performer'
		END AS employee_status
	FROM overall_score
)
SELECT
	*,
    CASE 
		WHEN salary >= (AVG(salary) OVER()) AND  employee_status = 'Low Performer' THEN 'Priority Layoff'
        WHEN salary < (AVG(salary) OVER()) AND  employee_status = 'Low Performer' THEN 'Standard Layoff'
        ELSE 'Retained'
	END AS layoff_decision
FROM employee_status;



-- -----------------------------------------------------------------------
-- Branch Scoring --------------------------------------------------------
-- -----------------------------------------------------------------------

CREATE TABLE branch_result2 AS
WITH branch_monthly AS (
    SELECT
        month_date,
        branch_id,
        COUNT(DISTINCT employee_id)                                    AS total_employee,
        SUM(total_working_hours)                                       AS total_hours,
        SUM(monthly_salary)                                            AS total_salary,
        COUNT(DISTINCT employee_id) * 176                              AS standard_hours
    FROM monthly_data
    GROUP BY month_date, branch_id
),
branch_agg AS (
    SELECT 
        branch_id,
        SUM(total_salary) / NULLIF(SUM(total_hours), 0)               AS avg_cph,
        SUM(total_hours) / NULLIF(SUM(standard_hours), 0)             AS avg_util,
        SUM(total_salary) / NULLIF(SUM(total_employee), 0)            AS avg_payroll_burden
    FROM branch_monthly
    GROUP BY branch_id
),
branch_norm AS (
    SELECT
        *,
        1 - ((avg_cph - MIN(avg_cph) OVER()) /
            NULLIF(MAX(avg_cph) OVER() - MIN(avg_cph) OVER(), 0))     AS norm_cph,
        (avg_util - MIN(avg_util) OVER()) /
            NULLIF(MAX(avg_util) OVER() - MIN(avg_util) OVER(), 0)    AS norm_util,
        1 - ((avg_payroll_burden - MIN(avg_payroll_burden) OVER()) /
            NULLIF(MAX(avg_payroll_burden) OVER() - MIN(avg_payroll_burden) OVER(), 0))
                                                                       AS norm_payroll_burden
    FROM branch_agg
)
SELECT
    *,
    (norm_cph * 0.45) + (norm_util * 0.35) + (norm_payroll_burden * 0.20) AS branch_score,
    CASE
        WHEN PERCENT_RANK() OVER(ORDER BY 
            (norm_cph * 0.45) + (norm_util * 0.35) + (norm_payroll_burden * 0.20)
        ) >= 0.8 THEN 'High Efficient'
        WHEN PERCENT_RANK() OVER(ORDER BY 
            (norm_cph * 0.45) + (norm_util * 0.35) + (norm_payroll_burden * 0.20)
        ) >= 0.2 THEN 'Operational'
        ELSE 'Underperforming'
    END AS branch_status
FROM branch_norm;
```
