import pandas as pd
from datetime import datetime
from io import StringIO
import boto3

s3_client = boto3.client("s3")


def save_to_s3(df: pd.DataFrame, bucket_name: str):
    now = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
    key = f"raw/crawled_data/{now}.csv"

    buffer = StringIO()
    df.to_csv(buffer)
    s3_client.put_object(Bucket=bucket_name, Key=key, Body=buffer.getvalue())

    return { "file": f"s3://{bucket_name}/{key}" }

def handler(event, _context):
    """
    Write crawled market info to S3
    """

    s3_bucket_name = event.get("bucket_name", "cashflow-data")
    results = event.get("results", [])
    flat_results = []
    for sublist in results:
        flat_results.extend(sublist)

    df = pd.DataFrame(flat_results)

    return save_to_s3(df, s3_bucket_name)


if __name__ == "__main__":
    event = {
        "results": [
            { "ticker": "AAPL", "date": "2021-01-01", "price": 100 },
            { "ticker": "AAPL", "date": "2021-01-02", "price": 101 },
        ],
        "s3_bucket_name": "cashflow-data"
    }
    print(handler(event, {}))
