import yfinance as yf
import json
from datetime import datetime

def download_market_info(ticker_name: str, period: str, retrieved_at: datetime):
    ticker = yf.Ticker(ticker_name)

    info = ticker.info
    history = ticker.history(period=period)
    results = []

    for date, row in history.iterrows():
        results.append({
            "name": info.get("shortName"),
            "sector": info.get("sector"),
            "country": info.get("country"),
            "industry": info.get("industry"),
            "market": info.get("market"),
            "date": date.strftime("%Y-%m-%d"),
            "ticker": ticker_name,
            "open": float(row.get('Open', 0)),
            "close": float(row.get('Close', 0)),
            "high": float(row.get('High', 0)),
            "low": float(row.get('Low', 0)),
            "volume": int(row.get('Volume', 0)),
            "retrieved_at": retrieved_at.isoformat()
        })

    return results

def handler(event, _context):
    """
    Retrieve market info for provided company symbols and period
    """
    items = event.get("Items", [])
    tickers = [item.get("Ticker") for item in items]
    period = event.get("period", "30d")
    retrieved_at = datetime.now()

    if not tickers:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No tickers provided"})
        }

    results = []

    for ticker in tickers:
        results.extend(download_market_info(ticker_name=ticker, period=period, retrieved_at=retrieved_at))

    return results


if __name__ == "__main__":
    event = {
        "Items": [
            {"Ticker": "AAPL"},
            {"Ticker": "PETR4.SA"}
        ]
    }

    print(handler(event, {}))
