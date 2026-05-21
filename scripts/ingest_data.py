# Fetch the public use microdata sample from the Census ACS PUMS API for philosophy graduate records and upload to S3.

import logging
import os
import boto3
import requests
import json
from botocore.exceptions import ClientError
from dotenv import load_dotenv
from requests.adapters import HTTPAdapter

load_dotenv()

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

CENSUS_API_KEY = os.getenv('CENSUS_API_KEY')
YEAR = '2023'
DATASET = 'acs5'
FOD_CODE = '4801' # Code for Philosophy and Religious Studies

VARIABLES = [
    'SERIALNO', # Housing Unit Serial Number
    'SPORDER', # Person Number
    'PWGTP', # Person Weight
    'FOD1P', # Field of Degree - Primary
    'FOD2P', # Field of Degree - Secondary
    'SCHL', # Educational Attainment
    'OCCP', # Wages or Salary Income
    'WAGP', # Occupation Code
    'ESR', # Employment Status Code
    'AGEP' # Age
]

def check_s3_bucket_exists(bucket_name):
    """
    Check to see if the S3 bucket exists and is accessible.
    """
    s3 = boto3.client('s3')

    try:
        s3.head_bucket(Bucket=bucket_name)
        logging.info(f"Bucket '{bucket_name}' exists and is accessible.")
        return True
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            logging.info(f"Error: Bucket '{bucket_name}' does not exist.")
        else:
            logging.info(f"Error: {e}")
        return False

def grab_pums_api():
    """
    Grab records of philosophy majors from the Census ACS PUMS API. 
    Both FOD1P and FOD2P are included and records are deduplicated using composite keys.
    """
    url = f"https://api.census.gov/data/{YEAR}/acs/{DATASET}/pums"

    session = requests.Session()
    session.mount('https://', HTTPAdapter(max_retries=3))

    # Force unique records
    unique_records = {}

    # Define the two discrete searches
    search_tracks = [
        {'field': 'FOD1P', 'label': 'Primary Major'},
        {'field': 'FOD2P', 'label': 'Secondary Major'}
    ]

    for track in search_tracks:
        params = {
            'get': ','.join(VARIABLES),
            track['field']: FOD_CODE,
            'for': 'state:*'
        }
        if CENSUS_API_KEY:
            params['key'] = CENSUS_API_KEY

        logging.info(f"Fetching PUMS {YEAR} {DATASET} for FOD1P={FOD_CODE}.")
        response = session.get(url, params=params, timeout=120)
        response.raise_for_status()

        raw = response.json()

        # Top row contains headers
        headers = raw[0]
        rows = raw[1:]

        for row in rows:
            record = dict(zip(headers, row))
            composite_key = f"{record['SERIALNO']}_{record['SPORDER']}"
            unique_records[composite_key] = record

    final_records = list(unique_records.values())
    logging.info(f"Fetched {len(final_records):,} unqiue records.")
    return final_records

def upload_pums_to_s3(bucket_name, records):
    """
    Upload PUMS records to S3.
    """
    s3 = boto3.client('s3')
    s3_key = f"philosophy-5-year-public-microdata-sample-{YEAR}.json"

    body = '\n'.join(json.dumps(record) for record in records)

    try:
        s3.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=body,
            ContentType='application/x-ndjson'
        )
        logging.info(f"Uploaded {len(records):,} records to s3://{bucket_name}/{s3_key}.")
        return True
    except Exception as e:
        logging.error(f"Failed to upload to s3: {e}")
        return False
    
if __name__ == "__main__":
    bucket_name = 'philosophy-5-year-public-microdata-sample-2023'

    # If check_s3_bucket_exists returns True, run the script
    if check_s3_bucket_exists(bucket_name):
        logging.info("Pipeline starting...")
        records = grab_pums_api()
        if records:
            upload_pums_to_s3(bucket_name, records)
        logging.info("Pipeline finished.")