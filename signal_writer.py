from pathlib import Path
from datetime import datetime, timezone

def write_signals(lines, signals_dir: str, backtest: bool = True):
    Path(signals_dir).mkdir(parents=True, exist_ok=True)
    if backtest:
        fname = f"backtest_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.txt"
    else:
        fname = "live_signal.txt"
    p = Path(signals_dir) / fname
    p.write_text("\n".join(lines), encoding="utf-8")
    return str(p)
