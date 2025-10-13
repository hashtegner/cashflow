import yfinance as yf
import json
from datetime import datetime

def download_market_info(ticker: str, period: str, retrieved_at: datetime):
    info = yf.Ticker(ticker).history(period=period)
    results = []

    for date, row in info.iterrows():
        results.append({
                "date": date.strftime("%Y-%m-%d"),
                "ticker": ticker,
                "open": float(row['Open']),
                "close": float(row['Close']),
                "high": float(row['High']),
                "low": float(row['Low']),
                "volume": int(row['Volume']),
                "retrieved_at": retrieved_at.isoformat()
            })

    return results

def handler(event, _context):
    """
    Retrieve market info for provided company symbols and period
    """
    items = event.get("Items", [])
    tickers = [item.get("Ticker") for item in items]
    period = event.get("period", "1d")
    retrieved_at = datetime.now()

    if not tickers:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No tickers provided"})
        }

    results = []

    for ticker in tickers:
        results.extend(download_market_info(ticker=ticker, period=period, retrieved_at=retrieved_at))

    return results


if __name__ == "__main__":
    event = {
        "Items": [
            {"Ticker": "AMBP3.SA"},
            {"Ticker": "ABEV3.SA"},
            {"Ticker": "PETR4.SA"},
        ]
    }

    print(handler(event, {}))
