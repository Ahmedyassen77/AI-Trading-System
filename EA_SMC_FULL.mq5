//+------------------------------------------------------------------+
//|                                                  EA_SMC_FULL.mq5 |
//|                                    Smart Money Concepts Strategy |
//|                                         Full Strategy Implementation |
//+------------------------------------------------------------------+
#property copyright "SMC Trading System"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== استراتيجية SMC ==="
input ENUM_TIMEFRAMES InpHTF = PERIOD_H4;        // HTF Timeframe (للـ Bias)
input ENUM_TIMEFRAMES InpMTF = PERIOD_M15;       // MTF Timeframe (للـ Structure)
input ENUM_TIMEFRAMES InpLTF = PERIOD_M5;        // LTF Timeframe (للـ Entry)

input group "=== Risk Management ==="
input double InpRiskPercent = 1.0;               // Risk % من الرصيد
input double InpMinRR = 2.0;                     // أقل Risk:Reward
input int    InpSLPoints = 150;                  // Stop Loss (points) احتياطي
input int    InpTPPoints = 300;                  // Take Profit (points) احتياطي

input group "=== Swing Detection ==="
input int    InpSwingLookback = 3;               // Swing Lookback Bars
input double InpSweepThreshold = 100;            // Sweep Threshold (points)

input group "=== Session Filter ==="
input bool   InpUseAsianFilter = true;           // تجاهل OB من الجلسة الآسيوية
input int    InpAsianStart = 23;                 // Asian Session Start (UTC)
input int    InpAsianEnd = 7;                    // Asian Session End (UTC)

input group "=== Order Block Settings ==="
input int    InpOBLookback = 10;                 // OB Max Lookback Bars
input bool   InpDrawOB = true;                   // رسم Order Blocks

input group "=== FVG Settings ==="
input double InpFVGMinPips = 5;                  // FVG Min Size (pips)
input bool   InpDrawFVG = true;                  // رسم FVG

input group "=== Trading Control ==="
input int    InpMagicNumber = 88888;             // Magic Number
input int    InpSlippage = 3;                    // Slippage
input bool   InpEnableTrading = true;            // Enable Trading

//--- Global Variables
CTrade trade;
datetime lastBarTime = 0;

//--- Structures
struct SwingPoint {
   datetime time;
   double   price;
   bool     isHigh;
};

struct OrderBlock {
   datetime timeStart;
   datetime timeEnd;
   double   priceHigh;
   double   priceLow;
   bool     isBullish;
   bool     isValid;
};

struct FVG {
   datetime timeStart;
   datetime timeEnd;
   double   priceHigh;
   double   priceLow;
   bool     isBullish;
   bool     isValid;
};

//--- Arrays
SwingPoint swingHighs[];
SwingPoint swingLows[];
OrderBlock orderBlocks[];
FVG fvgs[];

//--- HTF Bias
enum ENUM_BIAS {
   BIAS_BULLISH,
   BIAS_BEARISH,
   BIAS_NEUTRAL
};

ENUM_BIAS currentBias = BIAS_NEUTRAL;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("  EA SMC - Smart Money Concepts");
   Print("  HTF: ", EnumToString(InpHTF));
   Print("  MTF: ", EnumToString(InpMTF));
   Print("  LTF: ", EnumToString(InpLTF));
   Print("  Risk: ", InpRiskPercent, "%");
   Print("  Min R:R: ", InpMinRR);
   Print("========================================");
   
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   ArrayResize(swingHighs, 0);
   ArrayResize(swingLows, 0);
   ArrayResize(orderBlocks, 0);
   ArrayResize(fvgs, 0);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "SMC_");
   Print("EA SMC stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check for new bar on LTF
   datetime currentBarTime = iTime(_Symbol, InpLTF, 0);
   if(currentBarTime == lastBarTime)
      return;
   
   lastBarTime = currentBarTime;
   
   //--- Update SMC Analysis
   UpdateHTFBias();
   UpdateSwingPoints();
   UpdateOrderBlocks();
   UpdateFVGs();
   
   //--- Check for Entry Signals
   if(InpEnableTrading)
   {
      CheckForEntry();
   }
   
   //--- Draw Concepts
   DrawAllConcepts();
}

//+------------------------------------------------------------------+
//| Update HTF Bias                                                    |
//+------------------------------------------------------------------+
void UpdateHTFBias()
{
   //--- Get HTF data
   double htfHigh[], htfLow[], htfClose[];
   ArraySetAsSeries(htfHigh, true);
   ArraySetAsSeries(htfLow, true);
   ArraySetAsSeries(htfClose, true);
   
   if(CopyHigh(_Symbol, InpHTF, 0, 100, htfHigh) < 100) return;
   if(CopyLow(_Symbol, InpHTF, 0, 100, htfLow) < 100) return;
   if(CopyClose(_Symbol, InpHTF, 0, 100, htfClose) < 100) return;
   
   //--- Find last major BOS/CHoCH on HTF
   double lastSwingHigh = htfHigh[ArrayMaximum(htfHigh, 0, 20)];
   double lastSwingLow = htfLow[ArrayMinimum(htfLow, 0, 20)];
   
   //--- Determine bias based on structure
   if(htfClose[0] > lastSwingHigh)
   {
      currentBias = BIAS_BULLISH;
   }
   else if(htfClose[0] < lastSwingLow)
   {
      currentBias = BIAS_BEARISH;
   }
}

//+------------------------------------------------------------------+
//| Update Swing Points on LTF                                         |
//+------------------------------------------------------------------+
void UpdateSwingPoints()
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   int bars = 50;
   if(CopyHigh(_Symbol, InpLTF, 0, bars, high) < bars) return;
   if(CopyLow(_Symbol, InpLTF, 0, bars, low) < bars) return;
   
   //--- Clear old swings
   ArrayResize(swingHighs, 0);
   ArrayResize(swingLows, 0);
   
   //--- Find swing highs
   for(int i = InpSwingLookback; i < bars - InpSwingLookback; i++)
   {
      bool isSwingHigh = true;
      
      for(int j = 1; j <= InpSwingLookback; j++)
      {
         if(high[i] <= high[i-j] || high[i] <= high[i+j])
         {
            isSwingHigh = false;
            break;
         }
      }
      
      if(isSwingHigh)
      {
         SwingPoint sp;
         sp.time = iTime(_Symbol, InpLTF, i);
         sp.price = high[i];
         sp.isHigh = true;
         
         int size = ArraySize(swingHighs);
         ArrayResize(swingHighs, size + 1);
         swingHighs[size] = sp;
      }
   }
   
   //--- Find swing lows
   for(int i = InpSwingLookback; i < bars - InpSwingLookback; i++)
   {
      bool isSwingLow = true;
      
      for(int j = 1; j <= InpSwingLookback; j++)
      {
         if(low[i] >= low[i-j] || low[i] >= low[i+j])
         {
            isSwingLow = false;
            break;
         }
      }
      
      if(isSwingLow)
      {
         SwingPoint sp;
         sp.time = iTime(_Symbol, InpLTF, i);
         sp.price = low[i];
         sp.isHigh = false;
         
         int size = ArraySize(swingLows);
         ArrayResize(swingLows, size + 1);
         swingLows[size] = sp;
      }
   }
}

//+------------------------------------------------------------------+
//| Update Order Blocks                                                |
//+------------------------------------------------------------------+
void UpdateOrderBlocks()
{
   ArrayResize(orderBlocks, 0);
   
   double open[], high[], low[], close[];
   datetime time[];
   
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   
   int bars = 50;
   if(CopyOpen(_Symbol, InpLTF, 0, bars, open) < bars) return;
   if(CopyHigh(_Symbol, InpLTF, 0, bars, high) < bars) return;
   if(CopyLow(_Symbol, InpLTF, 0, bars, low) < bars) return;
   if(CopyClose(_Symbol, InpLTF, 0, bars, close) < bars) return;
   if(CopyTime(_Symbol, InpLTF, 0, bars, time) < bars) return;
   
   //--- Find bullish OB (last red candle before strong green move)
   for(int i = 2; i < bars - 2; i++)
   {
      //--- Check for strong bullish move
      if(close[i-1] > close[i] && close[i-1] - close[i] > 10 * _Point)
      {
         //--- Check if current candle is bearish (OB candidate)
         if(close[i] < open[i])
         {
            //--- Check Asian session filter
            if(InpUseAsianFilter)
            {
               MqlDateTime dt;
               TimeToStruct(time[i], dt);
               if(dt.hour >= InpAsianStart || dt.hour < InpAsianEnd)
                  continue; // Skip Asian session OB
            }
            
            OrderBlock ob;
            ob.timeStart = time[i];
            ob.timeEnd = time[0];
            ob.priceHigh = high[i];
            ob.priceLow = low[i];
            ob.isBullish = true;
            ob.isValid = true;
            
            int size = ArraySize(orderBlocks);
            ArrayResize(orderBlocks, size + 1);
            orderBlocks[size] = ob;
         }
      }
      
      //--- Check for strong bearish move
      if(close[i-1] < close[i] && close[i] - close[i-1] > 10 * _Point)
      {
         //--- Check if current candle is bullish (OB candidate)
         if(close[i] > open[i])
         {
            //--- Check Asian session filter
            if(InpUseAsianFilter)
            {
               MqlDateTime dt;
               TimeToStruct(time[i], dt);
               if(dt.hour >= InpAsianStart || dt.hour < InpAsianEnd)
                  continue;
            }
            
            OrderBlock ob;
            ob.timeStart = time[i];
            ob.timeEnd = time[0];
            ob.priceHigh = high[i];
            ob.priceLow = low[i];
            ob.isBullish = false;
            ob.isValid = true;
            
            int size = ArraySize(orderBlocks);
            ArrayResize(orderBlocks, size + 1);
            orderBlocks[size] = ob;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update Fair Value Gaps                                            |
//+------------------------------------------------------------------+
void UpdateFVGs()
{
   ArrayResize(fvgs, 0);
   
   double high[], low[];
   datetime time[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   
   int bars = 50;
   if(CopyHigh(_Symbol, InpLTF, 0, bars, high) < bars) return;
   if(CopyLow(_Symbol, InpLTF, 0, bars, low) < bars) return;
   if(CopyTime(_Symbol, InpLTF, 0, bars, time) < bars) return;
   
   double minGap = InpFVGMinPips * _Point * 10;
   
   //--- Find FVGs (3-candle pattern)
   for(int i = 2; i < bars - 1; i++)
   {
      //--- Bullish FVG: low[i-1] > high[i+1]
      if(low[i-1] > high[i+1])
      {
         double gapSize = low[i-1] - high[i+1];
         if(gapSize >= minGap)
         {
            FVG fvg;
            fvg.timeStart = time[i+1];
            fvg.timeEnd = time[0];
            fvg.priceHigh = low[i-1];
            fvg.priceLow = high[i+1];
            fvg.isBullish = true;
            fvg.isValid = true;
            
            int size = ArraySize(fvgs);
            ArrayResize(fvgs, size + 1);
            fvgs[size] = fvg;
         }
      }
      
      //--- Bearish FVG: high[i-1] < low[i+1]
      if(high[i-1] < low[i+1])
      {
         double gapSize = low[i+1] - high[i-1];
         if(gapSize >= minGap)
         {
            FVG fvg;
            fvg.timeStart = time[i+1];
            fvg.timeEnd = time[0];
            fvg.priceHigh = low[i+1];
            fvg.priceLow = high[i-1];
            fvg.isBullish = false;
            fvg.isValid = true;
            
            int size = ArraySize(fvgs);
            ArrayResize(fvgs, size + 1);
            fvgs[size] = fvg;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for Entry Signal                                             |
//+------------------------------------------------------------------+
void CheckForEntry()
{
   //--- Check if already in trade
   if(PositionSelect(_Symbol))
      return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   //--- Check for BUY signal
   if(currentBias == BIAS_BULLISH)
   {
      //--- Look for bullish OB touch
      for(int i = 0; i < ArraySize(orderBlocks); i++)
      {
         if(!orderBlocks[i].isBullish || !orderBlocks[i].isValid)
            continue;
         
         //--- Check if price is in OB zone
         if(bid >= orderBlocks[i].priceLow && bid <= orderBlocks[i].priceHigh)
         {
            //--- Check for confirmation candle
            if(IsEngulfingBullish() || IsInsideBar())
            {
               //--- Find nearest liquidity for TP
               double tp = FindNearestLiquidity(true);
               if(tp <= 0) tp = ask + InpTPPoints * _Point;
               
               //--- Find SL (below OB)
               double sl = orderBlocks[i].priceLow - 10 * _Point;
               
               //--- Check R:R
               double rr = (tp - ask) / (ask - sl);
               if(rr >= InpMinRR)
               {
                  ExecuteBuy(ask, sl, tp, "SMC_OB_Buy");
                  orderBlocks[i].isValid = false; // Mark as used
                  return;
               }
            }
         }
      }
      
      //--- Look for bullish FVG touch
      for(int i = 0; i < ArraySize(fvgs); i++)
      {
         if(!fvgs[i].isBullish || !fvgs[i].isValid)
            continue;
         
         if(bid >= fvgs[i].priceLow && bid <= fvgs[i].priceHigh)
         {
            if(IsEngulfingBullish() || IsInsideBar())
            {
               double tp = FindNearestLiquidity(true);
               if(tp <= 0) tp = ask + InpTPPoints * _Point;
               
               double sl = fvgs[i].priceLow - 10 * _Point;
               
               double rr = (tp - ask) / (ask - sl);
               if(rr >= InpMinRR)
               {
                  ExecuteBuy(ask, sl, tp, "SMC_FVG_Buy");
                  fvgs[i].isValid = false;
                  return;
               }
            }
         }
      }
   }
   
   //--- Check for SELL signal
   if(currentBias == BIAS_BEARISH)
   {
      //--- Look for bearish OB touch
      for(int i = 0; i < ArraySize(orderBlocks); i++)
      {
         if(orderBlocks[i].isBullish || !orderBlocks[i].isValid)
            continue;
         
         if(ask >= orderBlocks[i].priceLow && ask <= orderBlocks[i].priceHigh)
         {
            if(IsEngulfingBearish() || IsInsideBar())
            {
               double tp = FindNearestLiquidity(false);
               if(tp <= 0) tp = bid - InpTPPoints * _Point;
               
               double sl = orderBlocks[i].priceHigh + 10 * _Point;
               
               double rr = (bid - tp) / (sl - bid);
               if(rr >= InpMinRR)
               {
                  ExecuteSell(bid, sl, tp, "SMC_OB_Sell");
                  orderBlocks[i].isValid = false;
                  return;
               }
            }
         }
      }
      
      //--- Look for bearish FVG touch
      for(int i = 0; i < ArraySize(fvgs); i++)
      {
         if(fvgs[i].isBullish || !fvgs[i].isValid)
            continue;
         
         if(ask >= fvgs[i].priceLow && ask <= fvgs[i].priceHigh)
         {
            if(IsEngulfingBearish() || IsInsideBar())
            {
               double tp = FindNearestLiquidity(false);
               if(tp <= 0) tp = bid - InpTPPoints * _Point;
               
               double sl = fvgs[i].priceHigh + 10 * _Point;
               
               double rr = (bid - tp) / (sl - bid);
               if(rr >= InpMinRR)
               {
                  ExecuteSell(bid, sl, tp, "SMC_FVG_Sell");
                  fvgs[i].isValid = false;
                  return;
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for Bullish Engulfing                                        |
//+------------------------------------------------------------------+
bool IsEngulfingBullish()
{
   double open[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   
   if(CopyOpen(_Symbol, InpLTF, 0, 3, open) < 3) return false;
   if(CopyClose(_Symbol, InpLTF, 0, 3, close) < 3) return false;
   
   //--- Current candle is bullish
   if(close[0] <= open[0]) return false;
   
   //--- Previous candle is bearish
   if(close[1] >= open[1]) return false;
   
   //--- Current engulfs previous
   if(close[0] > open[1] && open[0] < close[1])
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for Bearish Engulfing                                        |
//+------------------------------------------------------------------+
bool IsEngulfingBearish()
{
   double open[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   
   if(CopyOpen(_Symbol, InpLTF, 0, 3, open) < 3) return false;
   if(CopyClose(_Symbol, InpLTF, 0, 3, close) < 3) return false;
   
   //--- Current candle is bearish
   if(close[0] >= open[0]) return false;
   
   //--- Previous candle is bullish
   if(close[1] <= open[1]) return false;
   
   //--- Current engulfs previous
   if(close[0] < open[1] && open[0] > close[1])
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for Inside Bar                                               |
//+------------------------------------------------------------------+
bool IsInsideBar()
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyHigh(_Symbol, InpLTF, 0, 3, high) < 3) return false;
   if(CopyLow(_Symbol, InpLTF, 0, 3, low) < 3) return false;
   
   //--- Current bar is inside previous bar
   if(high[0] < high[1] && low[0] > low[1])
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Find Nearest Liquidity Level                                       |
//+------------------------------------------------------------------+
double FindNearestLiquidity(bool isBullish)
{
   double currentPrice = isBullish ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double nearestLiq = 0;
   double minDistance = 999999;
   
   if(isBullish)
   {
      //--- Look for swing highs above
      for(int i = 0; i < ArraySize(swingHighs); i++)
      {
         if(swingHighs[i].price > currentPrice)
         {
            double distance = swingHighs[i].price - currentPrice;
            if(distance < minDistance)
            {
               minDistance = distance;
               nearestLiq = swingHighs[i].price;
            }
         }
      }
   }
   else
   {
      //--- Look for swing lows below
      for(int i = 0; i < ArraySize(swingLows); i++)
      {
         if(swingLows[i].price < currentPrice)
         {
            double distance = currentPrice - swingLows[i].price;
            if(distance < minDistance)
            {
               minDistance = distance;
               nearestLiq = swingLows[i].price;
            }
         }
      }
   }
   
   return nearestLiq;
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                  |
//+------------------------------------------------------------------+
void ExecuteBuy(double price, double sl, double tp, string comment)
{
   double lotSize = CalculateLotSize(price, sl);
   
   if(trade.Buy(lotSize, _Symbol, price, sl, tp, comment))
   {
      Print("✅ BUY executed: ", lotSize, " lots @ ", price, " SL:", sl, " TP:", tp);
   }
   else
   {
      Print("❌ BUY failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                                 |
//+------------------------------------------------------------------+
void ExecuteSell(double price, double sl, double tp, string comment)
{
   double lotSize = CalculateLotSize(price, sl);
   
   if(trade.Sell(lotSize, _Symbol, price, sl, tp, comment))
   {
      Print("✅ SELL executed: ", lotSize, " lots @ ", price, " SL:", sl, " TP:", tp);
   }
   else
   {
      Print("❌ SELL failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size based on Risk                                   |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double slPrice)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (InpRiskPercent / 100.0);
   double slDistance = MathAbs(entryPrice - slPrice);
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   double lotSize = 0.01;
   
   if(slDistance > 0 && tickSize > 0 && tickValue > 0)
   {
      lotSize = riskAmount / ((slDistance / tickSize) * tickValue);
   }
   
   //--- Normalize
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Draw All SMC Concepts                                              |
//+------------------------------------------------------------------+
void DrawAllConcepts()
{
   //--- Draw HTF Bias
   DrawHTFBias();
   
   //--- Draw Order Blocks
   if(InpDrawOB)
   {
      for(int i = 0; i < ArraySize(orderBlocks); i++)
      {
         DrawOrderBlock(orderBlocks[i], i);
      }
   }
   
   //--- Draw FVGs
   if(InpDrawFVG)
   {
      for(int i = 0; i < ArraySize(fvgs); i++)
      {
         DrawFVG(fvgs[i], i);
      }
   }
   
   //--- Draw Swing Points
   for(int i = 0; i < ArraySize(swingHighs); i++)
   {
      DrawSwingHigh(swingHighs[i], i);
   }
   
   for(int i = 0; i < ArraySize(swingLows); i++)
   {
      DrawSwingLow(swingLows[i], i);
   }
}

//+------------------------------------------------------------------+
//| Draw HTF Bias Background                                           |
//+------------------------------------------------------------------+
void DrawHTFBias()
{
   string objName = "SMC_HTF_Bias";
   
   color bgColor = (currentBias == BIAS_BULLISH) ? C'144,238,144' : 
                   (currentBias == BIAS_BEARISH) ? C'255,182,193' : clrNONE;
   
   if(bgColor == clrNONE) return;
   
   datetime timeStart = iTime(_Symbol, InpLTF, 50);
   datetime timeEnd = iTime(_Symbol, InpLTF, 0);
   
   double high = ChartGetDouble(0, CHART_PRICE_MAX);
   double low = ChartGetDouble(0, CHART_PRICE_MIN);
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, timeStart, high, timeEnd, low);
   }
   else
   {
      ObjectSetInteger(0, objName, OBJPROP_TIME, 0, timeStart);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, timeEnd);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, high);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, low);
   }
   
   ObjectSetInteger(0, objName, OBJPROP_COLOR, bgColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 0);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw Order Block                                                   |
//+------------------------------------------------------------------+
void DrawOrderBlock(OrderBlock &ob, int index)
{
   if(!ob.isValid) return;
   
   string objName = "SMC_OB_" + IntegerToString(index);
   
   color obColor = ob.isBullish ? C'0,255,0' : C'255,0,0';
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, ob.timeStart, ob.priceHigh, ob.timeEnd, ob.priceLow);
   }
   else
   {
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, ob.timeEnd);
   }
   
   ObjectSetInteger(0, objName, OBJPROP_COLOR, obColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   
   //--- Label
   string labelName = objName + "_label";
   datetime labelTime = ob.timeStart;
   double labelPrice = (ob.priceHigh + ob.priceLow) / 2;
   
   if(ObjectFind(0, labelName) < 0)
   {
      ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, labelPrice);
      ObjectSetString(0, labelName, OBJPROP_TEXT, "OB");
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, obColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
   }
}

//+------------------------------------------------------------------+
//| Draw FVG                                                           |
//+------------------------------------------------------------------+
void DrawFVG(FVG &fvg, int index)
{
   if(!fvg.isValid) return;
   
   string objName = "SMC_FVG_" + IntegerToString(index);
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, fvg.timeStart, fvg.priceHigh, fvg.timeEnd, fvg.priceLow);
   }
   else
   {
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, fvg.timeEnd);
   }
   
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   
   //--- Label
   string labelName = objName + "_label";
   datetime labelTime = fvg.timeStart;
   double labelPrice = (fvg.priceHigh + fvg.priceLow) / 2;
   
   if(ObjectFind(0, labelName) < 0)
   {
      ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, labelPrice);
      ObjectSetString(0, labelName, OBJPROP_TEXT, "FVG");
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
   }
}

//+------------------------------------------------------------------+
//| Draw Swing High                                                    |
//+------------------------------------------------------------------+
void DrawSwingHigh(SwingPoint &sp, int index)
{
   string objName = "SMC_SwingH_" + IntegerToString(index);
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_ARROW, 0, sp.time, sp.price);
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 159);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   }
}

//+------------------------------------------------------------------+
//| Draw Swing Low                                                     |
//+------------------------------------------------------------------+
void DrawSwingLow(SwingPoint &sp, int index)
{
   string objName = "SMC_SwingL_" + IntegerToString(index);
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_ARROW, 0, sp.time, sp.price);
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 159);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   }
}
//+------------------------------------------------------------------+
