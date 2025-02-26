import requests
import ccxt
import pandas as pd
import config1  # Import your config module
import ta  # Import ta library

# Fetch SELECTED_SYMBOLS dynamically from Binance Futures
url = "https://fapi.binance.com/fapi/v1/exchangeInfo"
try:
    response = requests.get(url)
    response.raise_for_status()  # Check if the request was successful
    data = response.json()

    SELECTED_SYMBOLS = [
        s['symbol'] for s in data['symbols']
        if s['quoteAsset'] == 'USDT' and s['status'] == 'TRADING'
    ]
except requests.exceptions.RequestException as e:
    print(f"Error fetching data from Binance Futures: {e}")
    SELECTED_SYMBOLS = []

# Initialize Binance client
binance = ccxt.binance({
    'apiKey': config1.API_KEY,
    'secret': config1.API_SECRET,
})

# Function to get historical candlestick data
def get_historical_data(symbol, interval='1d', limit=21):  # 21 to ensure we have enough data for EMA 20
    ohlcv = binance.fetch_ohlcv(symbol, interval, limit=limit)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    df.set_index('timestamp', inplace=True)
    df.columns = ['Open', 'High', 'Low', 'Close', 'Volume']
    return df

# Function to calculate EMA
def calculate_ema(df, period):
    return ta.trend.EMAIndicator(df['Close'], window=period).ema_indicator()

# Function to process a symbol and return its position and percentage
def process_symbol(symbol):
    try:
        # Fetch historical data
        df = get_historical_data(symbol)
        
        # Calculate EMAs
        df['EMA_3'] = calculate_ema(df, 3)
        df['EMA_20'] = calculate_ema(df, 20)
        
        # Get today's candle (last row)
        today_open = df['Open'].iloc[-1]
        today_close = df['Close'].iloc[-1]
        ema_3 = df['EMA_3'].iloc[-1]
        ema_20 = df['EMA_20'].iloc[-1]
        
        # Calculate actual percentage change for today
        percent_change = ((today_close - today_open) / today_open) * 100
        
        # Determine position based on EMA
        if ema_3 > ema_20:
            position = "Long"
        elif ema_3 < ema_20:
            position = "Short"
        else:
            position = "Neutral"
        
        return symbol, percent_change, position
    
    except Exception as e:
        print(f"Error processing {symbol}: {e}")
        return symbol, None, None

# Main function
def main():
    long_positions = []
    short_positions = []
    
    print("Processing symbols...")
    for symbol in SELECTED_SYMBOLS:
        sym, percent, position = process_symbol(symbol)
        if percent is not None and position is not None:
            if position == "Long":
                long_positions.append((sym, percent))
            elif position == "Short":
                short_positions.append((sym, percent))
    
    # Calculate cumulative percentages
    long_cumulative = sum(percent for _, percent in long_positions)
    short_cumulative = sum(percent for _, percent in short_positions)
    
    # Sort results by percentage change
    long_positions.sort(key=lambda x: x[1], reverse=True)
    short_positions.sort(key=lambda x: x[1], reverse=True)
    
    # Print Long Positions
    print("\nLong Positions:")
    print("Symbol | Percentage Change (%)")
    print("-" * 40)
    for symbol, percent in long_positions:
        print(f"{symbol:<12} | {percent:>8.2f}%")
    print(f"\nCumulative Long Positions Percentage: {long_cumulative:.2f}%")
    
    # Print Short Positions
    print("\nShort Positions:")
    print("Symbol | Percentage Change (%)")
    print("-" * 40)
    for symbol, percent in short_positions:
        print(f"{symbol:<12} | {percent:>8.2f}%")
    print(f"\nCumulative Short Positions Percentage: {short_cumulative:.2f}%")

if __name__ == "__main__":
    main()
