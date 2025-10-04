import yfinance as yf
import json


def handler(event, context):
    data = yf.Ticker(event["Código"]).info


    return {
        "statusCode": 200,
        "body": json.dumps(data),
    }

if __name__ == "__main__":
    event = {
        "Código": "MGLU3.SA"
    }
    handler(event, None)    