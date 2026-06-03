# American Community Survey (ACS) Philosophy Degree ROI Pipeline

-- 1. Create the database and staging area
CREATE OR REPLACE DATABASE philosophy_roi;
CREATE OR REPLACE SCHEMA philosophy_roi.staging;

-- 2. Create the virtual compute engine (wakes up for queries, sleeps automatically)
CREATE OR REPLACE WAREHOUSE roi_ingest_wh WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 3. Create the landing table for the raw JSON variant payload
CREATE OR REPLACE TABLE philosophy_roi.staging.acs_json_raw (
    raw_payload VARIANT
);

-- 4. Secure the bridge to your existing S3 bucket
-- Note: Replace with your actual AWS keys if not using an IAM storage integration
CREATE OR REPLACE STAGE philosophy_roi.staging.acs_external_stage
    URL = 's3://philosophy-5-year-public-microdata-sample-2023/'
    CREDENTIALS = (
        AWS_KEY_ID = 'your_aws_access_key_here' 
        AWS_SECRET_KEY = 'your_aws_secret_access_key_here'
    );