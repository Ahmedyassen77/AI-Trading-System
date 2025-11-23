"""
SMC Signal Generator
يولد إشارات SMC مع معلومات الرسم الكاملة
"""

import sys
import yaml
import json
from pathlib import Path
from datetime import datetime, timezone

sys.path.insert(0, str(Path(__file__).parent.parent / 'strategy'))

from smc_strategy import SMCStrategy


def load_config(config_path: str) -> dict:
    """تحميل ملف الإعدادات"""
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def get_market_data(symbol: str, timeframe: str, bars: int):
    """جلب بيانات السوق من MT5 أو dummy data"""
    try:
        import MetaTrader5 as mt5
        import pandas as pd
        
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
        print("⚠️  MT5 غير متوفر، استخدام بيانات وهمية")
        return generate_dummy_data(bars)


def generate_dummy_data(bars: int):
    """توليد بيانات وهمية واقعية"""
    import pandas as pd
    import numpy as np
    
    dates = pd.date_range(end=datetime.now(timezone.utc), periods=bars, freq='5min')
    
    # بيانات أكثر واقعية مع trend
    base_price = 1.0850
    trend = np.linspace(0, 0.0050, bars)  # trend صاعد بسيط
    noise = np.random.normal(0, 0.0010, bars)
    
    close_prices = base_price + trend + noise
    
    data = {
        'time': dates,
        'open': close_prices + np.random.uniform(-0.0002, 0.0002, bars),
        'high': close_prices + np.random.uniform(0.0001, 0.0005, bars),
        'low': close_prices - np.random.uniform(0.0001, 0.0005, bars),
        'close': close_prices,
        'tick_volume': np.random.randint(100, 1000, bars)
    }
    
    df = pd.DataFrame(data)
    
    # تأكد أن High/Low صحيحين
    df['high'] = df[['open', 'close', 'high']].max(axis=1)
    df['low'] = df[['open', 'close', 'low']].min(axis=1)
    
    return df


def write_bridge_file(signals: list, output_path: str):
    """كتابة ملف bridge.txt للإشارات فقط"""
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
    
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    return output_path


def write_drawings_file(drawings: list, output_path: str):
    """
    كتابة ملف الرسومات بتنسيق JSON
    سيقرأه EA لرسم كل المفاهيم على الشارت
    """
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(drawings, f, indent=2, default=str)
    
    return output_path


def write_analysis_file(result: dict, output_path: str):
    """كتابة ملف تحليل شامل"""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    analysis = {
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'htf_bias': result['htf_bias'],
        'statistics': result['stats'],
        'signals_count': len(result['signals']),
        'drawings_count': len(result['drawings']),
        'signals': result['signals']
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(analysis, f, indent=2, default=str)
    
    return output_path


def print_summary(result: dict):
    """طباعة ملخص النتائج"""
    print("\n" + "="*60)
    print("  SMC STRATEGY ANALYSIS SUMMARY")
    print("="*60)
    
    print(f"\n📊 HTF Bias: {result['htf_bias'].upper()}")
    
    print("\n📈 Statistics:")
    stats = result['stats']
    for key, value in stats.items():
        print(f"   - {key.replace('_', ' ').title()}: {value}")
    
    print(f"\n💹 Trade Signals: {len(result['signals'])}")
    if result['signals']:
        buy_count = sum(1 for s in result['signals'] if s['action'] == 'BUY')
        sell_count = sum(1 for s in result['signals'] if s['action'] == 'SELL')
        print(f"   - BUY: {buy_count}")
        print(f"   - SELL: {sell_count}")
        
        print("\n🎯 Sample Signals:")
        for sig in result['signals'][:3]:
            print(f"   - {sig['action']} @ {sig['price']:.5f}")
            print(f"     SL: {sig['sl']:.5f} | TP: {sig['tp']:.5f}")
            print(f"     Context: {sig['comment']}")
    
    print(f"\n🎨 Drawing Objects: {len(result['drawings'])}")
    drawing_types = {}
    for d in result['drawings']:
        obj_type = d.get('object', 'unknown')
        drawing_types[obj_type] = drawing_types.get(obj_type, 0) + 1
    
    for obj_type, count in drawing_types.items():
        print(f"   - {obj_type}: {count}")
    
    print("\n" + "="*60)


def main():
    """الدالة الرئيسية"""
    
    base_dir = Path(__file__).parent.parent
    config_path = base_dir / 'strategy' / 'config_smc.yaml'
    
    print("="*60)
    print("  SMC SIGNAL GENERATOR")
    print("="*60)
    
    # تحميل الإعدادات
    print(f"\n📁 Loading config: {config_path}")
    config = load_config(str(config_path))
    
    # جلب البيانات
    symbol = config['symbol']
    timeframe = config['ltf_timeframe']
    bars = config['backtest_bars']
    
    print(f"📊 Fetching {symbol} {timeframe} - {bars} bars")
    df = get_market_data(symbol, timeframe, bars)
    print(f"✅ Got {len(df)} candles")
    
    # تطبيق الاستراتيجية
    print(f"\n🧠 Applying SMC Strategy...")
    strategy = SMCStrategy(config)
    result = strategy.generate_signals(df)
    
    # طباعة الملخص
    print_summary(result)
    
    # كتابة الملفات
    print(f"\n💾 Writing output files...")
    
    # 1. ملف bridge.txt للإشارات
    bridge_path = base_dir / 'signals' / 'bridge.txt'
    write_bridge_file(result['signals'], str(bridge_path))
    print(f"✅ Signals: {bridge_path}")
    
    # 2. ملف drawings.json للرسومات
    drawings_path = base_dir / 'signals' / 'drawings.json'
    write_drawings_file(result['drawings'], str(drawings_path))
    print(f"✅ Drawings: {drawings_path}")
    
    # 3. ملف analysis.json للتحليل الشامل
    analysis_path = base_dir / 'signals' / 'smc_analysis.json'
    write_analysis_file(result, str(analysis_path))
    print(f"✅ Analysis: {analysis_path}")
    
    print("\n" + "="*60)
    print("✅ DONE! Files ready for EA")
    print("="*60)
    
    print("\n📋 Next Steps:")
    print("1. Copy signals/bridge.txt to MT5 Common Files")
    print("2. Copy signals/drawings.json to MT5 Common Files")
    print("3. Run EA_SignalBridge in MT5")
    print("4. EA will read and draw all SMC concepts on chart")


if __name__ == '__main__':
    main()
