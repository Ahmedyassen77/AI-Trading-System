# AI Trading System - Setup Guide

دليل الإعداد الكامل للنظام على Windows

---

## 🎯 Overview

هذا النظام يعمل بالشكل التالي:
```
Python (Strategy) → bridge.txt → EA (MT5) → Trading
```

---

## 📋 المتطلبات الأساسية

### 1. Software المطلوب

- ✅ **Python 3.8+** ([تحميل](https://www.python.org/downloads/))
- ✅ **MetaTrader 5** ([تحميل](https://www.metatrader5.com/))
- ✅ **Git for Windows** ([تحميل](https://git-scm.com/download/win))
- ✅ **حساب GitHub** ([تسجيل](https://github.com/))

### 2. Python Libraries

```bash
pip install MetaTrader5 pandas pyyaml numpy
```

---

## 🚀 خطوات الإعداد

### خطوة 1: Clone المشروع

```bash
# في Command Prompt أو PowerShell
cd C:\
git clone https://github.com/Ahmedyassen77/AI-Trading-System.git
cd AI-Trading-System
```

**النتيجة:**
```
C:\AI-Trading-System\
├── strategy/
├── bridge/
├── automation/
├── signals/
├── results/
└── ...
```

---

### خطوة 2: تثبيت Dependencies

```bash
cd C:\AI-Trading-System
pip install -r requirements.txt
```

**تحقق من التثبيت:**
```bash
python -c "import MetaTrader5 as mt5; print('MT5 OK')"
```

---

### خطوة 3: إعداد MT5

#### 3.1 تثبيت EA_SignalBridge

1. **افتح MT5**
2. **File → Open Data Folder**
3. **انسخ EA_SignalBridge.ex5 إلى:**
   ```
   MQL5\Experts\EA_SignalBridge.ex5
   ```
4. **أعد تشغيل MT5**

#### 3.2 تفعيل Auto Trading

1. في MT5، اضغط **Tools → Options**
2. تبويب **Expert Advisors**
3. ✅ فعّل **Allow automated trading**
4. ✅ فعّل **Allow DLL imports**
5. **OK**

---

### خطوة 4: اختبار النظام

#### 4.1 توليد الإشارات

```bash
cd C:\AI-Trading-System
python bridge\generate_signals.py
```

**الناتج المتوقع:**
```
📁 تحميل الإعدادات من: strategy/config_simple.yaml
📊 جلب بيانات EURUSD - M15 - 2000 شموع
✅ تم جلب 2000 شمعة
🧠 تطبيق الاستراتيجية...
✅ تم توليد 1999 إشارة
💾 كتابة الإشارات إلى: signals/bridge.txt
✅ تم! الملف جاهز للـ EA
```

#### 4.2 التحقق من bridge.txt

```bash
# افتح الملف
notepad signals\bridge.txt
```

**يجب أن تشوف:**
```
timestamp;symbol;action;price;sl;tp;risk;comment
2025-11-21T10:00:00Z;EURUSD;BUY;1.08500;1.08350;1.08800;1.0;test
...
```

---

### خطوة 5: نسخ bridge.txt إلى MT5

#### الطريقة الأوتوماتيكية (Recommended)

```bash
copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"
```

#### الطريقة اليدوية

1. افتح **File Explorer**
2. اكتب في شريط العنوان:
   ```
   %APPDATA%\MetaQuotes\Terminal\Common\Files
   ```
3. انسخ `signals\bridge.txt` هنا

---

### خطوة 6: تشغيل Backtest في MT5

#### 6.1 افتح Strategy Tester

1. في MT5: **View → Strategy Tester** (Ctrl+R)
2. أو اضغط على أيقونة Strategy Tester

#### 6.2 إعدادات الـ Tester

**Settings Tab:**
- **Expert Advisor:** `EA_SignalBridge`
- **Symbol:** `EURUSD`
- **Period:** `M15`
- **Date Range:** من `2024.01.01` إلى `2024.12.31`
- **Model:** `Every tick` (الأدق)
- **Optimization:** `Disabled`

**Inputs Tab:**
```
InpEnableTrading     = true
InpSource            = 0  (MODE_COMMON_FILES)
InpFileOrMask        = "bridge.txt"
InpFixedLots         = 0.01
InpUseRiskFromFile   = false
InpSlippagePoints    = 3
InpMagic             = 12345
InpDrawSignals       = true
InpDrawLevels        = true
```

#### 6.3 تشغيل الاختبار

1. اضغط **Start**
2. انتظر حتى ينتهي الاختبار
3. راجع النتائج في تبويب **Results**

---

### خطوة 7: إعداد Auto-Pull (اختياري)

لسحب التحديثات تلقائياً من GitHub كل فترة.

#### 7.1 إنشاء Scheduled Task

1. افتح **Task Scheduler** (ابحث في Start Menu)
2. **Create Basic Task...**
3. **Name:** `AI-Trading-Auto-Pull`
4. **Trigger:** `Daily` at `00:00` (أو كل ساعة)
5. **Action:** `Start a program`
   - **Program:** `C:\AI-Trading-System\automation\pull.bat`
6. **Finish**

#### 7.2 اختبار الـ Task

```bash
# تشغيل يدوي
cd C:\AI-Trading-System
automation\pull.bat
```

---

## 🔄 Workflow اليومي

### للتطوير والاختبار

```bash
# 1. سحب آخر تحديثات
git pull origin main

# 2. تعديل الاستراتيجية (في strategy/)
# ... edit files ...

# 3. توليد الإشارات
python bridge\generate_signals.py

# 4. نسخ إلى MT5
copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"

# 5. تشغيل Backtest في MT5
# (يدوي أو باستخدام automation\run_backtest.bat)

# 6. تحليل النتائج
# results/backtest_report.html

# 7. Commit التغييرات
git add .
git commit -m "feat: description of changes"
git push origin main
```

### للتشغيل الآلي الكامل

```bash
# تشغيل سكربت واحد يعمل كل شيء
automation\run_backtest.bat
```

هذا السكربت:
1. ✅ يسحب من GitHub
2. ✅ يولد الإشارات
3. ✅ ينسخ إلى MT5
4. ✅ يشغّل MT5 (إذا المسار صحيح)

---

## 📊 تحليل النتائج

### بعد الباكتيست

1. **تقرير MT5** → `results/backtest_report.html`
2. **ملخص JSON** → `results/test_001_summary.json`

### قراءة JSON

```python
import json

with open('results/test_001_summary.json', 'r') as f:
    results = json.load(f)

print(f"Profit: ${results['results']['profit']}")
print(f"Win Rate: {results['results']['win_rate']}%")
print(f"Max Drawdown: {results['results']['max_drawdown_percent']}%")
```

---

## 🛠️ Troubleshooting

### مشكلة: `MT5 initialization failed`

**الحل:**
- ✅ تأكد أن MT5 مفتوح وشغال
- ✅ تأكد أنك مسجل دخول في حساب
- ✅ أعد تشغيل Python script

### مشكلة: EA لا يقرأ bridge.txt

**الحل:**
- ✅ تحقق الملف موجود في:
  ```
  %APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt
  ```
- ✅ تحقق `InpSource = 0` (MODE_COMMON_FILES)
- ✅ تحقق `InpFileOrMask = "bridge.txt"`

### مشكلة: لا توجد إشارات على الشارت

**الحل:**
- ✅ `InpDrawSignals = true`
- ✅ Symbol في bridge.txt = Symbol في الشارت
- ✅ تحقق تنسيق الملف صحيح

### مشكلة: لا يفتح صفقات

**الحل:**
- ✅ `InpEnableTrading = true`
- ✅ Auto Trading مفعّل في MT5 (أيقونة خضراء)
- ✅ Balance كافي للوت المحدد

### مشكلة: Git push يطلب password كل مرة

**الحل:**
```bash
# استخدم GitHub Personal Access Token
git config --global credential.helper store
git push origin main
# أدخل username و token (مرة واحدة)
```

---

## 🔐 GitHub Integration

### إنشاء Personal Access Token

1. GitHub → **Settings** → **Developer settings**
2. **Personal access tokens** → **Tokens (classic)**
3. **Generate new token**
4. **Select scopes:** `repo` (full)
5. **Generate token** → انسخه

### تكوين Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global credential.helper store
```

---

## 📚 الملفات المهمة

| File | Purpose |
|------|---------|
| `strategy/simple_strategy.py` | منطق الاستراتيجية |
| `strategy/config_simple.yaml` | إعدادات الاستراتيجية |
| `bridge/generate_signals.py` | توليد bridge.txt |
| `signals/bridge.txt` | ملف الإشارات للـ EA |
| `automation/run_backtest.bat` | تشغيل باكتيست كامل |
| `automation/pull.bat` | سحب من GitHub |
| `automation/tester.ini` | إعدادات MT5 Tester |
| `results/*.json` | نتائج الباكتيست |

---

## 🎓 الخطوات التالية

بعد إتمام الإعداد:

1. ✅ اختبر Simple Strategy على بيانات demo
2. ✅ افهم النتائج والتقارير
3. ✅ ابدأ في تطوير استراتيجيتك الخاصة
4. ✅ طبّق Dyson Strategy (لاحقاً)
5. ✅ حسّن وأمثل البارامترات

---

## ℹ️ Support

- 📖 اقرأ: `README.md`
- 🔗 EA Integration: `EA_INTEGRATION.md`
- 📁 Results Format: `results/README.md`
- 🐛 Issues: GitHub Issues tab

---

**Version:** 1.0  
**Last Updated:** 2025-11-21  
**Status:** ✅ Production Ready
