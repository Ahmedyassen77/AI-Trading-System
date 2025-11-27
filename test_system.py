"""
System Test Script - للتحقق من أن كل شيء يعمل
يختبر كل المكونات الأساسية للنظام
"""

import sys
from pathlib import Path

def print_header(text):
    """طباعة ترويسة مميزة"""
    print("\n" + "="*60)
    print(f"  {text}")
    print("="*60)

def test_imports():
    """اختبار المكتبات المطلوبة"""
    print_header("Testing Python Imports")
    
    required = {
        'yaml': 'pyyaml',
        'pandas': 'pandas',
        'numpy': 'numpy',
        'MetaTrader5': 'MetaTrader5'
    }
    
    all_ok = True
    for module, package in required.items():
        try:
            __import__(module)
            print(f"✅ {package:20s} - OK")
        except ImportError:
            print(f"❌ {package:20s} - MISSING")
            all_ok = False
    
    return all_ok

def test_directory_structure():
    """اختبار بنية المجلدات"""
    print_header("Testing Directory Structure")
    
    base = Path(__file__).parent
    required_dirs = [
        'strategy',
        'bridge',
        'signals',
        'results',
        'automation',
        'Logs'
    ]
    
    all_ok = True
    for dir_name in required_dirs:
        dir_path = base / dir_name
        if dir_path.exists() and dir_path.is_dir():
            print(f"✅ {dir_name:20s} - EXISTS")
        else:
            print(f"❌ {dir_name:20s} - MISSING")
            all_ok = False
    
    return all_ok

def test_required_files():
    """اختبار الملفات المطلوبة"""
    print_header("Testing Required Files")
    
    base = Path(__file__).parent
    required_files = [
        'strategy/strategy.py',
        'strategy/config.yaml',
        'bridge/generate_signals.py',
        'automation/run_tester.bat',
        'automation/RUN_BACKTEST.bat',
        'automation/tester.ini',
        'automation/pull.bat',
        'README.md',
        'requirements.txt'
    ]
    
    all_ok = True
    for file_path in required_files:
        full_path = base / file_path
        if full_path.exists() and full_path.is_file():
            print(f"✅ {file_path:40s} - EXISTS")
        else:
            print(f"❌ {file_path:40s} - MISSING")
            all_ok = False
    
    return all_ok

def test_strategy_import():
    """اختبار استيراد الاستراتيجية"""
    print_header("Testing Strategy Import")
    
    try:
        sys.path.insert(0, str(Path(__file__).parent / 'strategy'))
        from strategy import SMCStrategy
        
        # Test instantiation
        config = {
            'symbol': 'EURUSD',
            'htf_timeframe': 'H4',
            'mtf_timeframe': 'M15',
            'ltf_timeframe': 'M5',
            'swing_lookback': 3,
            'risk_pct': 1.0,
            'min_rr': 2.0
        }
        strategy = SMCStrategy(config)
        
        print(f"✅ SMC Strategy imported successfully")
        print(f"   - Symbol: {strategy.symbol}")
        print(f"   - HTF: {strategy.htf}")
        print(f"   - MTF: {strategy.mtf}")
        print(f"   - LTF: {strategy.ltf}")
        print(f"   - Min R:R: {strategy.min_rr}")
        
        return True
        
    except Exception as e:
        print(f"❌ SMC Strategy import failed: {e}")
        return False

def test_config_loading():
    """اختبار تحميل ملف الإعدادات"""
    print_header("Testing Config Loading")
    
    try:
        import yaml
        
        config_path = Path(__file__).parent / 'strategy' / 'config.yaml'
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        
        print(f"✅ Config loaded successfully")
        print(f"   - Symbol: {config.get('symbol')}")
        print(f"   - HTF: {config.get('htf_timeframe')}")
        print(f"   - MTF: {config.get('mtf_timeframe')}")
        print(f"   - LTF: {config.get('ltf_timeframe')}")
        print(f"   - Min R:R: {config.get('min_rr')}")
        print(f"   - Backtest Bars: {config.get('backtest_bars')}")
        
        return True
        
    except Exception as e:
        print(f"❌ Config loading failed: {e}")
        return False

def test_signal_generation():
    """اختبار توليد الإشارات"""
    print_header("Testing Signal Generation")
    
    try:
        import pandas as pd
        import numpy as np
        from datetime import datetime, timezone
        
        sys.path.insert(0, str(Path(__file__).parent / 'strategy'))
        from strategy import SMCStrategy
        
        # Create dummy data
        bars = 200
        dates = pd.date_range(end=datetime.now(timezone.utc), periods=bars, freq='5min')
        
        # More realistic data with trend
        base_price = 1.0850
        trend = np.linspace(0, 0.0020, bars)
        noise = np.random.normal(0, 0.0005, bars)
        close_prices = base_price + trend + noise
        
        df = pd.DataFrame({
            'time': dates,
            'open': close_prices + np.random.uniform(-0.0001, 0.0001, bars),
            'high': close_prices + np.random.uniform(0.0001, 0.0003, bars),
            'low': close_prices - np.random.uniform(0.0001, 0.0003, bars),
            'close': close_prices,
            'tick_volume': np.random.randint(100, 1000, bars)
        })
        
        # Ensure high/low are correct
        df['high'] = df[['open', 'close', 'high']].max(axis=1)
        df['low'] = df[['open', 'close', 'low']].min(axis=1)
        
        # Generate signals
        config = {
            'symbol': 'EURUSD',
            'htf_timeframe': 'H4',
            'mtf_timeframe': 'M15',
            'ltf_timeframe': 'M5',
            'swing_lookback': 3,
            'risk_pct': 1.0,
            'min_rr': 2.0
        }
        strategy = SMCStrategy(config)
        result = strategy.generate_signals(df)
        signals = result['signals']
        
        print(f"✅ Signal generation successful")
        print(f"   - Input bars: {len(df)}")
        print(f"   - Generated signals: {len(signals)}")
        
        if signals:
            buy_count = sum(1 for s in signals if s['action'] == 'BUY')
            sell_count = sum(1 for s in signals if s['action'] == 'SELL')
            print(f"   - BUY signals: {buy_count}")
            print(f"   - SELL signals: {sell_count}")
            
            # Show first signal
            first = signals[0]
            print(f"   - First signal: {first['action']} at {first['price']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Signal generation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """الدالة الرئيسية"""
    print("\n" + "="*60)
    print("  AI TRADING SYSTEM - SYSTEM TEST")
    print("="*60)
    
    tests = [
        ("Python Imports", test_imports),
        ("Directory Structure", test_directory_structure),
        ("Required Files", test_required_files),
        ("Strategy Import", test_strategy_import),
        ("Config Loading", test_config_loading),
        ("Signal Generation", test_signal_generation)
    ]
    
    results = {}
    for name, test_func in tests:
        try:
            results[name] = test_func()
        except Exception as e:
            print(f"\n❌ Test '{name}' crashed: {e}")
            results[name] = False
    
    # Summary
    print_header("TEST SUMMARY")
    
    passed = sum(1 for r in results.values() if r)
    total = len(results)
    
    for name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status:10s} - {name}")
    
    print("\n" + "-"*60)
    print(f"Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! System is ready.")
        return 0
    else:
        print("⚠️  Some tests failed. Please check above for details.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
