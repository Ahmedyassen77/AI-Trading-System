"""
سكربت توليد الإشارات - الجسر بين Python و MT5
يقرأ البيانات، يطبق الاستراتيجية، يكتب bridge.txt
"""

import sys
import yaml
from pathlib import Path
from datetime import datetime, timezone

# إضافة مجلد strategy للـ path
sys.path.insert(0, str(Path(__file__).parent.parent / 'strategy'))

from simple_strategy import SimpleStrategy


def load_config(config_path: str) -> dict:
    """تحميل ملف الإعدادات"""
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def get_market_data(symbol: str, timeframe: str, bars: int):
    """
    يجلب بيانات السوق من MT5
    ملاحظة: يحتاج MT5 يكون مفتوح ومتصل
    """
    try:
        import MetaTrader5 as mt5
        import pandas as pd
        
        # Timeframe mapping
        TF_MAP = {
            'M1': mt5.TIMEFRAME_M1,
            'M5': mt5.TIMEFRAME_M5,
            'M15': mt5.TIMEFRAME_M15,
            'M30': mt5.TIMEFRAME_M30,
            'H1': mt5.TIMEFRAME_H1,
            'H4': mt5.TIMEFRAME_H4,
            'D1': mt5.TIMEFRAME_D1
        }
        
        if not mt5.initialize():
            raise RuntimeError("فشل تشغيل MT5")
        
        tf = TF_MAP.get(timeframe)
        if tf is None:
            raise ValueError(f"إطار زمني غير صحيح: {timeframe}")
        
        rates = mt5.copy_rates_from_pos(symbol, tf, 0, bars)
        if rates is None or len(rates) == 0:
            raise RuntimeError(f"فشل جلب البيانات لـ {symbol}")
        
        df = pd.DataFrame(rates)
        df['time'] = pd.to_datetime(df['time'], unit='s', utc=True)
        
        mt5.shutdown()
        return df
        
    except ImportError:
        print("⚠️  MT5 غير متوفر، استخدام بيانات وهمية للاختبار")
        return generate_dummy_data(bars)


def generate_dummy_data(bars: int):
    """توليد بيانات وهمية للاختبار بدون MT5"""
    import pandas as pd
    import numpy as np
    
    dates = pd.date_range(end=datetime.now(timezone.utc), periods=bars, freq='15min')
    
    data = {
        'time': dates,
        'open': np.random.uniform(1.0800, 1.0900, bars),
        'high': np.random.uniform(1.0850, 1.0950, bars),
        'low': np.random.uniform(1.0750, 1.0850, bars),
        'close': np.random.uniform(1.0800, 1.0900, bars),
        'tick_volume': np.random.randint(100, 1000, bars)
    }
    
    return pd.DataFrame(data)


def write_bridge_file(signals: list, output_path: str):
    """
    كتابة ملف bridge.txt بالتنسيق القياسي
    
    Format:
    timestamp;symbol;action;price;sl;tp;risk;comment
    """
    lines = ['timestamp;symbol;action;price;sl;tp;risk;comment']
    
    for sig in signals:
        line = (
            f"{sig['timestamp']};"
            f"{sig['symbol']};"
            f"{sig['action']};"
            f"{sig['price']:.5f};"
            f"{sig['sl']:.5f};"
            f"{sig['tp']:.5f};"
            f"{sig['risk']};"
            f"{sig['comment']}"
        )
        lines.append(line)
    
    # كتابة الملف
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    return output_path


def main():
    """الدالة الرئيسية"""
    
    # تحديد المسارات
    base_dir = Path(__file__).parent.parent
    config_path = base_dir / 'strategy' / 'config_simple.yaml'
    
    # تحميل الإعدادات
    print(f"📁 تحميل الإعدادات من: {config_path}")
    config = load_config(str(config_path))
    
    # جلب البيانات
    print(f"📊 جلب بيانات {config['symbol']} - {config['timeframe']} - {config['backtest_bars']} شموع")
    df = get_market_data(
        symbol=config['symbol'],
        timeframe=config['timeframe'],
        bars=config['backtest_bars']
    )
    
    print(f"✅ تم جلب {len(df)} شمعة")
    
    # تطبيق الاستراتيجية
    print("🧠 تطبيق الاستراتيجية...")
    strategy = SimpleStrategy(config)
    signals = strategy.generate_signals(df)
    
    print(f"✅ تم توليد {len(signals)} إشارة")
    
    # كتابة ملف bridge.txt
    output_path = base_dir / 'signals' / 'bridge.txt'
    print(f"💾 كتابة الإشارات إلى: {output_path}")
    write_bridge_file(signals, str(output_path))
    
    print(f"✅ تم! الملف جاهز للـ EA")
    print(f"📍 المسار: {output_path}")
    print(f"📈 عدد الإشارات: {len(signals)}")
    
    # معلومات إضافية
    if signals:
        buy_count = sum(1 for s in signals if s['action'] == 'BUY')
        sell_count = sum(1 for s in signals if s['action'] == 'SELL')
        print(f"   - BUY: {buy_count}")
        print(f"   - SELL: {sell_count}")


if __name__ == '__main__':
    main()
