# Quick Start - 5 Minutes Setup

أسرع طريقة لتشغيل النظام

---

## ⚡ السريع جداً (للمحترفين)

```bash
# 1. Clone
git clone https://github.com/Ahmedyassen77/AI-Trading-System.git
cd AI-Trading-System

# 2. Install
pip install -r requirements.txt

# 3. Test System
python test_system.py

# 4. Generate Signals
python bridge/generate_signals.py

# 5. Copy to MT5
copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"

# 6. Open MT5 Strategy Tester → EA_SignalBridge → Start
```

**Done! ✅**

---

## 📝 الأساسي (خطوة بخطوة)

### 1️⃣ جهز البيئة

```bash
# تأكد من Python
python --version  # يجب 3.8+

# تأكد من Git
git --version
```

### 2️⃣ نزّل المشروع

```bash
cd C:\
git clone https://github.com/Ahmedyassen77/AI-Trading-System.git
cd AI-Trading-System
```

### 3️⃣ نصّب المكتبات

```bash
pip install MetaTrader5 pandas pyyaml numpy
```

### 4️⃣ اختبر النظام

```bash
python test_system.py
```

**المفروض تشوف:**
```
✅ PASS - Directory Structure
✅ PASS - Required Files
✅ PASS - Strategy Import
✅ PASS - Config Loading
✅ PASS - Signal Generation
Results: 5/6 tests passed
```

*(MT5 import سيفشل لأنه مش مطلوب الآن)*

### 5️⃣ ولّد الإشارات

```bash
python bridge\generate_signals.py
```

**المفروض تشوف:**
```
✅ تم جلب 2000 شمعة
✅ تم توليد 1999 إشارة
✅ تم! الملف جاهز للـ EA
```

### 6️⃣ انسخ للـ MT5

```bash
copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"
```

### 7️⃣ شغّل Backtest

1. افتح **MT5**
2. اضغط **Ctrl+R** (Strategy Tester)
3. اختر **EA_SignalBridge**
4. Symbol: **EURUSD**, Period: **M15**
5. Inputs:
   - `InpEnableTrading = true`
   - `InpSource = 0`
   - `InpFileOrMask = "bridge.txt"`
6. اضغط **Start**

**Done! ✅**

---

## 🎯 الأسرع (سكربت واحد)

```bash
automation\run_backtest.bat
```

هذا يعمل كل شيء تلقائياً!

---

## 📚 للتفاصيل الكاملة

- **Setup الكامل:** [SETUP.md](SETUP.md)
- **الوثائق:** [README.md](README.md)
- **EA Integration:** [EA_INTEGRATION.md](EA_INTEGRATION.md)

---

## ✅ تأكد أن كل شيء شغال

```bash
# 1. النظام صحيح
python test_system.py

# 2. الإشارات اتولدت
dir signals\bridge.txt

# 3. الملف في MT5
dir "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"
```

---

## 🆘 مشاكل شائعة

**❌ Python لا يعمل**
```bash
# ثبّت من python.org
# تأكد من تفعيل "Add to PATH"
```

**❌ pip لا يعمل**
```bash
python -m pip install --upgrade pip
```

**❌ MT5 ما يلقى الملف**
```bash
# تأكد نسخت للمكان الصحيح
echo %APPDATA%\MetaQuotes\Terminal\Common\Files
```

**❌ EA ما يشتغل**
```bash
# في MT5:
# Tools → Options → Expert Advisors
# ✅ Allow automated trading
# ✅ Allow DLL imports
```

---

## 🚀 الخطوة التالية

الآن النظام شغال! 

**بعدين:**
1. ✅ افهم النتائج من الباكتيست
2. ✅ عدّل في `strategy/config_simple.yaml`
3. ✅ جرب إعدادات مختلفة
4. ✅ طوّر استراتيجيتك الخاصة

**للتطوير:**
```bash
# عدّل الاستراتيجية
notepad strategy\simple_strategy.py

# عدّل الإعدادات
notepad strategy\config_simple.yaml

# ولّد إشارات جديدة
python bridge\generate_signals.py

# اختبر
automation\run_backtest.bat
```

---

**Time to first backtest: < 5 minutes ⚡**
