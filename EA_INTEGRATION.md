# EA Integration Guide

دليل دمج Expert Advisor مع النظام

## 📋 متطلبات EA

### المدخلات المطلوبة (Inputs)

```mql5
// Trading Control
input bool     InpEnableTrading = true;        // Enable actual trading
input double   InpFixedLots = 0.01;            // Fixed lot size
input bool     InpUseRiskFromFile = false;     // Use risk% from file
input int      InpSlippagePoints = 3;          // Slippage in points
input int      InpMagic = 12345;               // Magic number

// File Settings
input ENUM_SOURCE InpSource = MODE_COMMON_FILES;  // 0=Common, 1=Experts
input string   InpFileOrMask = "bridge.txt";      // Signal file name

// Visual Settings
input bool     InpDrawSignals = true;          // Draw arrows on chart
input bool     InpDrawLevels = true;           // Draw SL/TP levels
input color    InpBuyColor = clrGreen;         // Buy arrow color
input color    InpSellColor = clrRed;          // Sell arrow color
```

## 📄 Signal File Format

### الترويسة (Header)
```
timestamp;symbol;action;price;sl;tp;risk;comment
```

### مثال سطر إشارة
```
2025-11-21T10:00:00Z;EURUSD;BUY;1.08500;1.08350;1.08800;1.0;test_signal
```

### شرح الحقول

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `timestamp` | DateTime | ISO format with Z (UTC) | `2025-11-21T10:00:00Z` |
| `symbol` | String | Trading symbol | `EURUSD` |
| `action` | String | BUY or SELL | `BUY` |
| `price` | Double | Entry price | `1.08500` |
| `sl` | Double | Stop Loss | `1.08350` |
| `tp` | Double | Take Profit | `1.08800` |
| `risk` | Double | Risk % or multiplier | `1.0` |
| `comment` | String | Trade comment | `test_signal` |

## 📂 File Locations

### Common Files (Recommended)
```
%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt
```

**Path Example:**
```
C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\Common\Files\bridge.txt
```

### Experts Files
```
%APPDATA%\MetaQuotes\Terminal\{TERMINAL_ID}\MQL5\Files\bridge.txt
```

## 🔄 EA Behavior

### Reading Signals

1. EA يقرأ `bridge.txt` كل تيك
2. يحلل كل سطر بعد الترويسة
3. يتجاهل السطور الفارغة أو الخاطئة
4. يتحقق من Symbol matches current chart
5. يرسم على الشارت حسب الإعدادات

### Drawing on Chart

**إذا `InpDrawSignals = true`:**
- سهم أخضر ↑ عند BUY
- سهم أحمر ↓ عند SELL
- يرسم عند `price` المحدد

**إذا `InpDrawLevels = true`:**
- خط أفقي أخضر عند TP
- خط أفقي أحمر عند SL

### Executing Trades

**إذا `InpEnableTrading = true`:**

1. يتحقق أن Symbol في الملف = Symbol في الشارت
2. يحسب Lot Size:
   - إذا `InpUseRiskFromFile = false` → يستخدم `InpFixedLots`
   - إذا `InpUseRiskFromFile = true` → يحسب من `risk` في الملف
3. يفتح الصفقة:
   - BUY: `OrderSend(symbol, OP_BUY, lots, price, slippage, sl, tp, comment, magic)`
   - SELL: `OrderSend(symbol, OP_SELL, lots, price, slippage, sl, tp, comment, magic)`

### Magic Number

- كل صفقة تأخذ `InpMagic` المحدد
- يسمح للـ EA بإدارة صفقاته فقط
- لا يتعارض مع صفقات يدوية أو EA آخر

## 🧪 Testing في Strategy Tester

### خطوات الاختبار

1. **تحضير bridge.txt**
   ```bash
   python bridge/generate_signals.py
   ```

2. **نسخ إلى Common Files**
   ```bash
   copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"
   ```

3. **إعدادات Strategy Tester**
   - Expert: `EA_SignalBridge.ex5`
   - Symbol: مثلاً `EURUSD`
   - Period: مثلاً `M15`
   - Dates: من - إلى
   - Model: `Every tick` (الأدق)

4. **Inputs في Tester**
   ```
   InpEnableTrading = true
   InpSource = MODE_COMMON_FILES (0)
   InpFileOrMask = "bridge.txt"
   InpFixedLots = 0.01
   InpUseRiskFromFile = false
   InpDrawSignals = true
   InpDrawLevels = true
   ```

5. **تشغيل**
   - Start
   - انتظر انتهاء الاختبار
   - راجع التقرير

### ملاحظات مهمة

- ⚠️ **bridge.txt يجب أن يكون موجود قبل بدء الاختبار**
- ⚠️ **Symbol في الملف = Symbol في Tester**
- ⚠️ **Timeframe قد يؤثر على النتائج إذا الإشارات خارج نطاق البيانات**
- ✅ **استخدم "Every tick" للدقة القصوى**

## 🔍 Debugging

### مشاكل شائعة

**1. EA لا يقرأ الملف**
- ✅ تحقق أن الملف موجود في المسار الصحيح
- ✅ تحقق أن `InpSource` صحيح
- ✅ تحقق أن `InpFileOrMask` اسم الملف صحيح

**2. لا توجد إشارات على الشارت**
- ✅ تحقق `InpDrawSignals = true`
- ✅ تحقق أن Symbol في الملف = Symbol في الشارت
- ✅ تحقق تنسيق الملف صحيح

**3. لا يفتح صفقات**
- ✅ تحقق `InpEnableTrading = true`
- ✅ تحقق أن Balance كافي
- ✅ تحقق أن Symbol متاح للتداول
- ✅ راجع Logs في Experts tab

**4. خطأ في تحليل الملف**
- ✅ تحقق الترويسة بالضبط: `timestamp;symbol;action;price;sl;tp;risk;comment`
- ✅ تحقق لا توجد مسافات إضافية
- ✅ تحقق الفواصل منقوطة `;` وليس `,`
- ✅ تحقق timestamp بتنسيق ISO مع Z

## 📊 Performance Tips

### لتحسين الأداء

1. **تقليل عدد الإشارات**
   - فلتر الإشارات الضعيفة في Python
   - لا ترسل إشارة كل شمعة إلا إذا ضروري

2. **استخدام Magic Number مختلف**
   - لكل استراتيجية Magic مختلف
   - يسهل التتبع والتحليل

3. **Visual Settings في Live**
   - في الحساب الحقيقي، قد تعطل الرسم:
   ```
   InpDrawSignals = false
   InpDrawLevels = false
   ```
   - يقلل استهلاك الموارد

## 🔗 Integration Workflow

```
1. Python Strategy (strategy/)
   ↓ generates
2. bridge.txt (signals/)
   ↓ copy to
3. MT5 Common Files
   ↓ read by
4. EA_SignalBridge
   ↓ executes
5. Trades in MT5
```

## 📝 Example: Full Cycle

```bash
# 1. Generate signals
python bridge/generate_signals.py

# 2. Copy to MT5
copy signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"

# 3. Run backtest (automated)
automation\run_backtest.bat

# 4. Check results
# results/backtest_report.html
```

---

**Version:** 1.0  
**Compatible EA:** EA_SignalBridge (v2.0+)  
**Last Updated:** 2025-11-21
