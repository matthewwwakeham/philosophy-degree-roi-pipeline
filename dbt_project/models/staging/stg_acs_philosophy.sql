{{ config(materialized='table') }}

WITH raw_source AS (
    SELECT raw_payload FROM philosophy_roi.staging.acs_json_raw
)

SELECT
    raw_payload:SERIALNO::STRING AS housing_serial_number,
    raw_payload:SPORDER::INT     AS person_number,
    raw_payload:PWGTP::INT       AS person_weight,
    raw_payload:FOD1P::STRING    AS primary_degree_code,
    raw_payload:FOD2P::STRING    AS secondary_degree_code,
    raw_payload:SCHL::STRING     AS educational_attainment_code,
    raw_payload:OCCP::STRING     AS occupation_code,
    raw_payload:WAGP::INT        AS wages_salary_income,
    raw_payload:ESR::STRING      AS employment_status_code,
    raw_payload:AGEP::INT        AS person_age
FROM 
    raw_source