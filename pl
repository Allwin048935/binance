import ccxt
import pandas as pd
import config1  # Import your config module
import ta  # Import ta library

# Initialize Binance client
binance = ccxt.binance({
    'apiKey': config1.API_KEY,
    'secret': config1.API_SECRET,
})

# Fetch SELECTED_SYMBOLS dynamically from Binance Futures
def get_trading_symbols():
    exchange_info = binance.fetch_markets()
    return [s['symbol'] for s in exchange_info 
            if s['quote'] == 'USDT' and s['type'] == 'future' and s['active']]

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

# Function to calculate today's percentage change and determine position
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
        
        # Calculate percentage change for today
        percent_change = ((today_close - today_open) / today_open) * 100
        
        # Determine position and adjust percentage output
        if ema_3 > ema_20:  # Long position
            return symbol, percent_change  # Positive for long
        elif ema_3 < ema_20:  # Short position
            return symbol, -abs(percent_change)  # Negative for short
        else:
            return symbol, 0.0  # Neutral if equal
        
    except Exception as e:
        print(f"Error processing {symbol}: {e}")
        return symbol, None

# Main function
def main():
    SELECTED_SYMBOLS = get_trading_symbols()
    results = []
    
    print("Processing symbols...")
    for symbol in SELECTED_SYMBOLS:
        sym, percent = process_symbol(symbol)
        if percent is not None:
            results.append((sym, percent))
    
    # Sort results by percentage change
    results.sort(key=lambda x: x[1], reverse=True)
    
    # Print results
    print("\nSymbol | Percentage Change (%) | Position")
    print("-" * 50)
    for symbol, percent in results:
        position = "Long" if percent > 0 else "Short" if percent < 0 else "Neutral"
        print(f"{symbol:<12} | {percent:>8.2f}% | {position}")

if __name__ == "__main__":
    main()
