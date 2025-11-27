//+------------------------------------------------------------------+
//|                                            EA_SMC_FULL_FIX1.mq5 |
//|                         Smart Money Concepts - FIXED VERSION 1    |
//+------------------------------------------------------------------+
#property copyright "SMC Trading System"
#property version   "1.01"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== استراتيجية SMC ==="
input int InpHTFPeriod = 240;                    // HTF Period (minutes): 240=H4, 60=H1
input int InpMTFPeriod = 15;                     // MTF Period (minutes): 15=M15
input int InpLTFPeriod = 5;                      // LTF Period (minutes): 5=M5

input group "=== Risk Management ==="
input double InpRiskPercent = 1.0;               // Risk % من الرصيد
input double InpMinRR = 1.5;                     // أقل Risk:Reward (قللناه!)
input int    InpSLPoints = 150;                  // Stop Loss (points) احتياطي
input int    InpTPPoints = 300;                  // Take Profit (points) احتياطي

input group "=== Swing Detection ==="
input int    InpSwingLookback = 3;               // Swing Lookback Bars
input double InpSweepThreshold = 50;             // Sweep Threshold (points) - خفضناه!

input group "=== Session Filter ==="
input bool   InpUseAsianFilter = false;          // تجاهل OB من الجلسة الآسيوية (عطلناه!)
input int    InpAsianStart = 23;                 // Asian Session Start (UTC)
input int    InpAsianEnd = 7;                    // Asian Session End (UTC)

input group "=== Order Block Settings ==="
input int    InpOBLookback = 20;                 // OB Max Lookback Bars (زودناه!)
input double InpOBMinMove = 5;                   // OB Min Move (pips) - جديد!
input bool   InpDrawOB = true;                   // رسم Order Blocks

input group "=== FVG Settings ==="
input double InpFVGMinPips = 3;                  // FVG Min Size (pips) - قللناه!
input bool   InpDrawFVG = true;                  // رسم FVG

input group "=== Trading Control ==="
input int    InpMagicNumber = 88888;             // Magic Number
input int    InpSlippage = 3;                    // Slippage
input bool   InpEnableTrading = true;            // Enable Trading
input bool   InpDebugMode = true;                // Debug Mode (طباعة تفاصيل)

//--- Global Variables
CTrade trade;
datetime lastBarTime = 0;
int biasCheckCount = 0;
int obDetectedCount = 0;
int fvgDetectedCount = 0;
int signalCheckCount = 0;

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
   Print("  EA SMC - FIXED VERSION 1");
   Print("  HTF Period: ", InpHTFPeriod, " min");
   Print("  MTF Period: ", InpMTFPeriod, " min");
   Print("  LTF Period: ", InpLTFPeriod, " min");
   Print("  Risk: ", InpRiskPercent, "%");
   Print("  Min R:R: ", InpMinRR, " (reduced!)");
   Print("  Asian Filter: ", InpUseAsianFilter ? "ON" : "OFF");
   Print("  Debug Mode: ", InpDebugMode ? "ON" : "OFF");
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
   
   Print("========================================");
   Print("  EA SMC - Final Statistics");
   Print("  Bias Checks: ", biasCheckCount);
   Print("  OBs Detected: ", obDetectedCount);
   Print("  FVGs Detected: ", fvgDetectedCount);
   Print("  Signal Checks: ", signalCheckCount);
   Print("========================================");
   
   Print("EA SMC stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check for new bar on LTF
   datetime currentBarTime = iTime(_Symbol, InpLTFPeriod, 0);
   if(currentBarTime == lastBarTime)
      return;
   
   lastBarTime = currentBarTime;
   
   if(InpDebugMode)
      Print("=== New Bar: ", TimeToString(currentBarTime), " ===");
   
   //--- Update SMC Analysis
   UpdateHTFBias();
   UpdateSwingPoints();
   UpdateOrderBlocks();
   UpdateFVGs();
   
   //--- Print statistics every 100 bars
   if(signalCheckCount % 100 == 0 && InpDebugMode)
   {
      Print("--- Statistics after ", signalCheckCount, " bars ---");
      Print("Current Bias: ", EnumToString(currentBias));
      Print("Swing Highs: ", ArraySize(swingHighs));
      Print("Swing Lows: ", ArraySize(swingLows));
      Print("Active OBs: ", ArraySize(orderBlocks));
      Print("Active FVGs: ", ArraySize(fvgs));
   }
   
   //--- Check for Entry Signals
   if(InpEnableTrading)
   {
      CheckForEntry();
   }
   
   //--- Draw Concepts
   DrawAllConcepts();
   
   signalCheckCount++;
}

//+------------------------------------------------------------------+
//| Update HTF Bias (Fixed version)                                   |
//+------------------------------------------------------------------+
void UpdateHTFBias()
{
   biasCheckCount++;
   
   //--- Get HTF data using integer period
   double htfHigh[], htfLow[], htfClose[];
   ArraySetAsSeries(htfHigh, true);
   ArraySetAsSeries(htfLow, true);
   ArraySetAsSeries(htfClose, true);
   
   int htfBars = 50;
   
   if(CopyHigh(_Symbol, InpHTFPeriod, 0, htfBars, htfHigh) < htfBars) 
   {
      if(InpDebugMode && biasCheckCount % 100 == 1)
         Print("Warning: Cannot copy HTF High data");
      return;
   }
   
   if(CopyLow(_Symbol, InpHTFPeriod, 0, htfBars, htfLow) < htfBars)
   {
      if(InpDebugMode && biasCheckCount % 100 == 1)
         Print("Warning: Cannot copy HTF Low data");
      return;
   }
   
   if(CopyClose(_Symbol, InpHTFPeriod, 0, htfBars, htfClose) < htfBars)
   {
      if(InpDebugMode && biasCheckCount % 100 == 1)
         Print("Warning: Cannot copy HTF Close data");
      return;
   }
   
   //--- Simple trend detection
   double sma20 = 0;
   for(int i = 0; i < 20; i++)
   {
      sma20 += htfClose[i];
   }
   sma20 /= 20;
   
   double sma50 = 0;
   for(int i = 0; i < 50; i++)
   {
      sma50 += htfClose[i];
   }
   sma50 /= 50;
   
   //--- Determine bias
   ENUM_BIAS oldBias = currentBias;
   
   if(htfClose[0] > sma20 && sma20 > sma50)
   {
      currentBias = BIAS_BULLISH;
   }
   else if(htfClose[0] < sma20 && sma20 < sma50)
   {
      currentBias = BIAS_BEARISH;
   }
   else
   {
      currentBias = BIAS_NEUTRAL;
   }
   
   if(oldBias != currentBias && InpDebugMode)
   {
      Print(">>> HTF Bias Changed: ", EnumToString(oldBias), " -> ", EnumToString(currentBias));
   }
}

//+------------------------------------------------------------------+
//| Update Swing Points (same but with debug)                         |
//+------------------------------------------------------------------+
void UpdateSwingPoints()
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   int bars = 50;
   if(CopyHigh(_Symbol, InpLTFPeriod, 0, bars, high) < bars) return;
   if(CopyLow(_Symbol, InpLTFPeriod, 0, bars, low) < bars) return;
   
   int oldSwingHighs = ArraySize(swingHighs);
   int oldSwingLows = ArraySize(swingLows);
   
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
         sp.time = iTime(_Symbol, InpLTFPeriod, i);
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
         sp.time = iTime(_Symbol, InpLTFPeriod, i);
         sp.price = low[i];
         sp.isHigh = false;
         
         int size = ArraySize(swingLows);
         ArrayResize(swingLows, size + 1);
         swingLows[size] = sp;
      }
   }
   
   if(InpDebugMode && (ArraySize(swingHighs) != oldSwingHighs || ArraySize(swingLows) != oldSwingLows))
   {
      Print("Swing Points Updated: Highs=", ArraySize(swingHighs), " Lows=", ArraySize(swingLows));
   }
}

//+------------------------------------------------------------------+
//| Update Order Blocks (improved detection)                          |
//+------------------------------------------------------------------+
void UpdateOrderBlocks()
{
   int oldCount = ArraySize(orderBlocks);
   ArrayResize(orderBlocks, 0);
   
   double open[], high[], low[], close[];
   datetime time[];
   
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   
   int bars = InpOBLookback + 10;
   if(CopyOpen(_Symbol, InpLTFPeriod, 0, bars, open) < bars) return;
   if(CopyHigh(_Symbol, InpLTFPeriod, 0, bars, high) < bars) return;
   if(CopyLow(_Symbol, InpLTFPeriod, 0, bars, low) < bars) return;
   if(CopyClose(_Symbol, InpLTFPeriod, 0, bars, close) < bars) return;
   if(CopyTime(_Symbol, InpLTFPeriod, 0, bars, time) < bars) return;
   
   double minMove = InpOBMinMove * _Point * 10;
   
   //--- Find bullish OB
   for(int i = 2; i < InpOBLookback; i++)
   {
      //--- Check for strong bullish move
      double moveSize = close[i-1] - low[i];
      if(close[i-1] > close[i] && moveSize > minMove)
      {
         //--- Current candle could be OB
         if(close[i] < open[i] || true) // Accept any candle
         {
            //--- Asian session filter
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
            ob.isBullish = true;
            ob.isValid = true;
            
            int size = ArraySize(orderBlocks);
            ArrayResize(orderBlocks, size + 1);
            orderBlocks[size] = ob;
            obDetectedCount++;
            
            if(InpDebugMode)
               Print("Bullish OB detected at ", DoubleToString(ob.priceLow, _Digits));
         }
      }
      
      //--- Check for strong bearish move
      double bearMoveSize = high[i] - close[i-1];
      if(close[i-1] < close[i] && bearMoveSize > minMove)
      {
         if(close[i] > open[i] || true)
         {
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
            obDetectedCount++;
            
            if(InpDebugMode)
               Print("Bearish OB detected at ", DoubleToString(ob.priceHigh, _Digits));
         }
      }
   }
   
   if(InpDebugMode && ArraySize(orderBlocks) != oldCount)
   {
      Print("Order Blocks: ", ArraySize(orderBlocks), " active");
   }
}

//+------------------------------------------------------------------+
//| Update FVGs (same as before)                                      |
//+------------------------------------------------------------------+
void UpdateFVGs()
{
   int oldCount = ArraySize(fvgs);
   ArrayResize(fvgs, 0);
   
   double high[], low[];
   datetime time[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   
   int bars = 50;
   if(CopyHigh(_Symbol, InpLTFPeriod, 0, bars, high) < bars) return;
   if(CopyLow(_Symbol, InpLTFPeriod, 0, bars, low) < bars) return;
   if(CopyTime(_Symbol, InpLTFPeriod, 0, bars, time) < bars) return;
   
   double minGap = InpFVGMinPips * _Point * 10;
   
   for(int i = 2; i < bars - 1; i++)
   {
      //--- Bullish FVG
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
            fvgDetectedCount++;
         }
      }
      
      //--- Bearish FVG
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
            fvgDetectedCount++;
         }
      }
   }
   
   if(InpDebugMode && ArraySize(fvgs) != oldCount)
   {
      Print("FVGs: ", ArraySize(fvgs), " active");
   }
}

//+------------------------------------------------------------------+
//| Check for Entry (with more debug)                                 |
//+------------------------------------------------------------------+
void CheckForEntry()
{
   if(PositionSelect(_Symbol))
   {
      if(InpDebugMode && signalCheckCount % 200 == 0)
         Print("Already in position, skipping entry check");
      return;
   }
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   //--- Check BUY
   if(currentBias == BIAS_BULLISH || currentBias == BIAS_NEUTRAL)
   {
      for(int i = 0; i < ArraySize(orderBlocks); i++)
      {
         if(!orderBlocks[i].isBullish || !orderBlocks[i].isValid)
            continue;
         
         if(bid >= orderBlocks[i].priceLow && bid <= orderBlocks[i].priceHigh)
         {
            if(InpDebugMode)
               Print(">>> Price in Bullish OB! Checking confirmation...");
            
            if(IsEngulfingBullish() || IsInsideBar() || true) // Accept any entry for testing
            {
               double tp = FindNearestLiquidity(true);
               if(tp <= 0) tp = ask + InpTPPoints * _Point;
               
               double sl = orderBlocks[i].priceLow - 10 * _Point;
               
               double rr = (tp - ask) / (ask - sl);
               
               if(InpDebugMode)
                  Print("BUY Signal: TP=", tp, " SL=", sl, " R:R=", rr);
               
               if(rr >= InpMinRR)
               {
                  ExecuteBuy(ask, sl, tp, "SMC_OB_Buy");
                  orderBlocks[i].isValid = false;
                  return;
               }
               else if(InpDebugMode)
               {
                  Print("Rejected: R:R too low (", rr, " < ", InpMinRR, ")");
               }
            }
         }
      }
      
      //--- Check FVG
      for(int i = 0; i < ArraySize(fvgs); i++)
      {
         if(!fvgs[i].isBullish || !fvgs[i].isValid)
            continue;
         
         if(bid >= fvgs[i].priceLow && bid <= fvgs[i].priceHigh)
         {
            if(InpDebugMode)
               Print(">>> Price in Bullish FVG! Checking confirmation...");
            
            if(IsEngulfingBullish() || IsInsideBar() || true)
            {
               double tp = FindNearestLiquidity(true);
               if(tp <= 0) tp = ask + InpTPPoints * _Point;
               
               double sl = fvgs[i].priceLow - 10 * _Point;
               
               double rr = (tp - ask) / (ask - sl);
               
               if(InpDebugMode)
                  Print("BUY Signal from FVG: TP=", tp, " SL=", sl, " R:R=", rr);
               
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
   
   //--- Check SELL
   if(currentBias == BIAS_BEARISH || currentBias == BIAS_NEUTRAL)
   {
      for(int i = 0; i < ArraySize(orderBlocks); i++)
      {
         if(orderBlocks[i].isBullish || !orderBlocks[i].isValid)
            continue;
         
         if(ask >= orderBlocks[i].priceLow && ask <= orderBlocks[i].priceHigh)
         {
            if(InpDebugMode)
               Print(">>> Price in Bearish OB! Checking confirmation...");
            
            if(IsEngulfingBearish() || IsInsideBar() || true)
            {
               double tp = FindNearestLiquidity(false);
               if(tp <= 0) tp = bid - InpTPPoints * _Point;
               
               double sl = orderBlocks[i].priceHigh + 10 * _Point;
               
               double rr = (bid - tp) / (sl - bid);
               
               if(InpDebugMode)
                  Print("SELL Signal: TP=", tp, " SL=", sl, " R:R=", rr);
               
               if(rr >= InpMinRR)
               {
                  ExecuteSell(bid, sl, tp, "SMC_OB_Sell");
                  orderBlocks[i].isValid = false;
                  return;
               }
            }
         }
      }
      
      //--- Check FVG
      for(int i = 0; i < ArraySize(fvgs); i++)
      {
         if(fvgs[i].isBullish || !fvgs[i].isValid)
            continue;
         
         if(ask >= fvgs[i].priceLow && ask <= fvgs[i].priceHigh)
         {
            if(InpDebugMode)
               Print(">>> Price in Bearish FVG! Checking confirmation...");
            
            if(IsEngulfingBearish() || IsInsideBar() || true)
            {
               double tp = FindNearestLiquidity(false);
               if(tp <= 0) tp = bid - InpTPPoints * _Point;
               
               double sl = fvgs[i].priceHigh + 10 * _Point;
               
               double rr = (bid - tp) / (sl - bid);
               
               if(InpDebugMode)
                  Print("SELL Signal from FVG: TP=", tp, " SL=", sl, " R:R=", rr);
               
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

//--- Rest of the functions (same as original)
bool IsEngulfingBullish()
{
   double open[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   
   if(CopyOpen(_Symbol, InpLTFPeriod, 0, 3, open) < 3) return false;
   if(CopyClose(_Symbol, InpLTFPeriod, 0, 3, close) < 3) return false;
   
   if(close[0] <= open[0]) return false;
   if(close[1] >= open[1]) return false;
   if(close[0] > open[1] && open[0] < close[1])
      return true;
   
   return false;
}

bool IsEngulfingBearish()
{
   double open[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   
   if(CopyOpen(_Symbol, InpLTFPeriod, 0, 3, open) < 3) return false;
   if(CopyClose(_Symbol, InpLTFPeriod, 0, 3, close) < 3) return false;
   
   if(close[0] >= open[0]) return false;
   if(close[1] <= open[1]) return false;
   if(close[0] < open[1] && open[0] > close[1])
      return true;
   
   return false;
}

bool IsInsideBar()
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyHigh(_Symbol, InpLTFPeriod, 0, 3, high) < 3) return false;
   if(CopyLow(_Symbol, InpLTFPeriod, 0, 3, low) < 3) return false;
   
   if(high[0] < high[1] && low[0] > low[1])
      return true;
   
   return false;
}

double FindNearestLiquidity(bool isBullish)
{
   double currentPrice = isBullish ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double nearestLiq = 0;
   double minDistance = 999999;
   
   if(isBullish)
   {
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
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

void DrawAllConcepts()
{
   DrawHTFBias();
   
   if(InpDrawOB)
   {
      for(int i = 0; i < ArraySize(orderBlocks); i++)
      {
         DrawOrderBlock(orderBlocks[i], i);
      }
   }
   
   if(InpDrawFVG)
   {
      for(int i = 0; i < ArraySize(fvgs); i++)
      {
         DrawFVG(fvgs[i], i);
      }
   }
   
   for(int i = 0; i < ArraySize(swingHighs); i++)
   {
      DrawSwingHigh(swingHighs[i], i);
   }
   
   for(int i = 0; i < ArraySize(swingLows); i++)
   {
      DrawSwingLow(swingLows[i], i);
   }
}

void DrawHTFBias()
{
   string objName = "SMC_HTF_Bias";
   
   color bgColor = (currentBias == BIAS_BULLISH) ? C'144,238,144' : 
                   (currentBias == BIAS_BEARISH) ? C'255,182,193' : clrNONE;
   
   if(bgColor == clrNONE) return;
   
   datetime timeStart = iTime(_Symbol, InpLTFPeriod, 50);
   datetime timeEnd = iTime(_Symbol, InpLTFPeriod, 0);
   
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
