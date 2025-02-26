import requests
import ccxt
import pandas as pd
import config1  # Import your config module
import ta  # Import ta library
import telegram  # Import python-telegram-bot library
import os

# Add these to your config1.py file:
# TELEGRAM_BOT_TOKEN = '7619077339:AAGvLzsABJRFKsv50TgI1XxMNhVvtED-E_4'
# TELEGRAM_CHAT_ID = '1385370555'

# Fetch SELECTED_SYMBOLS dynamically from Binance Futures
url = "https://fapi.binance.com/fapi/v1/exchangeInfo"
try:
    response = requests.get(url)
    response.raise_for_status()
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

# Initialize Telegram bot
bot = telegram.Bot(token=config1.TELEGRAM_BOT_TOKEN)

# Function to get historical candlestick data
def get_historical_data(symbol, interval='1d', limit=21):
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
        df = get_historical_data(symbol)
        df['EMA_3'] = calculate_ema(df, 3)
        df['EMA_20'] = calculate_ema(df, 20)
        
        today_open = df['Open'].iloc[-1]
        today_close = df['Close'].iloc[-1]
        ema_3 = df['EMA_3'].iloc[-1]
        ema_20 = df['EMA_20'].iloc[-1]
        
        percent_change = ((today_close - today_open) / today_open) * 100
        
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

# Function to save to Excel and send to Telegram
async def save_and_send_results(long_positions, short_positions, long_cumulative, short_cumulative):
    # Create DataFrames
    long_df = pd.DataFrame(long_positions, columns=['Symbol', 'Percentage Change (%)'])
    short_df = pd.DataFrame(short_positions, columns=['Symbol', 'Percentage Change (%)'])
    
    # Create Excel file
    filename = 'trading_positions.xlsx'
    with pd.ExcelWriter(filename) as writer:
        long_df.to_excel(writer, sheet_name='Long Positions', index=False)
        short_df.to_excel(writer, sheet_name='Short Positions', index=False)
        # Add cumulative percentages
        summary_df = pd.DataFrame({
            'Metric': ['Cumulative Long %', 'Cumulative Short %'],
            'Value': [f"{long_cumulative:.2f}%", f"{short_cumulative:.2f}%"]
        })
        summary_df.to_excel(writer, sheet_name='Summary', index=False)
    
    # Send file to Telegram
    with open(filename, 'rb') as file:
        await bot.send_document(
            chat_id=config1.TELEGRAM_CHAT_ID,
            document=file,
            caption=f"Trading Positions - {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
    
    # Clean up
    os.remove(filename)

# Main function
async def main():
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
    
    # Sort results
    long_positions.sort(key=lambda x: x[1], reverse=True)
    short_positions.sort(key=lambda x: x[1], reverse=True)
    
    # Print results
    print("\nLong Positions:")
    print("Symbol | Percentage Change (%)")
    print("-" * 40)
    for symbol, percent in long_positions:
        print(f"{symbol:<12} | {percent:>8.2f}%")
    print(f"\nCumulative Long Positions Percentage: {long_cumulative:.2f}%")
    
    print("\nShort Positions:")
    print("Symbol | Percentage Change (%)")
    print("-" * 40)
    for symbol, percent in short_positions:
        print(f"{symbol:<12} | {percent:>8.2f}%")
    print(f"\nCumulative Short Positions Percentage: {short_cumulative:.2f}%")
    
    # Save to Excel and send to Telegram
    await save_and_send_results(long_positions, short_positions, long_cumulative, short_cumulative)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
