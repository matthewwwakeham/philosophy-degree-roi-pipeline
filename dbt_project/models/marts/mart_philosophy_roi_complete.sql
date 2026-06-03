{{ config(materialized='view') }}

SELECT
    -- Attributes from Demographics Dimension
    fct.person_age,
    dim_dem.age_bracket,

    -- Attributes from Education Dimension
    dim_edu.primary_degree_title,
    dim_edu.secondary_degree_title,

    -- Attributes from Occupations Dimension
    dim_occ.occupation_title,
    
    -- Status Fields from Fact
    fct.employment_status_code,
    fct.employment_status_desc,

    -- Metrics from Fact
    fct.estimated_sample_population,
    fct.total_weighted_wages_pool,
    fct.wage_earning_population_pool,

    -- Dynamic Calculation (Guarantees mathematical accuracy at any grain)
    ROUND(
        fct.total_weighted_wages_pool / NULLIF(fct.wage_earning_population_pool, 0), 
        2
    ) AS weighted_average_annual_wages

FROM {{ ref('fct_earnings_response') }} fct
LEFT JOIN {{ ref('dim_demographics') }} dim_dem 
    ON fct.person_age = dim_dem.person_age
LEFT JOIN {{ ref('dim_education') }} dim_edu 
    ON fct.education_key = dim_edu.education_key
LEFT JOIN {{ ref('dim_occupations') }} dim_occ 
    ON fct.occupation_key = dim_occ.occupation_key