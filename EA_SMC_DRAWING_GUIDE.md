# EA SMC Drawing Guide

دليل كامل للـ EA لقراءة ورسم مفاهيم SMC على الشارت

---

## 📋 Overview

النظام الآن يولد **ملفين**:

1. **`bridge.txt`** - إشارات التداول (كما كان سابقاً)
2. **`drawings.json`** - معلومات الرسم لكل مفاهيم SMC

---

## 📄 ملف drawings.json

### الهيكل العام

```json
[
  {
    "type": "background",
    "object": "htf_bias",
    "color": "green_light",
    "label": "HTF Bias: BULLISH"
  },
  {
    "type": "line",
    "object": "swing_high",
    "time": "2025-11-23T06:31:47Z",
    "price": 1.09149,
    "color": "orange",
    "label": "SH"
  },
  {
    "type": "rectangle",
    "object": "bullish_ob",
    "time": "2025-11-23T08:00:00Z",
    "price_high": 1.09200,
    "price_low": 1.09150,
    "color": "green",
    "label": "BULLISH OB",
    "extend": true
  }
  // ... more objects
]
```

---

## 🎨 أنواع الرسومات (Drawing Types)

### 1. Background (HTF Bias)

**الهدف:** تظليل خلفية الشارت لإظهار الاتجاه العام

```json
{
  "type": "background",
  "object": "htf_bias",
  "color": "green_light",  // or "red_light"
  "label": "HTF Bias: BULLISH"
}
```

**كيف يرسمها EA:**
```mql5
// ارسم مستطيل شفاف يغطي كامل الشارت
ObjectCreate(0, "HTF_Bias_BG", OBJ_RECTANGLE, 0, 
             Time[WindowFirstVisibleBar()], 
             ChartGetDouble(0, CHART_PRICE_MAX),
             Time[0], 
             ChartGetDouble(0, CHART_PRICE_MIN));

// لون شفاف خفيف
if(color == "green_light")
   ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_COLOR, clrLightGreen);
else if(color == "red_light")
   ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_COLOR, clrLightPink);

ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_BACK, true);
ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_FILL, true);

// Label
ObjectCreate(0, "HTF_Bias_Label", OBJ_LABEL, 0, 0, 0);
ObjectSetString(0, "HTF_Bias_Label", OBJPROP_TEXT, label);
ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_XDISTANCE, 10);
ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_YDISTANCE, 30);
```

---

### 2. Line (Swing Highs/Lows)

**الهدف:** خطوط أفقية عند القمم والقيعان الهيكلية

```json
{
  "type": "line",
  "object": "swing_high",  // or "swing_low"
  "time": "2025-11-23T06:31:47Z",
  "price": 1.09149,
  "color": "orange",  // or "blue"
  "label": "SH"  // or "SL"
}
```

**كيف يرسمها EA:**
```mql5
datetime objTime = StringToTime(time);

// خط أفقي
string objName = "SwingHigh_" + TimeToString(objTime);
ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price);

// اللون
if(color == "orange")
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrOrange);
else if(color == "blue")
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlue);

ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);

// Text Label
string labelName = objName + "_Label";
ObjectCreate(0, labelName, OBJ_TEXT, 0, objTime, price);
ObjectSetString(0, labelName, OBJPROP_TEXT, label);
ObjectSetInteger(0, labelName, OBJPROP_COLOR, color);
```

---

### 3. Arrow (BOS/CHoCH)

**الهدف:** سهم يشير لحدث BOS أو CHoCH

```json
{
  "type": "arrow",
  "object": "bos_bullish",  // or "choch_bearish"
  "time": "2025-11-23T08:00:00Z",
  "price": 1.09200,
  "color": "magenta",  // or "cyan"
  "label": "BOS_BULLISH",
  "direction": "bullish"  // or "bearish"
}
```

**كيف يرسمها EA:**
```mql5
datetime objTime = StringToTime(time);

string objName = "BOS_" + TimeToString(objTime);

// سهم صاعد أو هابط
int arrowCode;
if(direction == "bullish")
   arrowCode = 233;  // ↑
else
   arrowCode = 234;  // ↓

ObjectCreate(0, objName, OBJ_ARROW, 0, objTime, price);
ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);

// اللون
if(color == "magenta")
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMagenta);
else if(color == "cyan")
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrCyan);

ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);

// Label
string labelName = objName + "_Text";
ObjectCreate(0, labelName, OBJ_TEXT, 0, objTime, price);
ObjectSetString(0, labelName, OBJPROP_TEXT, label);
```

---

### 4. Rectangle (OB/FVG/Liquidity)

**الهدف:** مستطيل يظلل منطقة محددة

```json
{
  "type": "rectangle",
  "object": "bullish_ob",  // or "fvg", "liquidity_high"
  "time": "2025-11-23T08:00:00Z",
  "price_high": 1.09200,
  "price_low": 1.09150,
  "color": "green",
  "label": "BULLISH OB",
  "extend": true  // تمديد لليمين
}
```

**كيف يرسمها EA:**
```mql5
datetime objTime = StringToTime(time);
datetime endTime;

if(extend == true)
   endTime = TimeCurrent() + PeriodSeconds(PERIOD_CURRENT) * 100;
else
   endTime = objTime + PeriodSeconds(PERIOD_CURRENT) * 20;

string objName = object + "_" + TimeToString(objTime);

ObjectCreate(0, objName, OBJ_RECTANGLE, 0, 
             objTime, price_high,
             endTime, price_low);

// اللون والشفافية
color rectColor;
if(color == "green")
   rectColor = clrGreen;
else if(color == "red")
   rectColor = clrRed;
else if(color == "yellow")
   rectColor = clrYellow;
else if(color == "orange")
   rectColor = clrOrange;
else if(color == "blue")
   rectColor = clrBlue;

ObjectSetInteger(0, objName, OBJPROP_COLOR, rectColor);
ObjectSetInteger(0, objName, OBJPROP_BACK, true);
ObjectSetInteger(0, objName, OBJPROP_FILL, true);
ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);

// Label داخل المستطيل
string labelName = objName + "_Label";
double midPrice = (price_high + price_low) / 2;
ObjectCreate(0, labelName, OBJ_TEXT, 0, objTime, midPrice);
ObjectSetString(0, labelName, OBJPROP_TEXT, label);
ObjectSetInteger(0, labelName, OBJPROP_COLOR, rectColor);
ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
```

---

### 5. Marker (Sweep)

**الهدف:** علامة X أو دائرة عند نقطة Sweep

```json
{
  "type": "marker",
  "object": "sweep",
  "time": "2025-11-23T09:00:00Z",
  "price": 1.09250,
  "color": "purple",
  "label": "SWEEP HIGH",
  "marker": "X"
}
```

**كيف يرسمها EA:**
```mql5
datetime objTime = StringToTime(time);

string objName = "Sweep_" + TimeToString(objTime);

// علامة X كبيرة
ObjectCreate(0, objName, OBJ_ARROW, 0, objTime, price);
ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 251);  // X symbol
ObjectSetInteger(0, objName, OBJPROP_COLOR, clrPurple);
ObjectSetInteger(0, objName, OBJPROP_WIDTH, 5);

// Label
string labelName = objName + "_Text";
ObjectCreate(0, labelName, OBJ_TEXT, 0, objTime, price);
ObjectSetString(0, labelName, OBJPROP_TEXT, label);
ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrPurple);
```

---

## 🔧 EA Implementation

### كود كامل لقراءة drawings.json

```mql5
#include <jason.mqh>  // مكتبة JSON

//+------------------------------------------------------------------+
//| قراءة ملف drawings.json                                          |
//+------------------------------------------------------------------+
void ReadAndDrawSMC()
{
   string filePath = "drawings.json";
   
   // فتح الملف
   int fileHandle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_COMMON);
   if(fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot open drawings.json");
      return;
   }
   
   // قراءة المحتوى
   string jsonContent = "";
   while(!FileIsEnding(fileHandle))
      jsonContent += FileReadString(fileHandle);
   
   FileClose(fileHandle);
   
   // Parse JSON
   CJAVal json;
   if(!json.Deserialize(jsonContent))
   {
      Print("ERROR: Failed to parse JSON");
      return;
   }
   
   // حذف الرسومات القديمة
   DeleteOldDrawings();
   
   // رسم كل object
   for(int i = 0; i < json.Size(); i++)
   {
      CJAVal obj = json[i];
      
      string type = obj["type"].ToStr();
      
      if(type == "background")
         DrawBackground(obj);
      else if(type == "line")
         DrawLine(obj);
      else if(type == "arrow")
         DrawArrow(obj);
      else if(type == "rectangle")
         DrawRectangle(obj);
      else if(type == "marker")
         DrawMarker(obj);
   }
   
   Print("✅ Drew ", json.Size(), " SMC objects");
}

//+------------------------------------------------------------------+
//| رسم Background                                                    |
//+------------------------------------------------------------------+
void DrawBackground(CJAVal &obj)
{
   string label = obj["label"].ToStr();
   string colorStr = obj["color"].ToStr();
   
   color bgColor = (colorStr == "green_light") ? clrLightGreen : clrLightPink;
   
   // مستطيل يغطي الشارت
   ObjectCreate(0, "HTF_Bias_BG", OBJ_RECTANGLE, 0,
                Time[WindowFirstVisibleBar()],
                ChartGetDouble(0, CHART_PRICE_MAX),
                Time[0],
                ChartGetDouble(0, CHART_PRICE_MIN));
   
   ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_COLOR, bgColor);
   ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_BACK, true);
   ObjectSetInteger(0, "HTF_Bias_BG", OBJPROP_FILL, true);
   
   // Label
   ObjectCreate(0, "HTF_Bias_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "HTF_Bias_Label", OBJPROP_TEXT, label);
   ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, "HTF_Bias_Label", OBJPROP_COLOR, clrBlack);
}

//+------------------------------------------------------------------+
//| رسم Line (Swing High/Low)                                        |
//+------------------------------------------------------------------+
void DrawLine(CJAVal &obj)
{
   datetime objTime = StringToTime(obj["time"].ToStr());
   double price = obj["price"].ToDbl();
   string label = obj["label"].ToStr();
   string colorStr = obj["color"].ToStr();
   
   color lineColor = (colorStr == "orange") ? clrOrange : clrBlue;
   
   string objName = obj["object"].ToStr() + "_" + TimeToString(objTime);
   
   ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   
   // Label
   string labelName = objName + "_Label";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, objTime, price);
   ObjectSetString(0, labelName, OBJPROP_TEXT, label);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
}

//+------------------------------------------------------------------+
//| رسم Rectangle (OB/FVG)                                           |
//+------------------------------------------------------------------+
void DrawRectangle(CJAVal &obj)
{
   datetime objTime = StringToTime(obj["time"].ToStr());
   double priceHigh = obj["price_high"].ToDbl();
   double priceLow = obj["price_low"].ToDbl();
   string label = obj["label"].ToStr();
   string colorStr = obj["color"].ToStr();
   bool extend = obj["extend"].ToBool();
   
   datetime endTime = extend ? 
                     (TimeCurrent() + PeriodSeconds(PERIOD_CURRENT) * 100) :
                     (objTime + PeriodSeconds(PERIOD_CURRENT) * 20);
   
   color rectColor;
   if(colorStr == "green") rectColor = clrGreen;
   else if(colorStr == "red") rectColor = clrRed;
   else if(colorStr == "yellow") rectColor = clrYellow;
   else if(colorStr == "orange") rectColor = clrOrange;
   else if(colorStr == "blue") rectColor = clrBlue;
   else rectColor = clrGray;
   
   string objName = obj["object"].ToStr() + "_" + TimeToString(objTime);
   
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0,
                objTime, priceHigh,
                endTime, priceLow);
   
   ObjectSetInteger(0, objName, OBJPROP_COLOR, rectColor);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   
   // Label
   string labelName = objName + "_Label";
   double midPrice = (priceHigh + priceLow) / 2;
   ObjectCreate(0, labelName, OBJ_TEXT, 0, objTime, midPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, label);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, rectColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| حذف الرسومات القديمة                                             |
//+------------------------------------------------------------------+
void DeleteOldDrawings()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      // حذف كل objects المتعلقة بـ SMC
      if(StringFind(name, "HTF_") >= 0 ||
         StringFind(name, "swing_") >= 0 ||
         StringFind(name, "BOS_") >= 0 ||
         StringFind(name, "bullish_ob") >= 0 ||
         StringFind(name, "bearish_ob") >= 0 ||
         StringFind(name, "fvg") >= 0 ||
         StringFind(name, "Sweep_") >= 0)
      {
         ObjectDelete(0, name);
      }
   }
}
```

---

## 📊 ملخص الألوان

| Concept | Object | Color | Type |
|---------|--------|-------|------|
| HTF Bullish Bias | background | Light Green | Rectangle |
| HTF Bearish Bias | background | Light Pink | Rectangle |
| Swing High | line | Orange | HLine |
| Swing Low | line | Blue | HLine |
| BOS | arrow | Magenta | Arrow |
| CHoCH | arrow | Cyan | Arrow |
| Bullish OB | rectangle | Green | Rectangle |
| Bearish OB | rectangle | Red | Rectangle |
| FVG | rectangle | Yellow | Rectangle |
| External Liq High | rectangle | Orange | Rectangle |
| External Liq Low | rectangle | Blue | Rectangle |
| Sweep | marker | Purple | X Mark |

---

## 🔄 Workflow

```
1. Python يحلل ويولد drawings.json
   ↓
2. EA يقرأ drawings.json
   ↓
3. EA يرسم كل object على الشارت
   ↓
4. EA يقرأ bridge.txt وينفذ الصفقات
```

---

## ✅ Checklist للـ EA

- [ ] قراءة drawings.json من Common Files
- [ ] Parse JSON بشكل صحيح
- [ ] رسم Background للـ HTF Bias
- [ ] رسم Lines للـ Swing Points
- [ ] رسم Arrows للـ BOS/CHoCH
- [ ] رسم Rectangles للـ OB/FVG/Liquidity
- [ ] رسم Markers للـ Sweeps
- [ ] حذف الرسومات القديمة قبل رسم جديد
- [ ] قراءة bridge.txt وتنفيذ الصفقات
- [ ] تحديث الرسومات كل فترة

---

**Version:** 1.0  
**Last Updated:** 2025-11-21  
**Status:** ✅ Ready for EA Implementation
