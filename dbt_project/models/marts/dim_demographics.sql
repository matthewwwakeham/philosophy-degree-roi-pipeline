{{ config(materialized='table') }}

WITH staging_acs AS (
    SELECT DISTINCT person_age FROM {{ ref('stg_acs_philosophy') }}
    WHERE educational_attainment_code = '21' AND person_age IS NOT NULL
)
SELECT
    person_age,
    CASE 
        WHEN person_age BETWEEN 22 AND 30 THEN '22-30 (Early Career)'
        WHEN person_age BETWEEN 31 AND 45 THEN '31-45 (Mid Career)'
        WHEN person_age BETWEEN 46 AND 60 THEN '46-60 (Late Career)'
        ELSE '61+ (Senior/Retirement)'
    END AS age_bracket
FROM staging_acs