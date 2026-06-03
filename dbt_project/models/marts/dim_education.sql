{{ config(materialized='table') }}

WITH staging_acs AS (
    SELECT DISTINCT primary_degree_code, secondary_degree_code 
    FROM {{ ref('stg_acs_philosophy') }}
    WHERE educational_attainment_code = '21'
),
degree_map AS (
    SELECT TO_VARCHAR(code) AS degree_code, degree_title 
    FROM {{ ref('degree_lookup') }}
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['acs.primary_degree_code', 'acs.secondary_degree_code']) }} AS education_key,
    acs.primary_degree_code,
    acs.secondary_degree_code,
    COALESCE(d1.degree_title, 'Unknown/Unmapped Degree') AS primary_degree_title,
    COALESCE(d2.degree_title, 'No Secondary Degree') AS secondary_degree_title
FROM staging_acs acs
LEFT JOIN degree_map d1 ON acs.primary_degree_code = d1.degree_code
LEFT JOIN degree_map d2 ON acs.secondary_degree_code = d2.degree_code