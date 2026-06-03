{{ config(materialized='table') }}

WITH staging_acs AS (
    SELECT * FROM {{ ref('stg_acs_philosophy') }}
),
sanitized_acs AS (
    SELECT
        primary_degree_code,
        secondary_degree_code,
        occupation_code,
        employment_status_code,
        TRY_TO_NUMBER(person_weight) AS person_weight,
        TRY_TO_NUMBER(wages_salary_income) AS wages_salary_income,
        TRY_TO_NUMBER(person_age) AS person_age
    FROM staging_acs
    WHERE educational_attainment_code = '21'
)
SELECT
    -- Surrogate Keys to join out to your new Dimension tables
    {{ dbt_utils.generate_surrogate_key(['acs.primary_degree_code', 'acs.secondary_degree_code']) }} AS education_key,
    {{ dbt_utils.generate_surrogate_key(['acs.occupation_code']) }} AS occupation_key,
    acs.person_age, -- natural join key to dim_demographics
    
    -- Status Code
    acs.employment_status_code,
    CASE 
        WHEN acs.employment_status_code = '1' THEN 'Employed'
        WHEN acs.employment_status_code = '2' THEN 'Unemployed'
        WHEN acs.employment_status_code = '3' THEN 'Not in Labor Force'
        ELSE 'Unknown'
    END AS employment_status_desc,

    -- Population Telemetry
    SUM(acs.person_weight) AS estimated_sample_population,

    -- Financial Pools
    SUM(CASE WHEN acs.employment_status_code = '1' AND acs.wages_salary_income > 0 THEN acs.wages_salary_income * acs.person_weight ELSE 0 END) AS total_weighted_wages_pool,
    SUM(CASE WHEN acs.employment_status_code = '1' AND acs.wages_salary_income > 0 THEN acs.person_weight ELSE 0 END) AS wage_earning_population_pool

FROM sanitized_acs acs
GROUP BY 1, 2, 3, 4, 5