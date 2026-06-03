{{ config(materialized='table') }}

WITH staging_acs AS (
    SELECT DISTINCT occupation_code FROM {{ ref('stg_acs_philosophy') }}
    WHERE educational_attainment_code = '21'
),
occupation_map AS (
    SELECT TO_VARCHAR(code) AS occupation_code, occupation_title 
    FROM {{ ref('occupation_lookup') }}
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['acs.occupation_code']) }} AS occupation_key,
    acs.occupation_code,
    COALESCE(occ.occupation_title, 'Unknown/Unmapped Occupation') AS occupation_title
FROM staging_acs acs
LEFT JOIN occupation_map occ ON acs.occupation_code = occ.occupation_code