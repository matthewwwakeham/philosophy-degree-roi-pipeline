# American Community Survey (ACS) Philosophy Degree ROI Pipeline

-- 1. Create the database container
CREATE OR REPLACE DATABASE PHILOSOPHY_ROI;

-- 2. Create the staging schema container
CREATE OR REPLACE SCHEMA PHILOSOPHY_ROI.STAGING;

-- 3. Create the dedicated virtual warehouse for computation
CREATE OR REPLACE WAREHOUSE ROI_INGEST_WH WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 4. Create the raw variant table where Python drops the JSON blobs
CREATE OR REPLACE TABLE PHILOSOPHY_ROI.STAGING.ACS_JSON_RAW (
    RAW_PAYLOAD VARIANT
);

-- 5. Create the External Stage mapping to your S3 bucket
CREATE OR REPLACE STAGE PHILOSOPHY_ROI.STAGING.ACS_EXTERNAL_STAGE
    URL = 's3://philosophy-5-year-public-microdata-sample-2023/'
    FILE_FORMAT = (TYPE = 'JSON');

CREATE OR REPLACE STAGE PHILOSOPHY_ROI.STAGING.ACS_EXTERNAL_STAGE
    URL = 's3://philosophy-5-year-public-microdata-sample-2023/'
    CREDENTIALS = (
        AWS_KEY_ID = 'PASTE_YOUR_AWS_ACCESS_KEY_ID_HERE' 
        AWS_SECRET_KEY = 'PASTE_YOUR_AWS_SECRET_ACCESS_KEY_HERE'
    )
    FILE_FORMAT = (TYPE = 'JSON');

    USE DATABASE PHILOSOPHY_ROI;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ROI_INGEST_WH;

SELECT 
    occupation_title,
    primary_degree_title,
    secondary_degree_title,
    age_bracket,
    estimated_sample_population AS estimated_us_population,
    weighted_average_annual_wages AS real_average_wages
FROM PHILOSOPHY_ROI.STAGING.MART_PHILOSOPHY_EARNINGS_SUMMARY
WHERE weighted_average_annual_wages BETWEEN 45000 AND 100000
AND occupation_title != 'Unknown/Unmapped Occupation'
AND secondary_degree_title = 'No Secondary Degree'
AND age_bracket = '31-45 (Mid Career)'
ORDER BY weighted_average_annual_wages, age_bracket DESC;

USE DATABASE PHILOSOPHY_ROI;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ROI_INGEST_WH;

SELECT 
    occupation_title,
    primary_degree_title,
    secondary_degree_title,
    age_bracket,
    estimated_sample_population AS estimated_us_population,
    weighted_average_annual_wages AS real_average_wages
FROM PHILOSOPHY_ROI.STAGING.MART_PHILOSOPHY_EARNINGS_SUMMARY
WHERE weighted_average_annual_wages BETWEEN 45000 AND 99999
AND occupation_title != 'Unknown/Unmapped Occupation'
AND secondary_degree_title = 'No Secondary Degree'
AND age_bracket = '31-45 (Mid Career)'
AND estimated_sample_population >= 100
ORDER BY weighted_average_annual_wages, age_bracket DESC;