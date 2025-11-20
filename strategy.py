import yaml
from data_source import init, get_rates
from signal_writer import write_signals

def load_cfg():
    with open("config.yaml", "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def simple_logic(df, sl_pts, tp_pts, symbol):
    lines = ["TIMESTAMP;SYMBOL;ACTION;PRICE;SL;TP;RISK;COMMENT"]
    for i in range(1, len(df)):
        row = df.iloc[i]
        ts = row["time"].strftime("%Y-%m-%dT%H:%M:%SZ")
        price = round(float(row["close"]), 5)
        if row["close"] > row["open"]:
            action, sl, tp, cmt = "BUY", price - sl_pts*1e-5, price + tp_pts*1e-5, "test_buy"
        else:
            action, sl, tp, cmt = "SELL", price + sl_pts*1e-5, price - tp_pts*1e-5, "test_sell"
        lines.append(f"{ts};{symbol};{action};{price:.5f};{sl:.5f};{tp:.5f};1.0;{cmt}")
    return lines

def main():
    cfg = load_cfg()
    symbol, tf, bars = cfg["symbol"], cfg["timeframe"], cfg["backtest_bars"]
    sl_pts, tp_pts = int(cfg["sl_points"]), int(cfg["tp_points"])
    init()
    df = get_rates(symbol, tf, bars)
    lines = simple_logic(df, sl_pts, tp_pts, symbol)
    out = write_signals(lines, cfg["signals_dir"], backtest=True)
    print("Wrote:", out)

if __name__ == "__main__":
    main()
