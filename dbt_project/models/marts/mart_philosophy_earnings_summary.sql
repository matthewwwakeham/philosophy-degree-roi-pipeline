{{ config(materialized='table') }}

WITH staging_acs AS (
    SELECT * FROM {{ ref('stg_acs_philosophy') }}
),

-- Pre-sanitize the data layer to convert Census alphabetic flags into clean numbers or NULLs
cleaned_acs AS (
    SELECT
        housing_serial_number,
        primary_degree_code,
        secondary_degree_code,
        occupation_code,
        employment_status_code,
        TRY_TO_NUMBER(person_number) AS person_number,
        TRY_TO_NUMBER(person_weight) AS person_weight,
        TRY_TO_NUMBER(wages_salary_income) AS wages_salary_income,
        TRY_TO_NUMBER(person_age) AS person_age
    FROM staging_acs
),

degree_map AS (
    SELECT 
        code::STRING AS degree_code, 
        degree_title 
    FROM {{ ref('degree_lookup') }}
),

occupation_map AS (
    SELECT 
        code::STRING AS occupation_code, 
        occupation_title 
    FROM {{ ref('occupation_lookup') }}
)

SELECT
    -- Dimensional Attributes for Grouping
    acs.person_age,
    
    CASE 
        WHEN acs.person_age BETWEEN 22 AND 30 THEN '22-30 (Early Career)'
        WHEN acs.person_age BETWEEN 31 AND 45 THEN '31-45 (Mid Career)'
        WHEN acs.person_age BETWEEN 46 AND 60 THEN '46-60 (Late Career)'
        ELSE '61+ (Senior/Retirement)'
    END AS age_bracket,

    COALESCE(d1.degree_title, 'Unknown/Unmapped Degree') AS primary_degree_title,
    COALESCE(d2.degree_title, 'No Secondary Degree') AS secondary_degree_title,
    COALESCE(occ.occupation_title, 'Unknown/Unmapped Occupation') AS occupation_title,
    
    -- Status Filters
    acs.employment_status_code,
    CASE 
        WHEN acs.employment_status_code = '1' THEN 'Employed'
        WHEN acs.employment_status_code = '2' THEN 'Unemployed'
        WHEN acs.employment_status_code = '3' THEN 'Not in Labor Force'
        ELSE 'Unknown'
    END AS employment_status_desc,

    -- Population Telemetry
    SUM(acs.person_weight) AS estimated_sample_population,

    -- Financial ROI Metrics (Safely handling NULLs using the cleaned numeric inputs)
    SUM(
        CASE 
            WHEN acs.employment_status_code = '1' AND acs.wages_salary_income > 0 
            THEN acs.wages_salary_income * acs.person_weight 
            ELSE 0 
        END
    ) AS total_weighted_wages_pool,

    SUM(
        CASE 
            WHEN acs.employment_status_code = '1' AND acs.wages_salary_income > 0 
            THEN acs.person_weight 
            ELSE 0 
        END
    ) AS wage_earning_population_pool,

    ROUND(
        SUM(
            CASE 
                WHEN acs.employment_status_code = '1' AND acs.wages_salary_income > 0 
                THEN acs.wages_salary_income * acs.person_weight 
                ELSE 0 
            END
        ) / 
        NULLIF(
            SUM(
                CASE 
                    WHEN acs.employment_status_code = '1' AND acs.wages_salary_income > 0 
                    THEN acs.person_weight 
                    ELSE 0 
                END
            ), 0
        ), 2
    ) AS weighted_average_annual_wages

FROM 
    cleaned_acs acs
LEFT JOIN 
    degree_map d1 ON acs.primary_degree_code = d1.degree_code
LEFT JOIN 
    degree_map d2 ON acs.secondary_degree_code = d2.degree_code
LEFT JOIN 
    occupation_map occ ON acs.occupation_code = occ.occupation_code

GROUP BY 
    1, 2, 3, 4, 5, 6