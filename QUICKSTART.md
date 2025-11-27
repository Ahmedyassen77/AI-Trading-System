# Quick Start - أسرع طريقة لتشغيل النظام

---

## ⚡ السريع جداً (للمحترفين)

```bash
# 1. Clone
git clone https://github.com/Ahmedyassen77/AI-Trading-System.git
cd AI-Trading-System

# 2. Install
pip install -r requirements.txt

# 3. Run backtest
RUN_BACKTEST.bat
```

**Done! ✅** MT5 Strategy Tester سيفتح تلقائياً

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

### 5️⃣ شغّل الباكتيست

**الطريقة الأسهل - ملف واحد:**
```bash
RUN_BACKTEST.bat
```

**أو الطريقة المفصلة:**
```bash
# توليد الإشارات
python bridge\generate_signals.py

# نسخ للـ MT5
copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"
copy signals\drawings.json "%APPDATA%\MetaQuotes\Terminal\Common\Files\drawings.json"

# تشغيل MT5 Tester
automation\run_tester.bat
```

---

## 🎯 الملفات المهمة

| الملف | الوظيفة |
|-------|---------|
| `RUN_BACKTEST.bat` | ✨ **استخدم هذا** - يعمل كل شيء تلقائياً |
| `automation/run_tester.bat` | يفتح MT5 Strategy Tester فقط |
| `bridge/generate_signals.py` | يولد الإشارات والرسومات |
| `strategy/config.yaml` | إعدادات الاستراتيجية |

---

## ⚙️ إعدادات سريعة

### تعديل الرمز والفترة:

```yaml
# افتح strategy/config.yaml
symbol: "GBPUSD"  # غير الرمز
ltf_timeframe: "M1"  # غير الفريم
backtest_bars: 5000  # غير عدد الشموع
```

### تعديل المخاطرة:

```yaml
risk_pct: 2.0  # كانت 1.0
min_rr: 3.0    # كان 2.0
```

**ثم شغّل:** `RUN_BACKTEST.bat`

---

## 🔍 فهم النتائج

### بعد تشغيل generate_signals.py:

```
📊 HTF Bias: BULLISH          ← الاتجاه العام
📈 Statistics:
   - Swing Highs: 288         ← عدد القمم
   - Swing Lows: 279          ← عدد القيعان
   - Sweeps: 516              ← عدد Sweeps
   - Order Blocks: 26         ← عدد OB
   - Signals: 11              ← عدد الصفقات
```

### الملفات المولدة:

1. **`signals/bridge.txt`** - الإشارات للـ EA
2. **`signals/drawings.json`** - معلومات الرسم
3. **`signals/smc_analysis.json`** - التحليل الكامل

---

## 🎨 ماذا سيرسم EA على الشارت؟

| المفهوم | الشكل | اللون |
|---------|-------|-------|
| HTF Bias | خلفية | أخضر/أحمر فاتح |
| Swing High | خط أفقي | برتقالي |
| Swing Low | خط أفقي | أزرق |
| BOS | سهم | قرمزي |
| CHoCH | سهم | سماوي |
| Order Block | مستطيل | أخضر/أحمر |
| FVG | مستطيل | أصفر |
| Liquidity | مستطيل | برتقالي/أزرق |
| Sweep | X | بنفسجي |

---

## 🆘 مشاكل شائعة

### ❌ `MT5 terminal64.exe not found`

**الحل:**
```batch
# افتح automation\run_tester.bat
# عدّل السطر:
set "TERM=C:\Program Files\MetaTrader 5\terminal64.exe"

# إلى المسار الصحيح على جهازك
```

### ❌ `ModuleNotFoundError: No module named 'yaml'`

**الحل:**
```bash
pip install pyyaml
```

### ❌ EA لا يقرأ الملفات

**الحل:**
```
1. تأكد الملفات في:
   %APPDATA%\MetaQuotes\Terminal\Common\Files\

2. EA Inputs:
   InpSource = 0 (MODE_COMMON_FILES)
   InpFileOrMask = "bridge.txt"
   InpDrawingsFile = "drawings.json"
```

---

## 🚀 الخطوة التالية

**الآن النظام شغال! جرّب:**

1. ✅ غير الإعدادات في `config.yaml`
2. ✅ شغّل `RUN_BACKTEST.bat` مرة ثانية
3. ✅ راجع النتائج في MT5
4. ✅ حلل الصفقات

**للتطوير:**
- عدّل `strategy/strategy.py` لتغيير المنطق
- عدّل `config.yaml` لتغيير البارامترات
- كل شيء سهل التعديل!

---

**Time to first backtest: < 5 minutes ⚡**

**كل ما تحتاجه:** `RUN_BACKTEST.bat` 🎯
