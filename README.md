# AI Trading System

نظام تداول آلي متقدم للفوركس - Python Strategy + MT5 Execution

## 🎯 Architecture

```
┌─────────────────┐
│  Python         │  ← المنطق والاستراتيجية
│  Strategy       │
└────────┬────────┘
         │
         ↓ generates
┌─────────────────┐
│  bridge.txt     │  ← ملف الإشارات
│  (signals)      │
└────────┬────────┘
         │
         ↓ reads
┌─────────────────┐
│  EA_SignalBridge│  ← Expert Advisor
│  (MT5)          │
└────────┬────────┘
         │
         ↓ executes
┌─────────────────┐
│  Trading        │  ← التنفيذ الفعلي
│  (MT5 Market)   │
└─────────────────┘
```

## 📁 Project Structure

```
AI-Trading-System/
│
├── strategy/                    # استراتيجيات التداول
│   ├── simple_strategy.py       # استراتيجية بسيطة للاختبار
│   ├── dyson_strategy.py        # استراتيجية Dyson (قريباً)
│   ├── config_simple.yaml       # إعدادات الاستراتيجية البسيطة
│   └── config_dyson.yaml        # إعدادات Dyson (قريباً)
│
├── bridge/                      # الجسر بين Python و MT5
│   └── generate_signals.py      # توليد ملف الإشارات
│
├── signals/                     # الإشارات المولدة
│   └── bridge.txt               # الملف الذي يقرأه EA
│
├── automation/                  # سكربتات التشغيل الآلي
│   ├── run_backtest.bat         # تشغيل باكتيست كامل
│   ├── pull.bat                 # سحب تحديثات من GitHub
│   ├── tester.ini               # إعدادات MT5 Strategy Tester
│   └── backtest_requests.yaml   # طلبات الباكتيست
│
├── results/                     # نتائج الباكتيست
│   └── README.md                # شرح تنسيق النتائج
│
├── Logs/                        # السجلات
│
└── requirements.txt             # مكتبات Python المطلوبة
```

## 🚀 Quick Start

### 1. Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Install MetaTrader5 library
pip install MetaTrader5 pandas pyyaml
```

### 2. Generate Signals

```bash
# من مجلد المشروع
python bridge/generate_signals.py
```

هذا سينشئ ملف `signals/bridge.txt` بتنسيق:
```
timestamp;symbol;action;price;sl;tp;risk;comment
2024-11-21T10:00:00Z;EURUSD;BUY;1.0850;1.0835;1.0880;1.0;test_signal
```

### 3. Copy to MT5

انسخ `signals/bridge.txt` إلى:
```
%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt
```

### 4. Run Backtest

**Option A: Manual**
- افتح MT5
- Strategy Tester → Choose EA_SignalBridge
- Configure inputs:
  - `InpEnableTrading = true`
  - `InpSource = MODE_COMMON_FILES`
  - `InpFileOrMask = "bridge.txt"`
- Run test

**Option B: Automated**
```bash
# من مجلد المشروع على Windows
automation\run_backtest.bat
```

## 🔧 Configuration

### Strategy Config (`strategy/config_simple.yaml`)

```yaml
symbol: "EURUSD"
timeframe: "M15"
risk_pct: 1.0
sl_points: 150
tp_points: 300
backtest_bars: 2000
```

### Backtest Requests (`automation/backtest_requests.yaml`)

```yaml
backtests:
  - id: "test_001"
    name: "Simple Strategy - EURUSD M15"
    enabled: true
    symbol: "EURUSD"
    timeframe: "M15"
    from_date: "2024-01-01"
    to_date: "2024-12-31"
    # ... more settings
```

## 📊 Signal File Format

**Header:**
```
timestamp;symbol;action;price;sl;tp;risk;comment
```

**Example Signal:**
```
2024-11-21T10:00:00Z;EURUSD;BUY;1.0850;1.0835;1.0880;1.0;green_candle
```

**Fields:**
- `timestamp`: ISO format with Z (UTC)
- `symbol`: e.g., EURUSD, GBPUSD
- `action`: BUY or SELL
- `price`: Entry price
- `sl`: Stop Loss
- `tp`: Take Profit
- `risk`: Risk percentage (for lot calculation)
- `comment`: Free text description

## 🤖 Automation

### Auto-Pull from GitHub

Setup Task Scheduler:
```
Task: Run automation\pull.bat every 5 minutes
```

### Auto-Backtest

```bash
# Schedule this to run daily at 2 AM
automation\run_backtest.bat
```

## 🧪 Testing

### Test Strategy Only

```python
from strategy.simple_strategy import SimpleStrategy
import yaml

# Load config
with open('strategy/config_simple.yaml') as f:
    config = yaml.safe_load(f)

# Initialize strategy
strategy = SimpleStrategy(config)

# Generate signals (needs DataFrame with OHLC data)
# signals = strategy.generate_signals(df)
```

## 📈 Strategies

### Current Strategies

1. **Simple Strategy** (`simple_strategy.py`)
   - منطق بسيط للاختبار
   - شمعة خضراء = BUY
   - شمعة حمراء = SELL

2. **Dyson Strategy** (قريباً)
   - استراتيجية متقدمة
   - فلاتر متعددة
   - إدارة مخاطر ديناميكية

## 🔄 Workflow

1. **Develop Strategy** (Python)
   - كتابة المنطق في `strategy/`
   - تعديل الإعدادات في `config_*.yaml`

2. **Generate Signals**
   - تشغيل `bridge/generate_signals.py`
   - يولد `signals/bridge.txt`

3. **Backtest**
   - تشغيل `automation/run_backtest.bat`
   - أو يدوياً من MT5 Strategy Tester

4. **Analyze Results**
   - قراءة `results/*.html`
   - تحليل `results/*.json`

5. **Iterate**
   - تعديل الاستراتيجية
   - Commit to GitHub
   - Auto-pull يسحب التحديثات
   - إعادة الباكتيست

## 🔐 Git Workflow

```bash
# Make changes
git add .
git commit -m "feat: add new filter to strategy"
git push origin main

# On trading machine, pull.bat will auto-sync
```

## 📝 Notes

- **Python** = Strategy logic only
- **EA** = Execution bridge only
- **MT5** = Market execution
- All parameters in YAML configs
- All signals through `bridge.txt`
- No hardcoded values in code

## 🆘 Troubleshooting

### Signals not showing in EA
- Check `bridge.txt` exists in Common\Files
- Check EA input `InpFileOrMask = "bridge.txt"`
- Check EA input `InpSource = MODE_COMMON_FILES`

### MT5 initialization failed
- Ensure MT5 is running
- Check symbol exists and is available
- Check timeframe is valid

### No trades executed in backtest
- Check `InpEnableTrading = true`
- Check signal format matches exactly
- Check logs for errors

## 📞 Support

راجع السجلات في `Logs/` لأي مشاكل

---

**Version:** 1.0  
**Last Updated:** 2025-11-21  
**Status:** ✅ Ready for Testing
