//+------------------------------------------------------------------+
//|                                              EA_SignalBridge.mq5 |
//|                                      AI Trading System - SMC Bot |
//|                        https://github.com/Ahmedyassen77/AI-Trading-System |
//+------------------------------------------------------------------+
#property copyright "AI Trading System"
#property link      "https://github.com/Ahmedyassen77/AI-Trading-System"
#property version   "1.00"
#property strict

//--- Input Parameters
input group "=== Trading Control ==="
input bool     InpEnableTrading = true;           // Enable Trading
input double   InpFixedLots = 0.01;               // Fixed Lot Size
input bool     InpUseRiskFromFile = true;         // Use Risk from Signal File
input int      InpSlippagePoints = 3;             // Slippage (points)
input int      InpMagic = 12345;                  // Magic Number

input group "=== File Settings ==="
input ENUM_FILE_SOURCE InpSource = 0;             // File Source (0=Common, 1=Experts)
input string   InpFileOrMask = "bridge.txt";      // Signal File Name
input string   InpDrawingsFile = "drawings.json"; // Drawings File Name

input group "=== Visual Settings ==="
input bool     InpDrawSignals = true;             // Draw Entry Arrows
input bool     InpDrawLevels = true;              // Draw SL/TP Lines
input bool     InpDrawSMCConcepts = true;         // Draw SMC Concepts
input color    InpBullishColor = clrLime;         // Bullish Color
input color    InpBearishColor = clrRed;          // Bearish Color

//--- File Source Enum
enum ENUM_FILE_SOURCE
{
   MODE_COMMON_FILES = 0,   // Common Files Folder
   MODE_EXPERTS_FILES = 1   // Experts Files Folder
};

//--- Global Variables
string g_signalFilePath = "";
string g_drawingsFilePath = "";
datetime g_lastFileCheck = 0;
int g_checkIntervalSeconds = 5;

//--- Signal Structure
struct Signal
{
   datetime timestamp;
   string   symbol;
   string   action;      // BUY or SELL
   double   price;
   double   sl;
   double   tp;
   double   risk;
   string   comment;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("  EA_SignalBridge - SMC Strategy");
   Print("  AI Trading System");
   Print("========================================");
   
   //--- Set file paths based on source
   if(InpSource == MODE_COMMON_FILES)
   {
      g_signalFilePath = InpFileOrMask;
      g_drawingsFilePath = InpDrawingsFile;
      Print("File Source: Common Files");
   }
   else
   {
      g_signalFilePath = "Files\\" + InpFileOrMask;
      g_drawingsFilePath = "Files\\" + InpDrawingsFile;
      Print("File Source: Experts Files");
   }
   
   Print("Signal File: ", g_signalFilePath);
   Print("Drawings File: ", g_drawingsFilePath);
   Print("Trading: ", InpEnableTrading ? "ENABLED" : "DISABLED");
   Print("========================================");
   
   //--- Load and draw SMC concepts on init
   if(InpDrawSMCConcepts)
   {
      LoadAndDrawConcepts();
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("EA_SignalBridge stopped. Reason: ", reason);
   
   //--- Clean up objects if needed
   // ObjectsDeleteAll(0, "SMC_");
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check file periodically
   datetime currentTime = TimeCurrent();
   if(currentTime - g_lastFileCheck >= g_checkIntervalSeconds)
   {
      g_lastFileCheck = currentTime;
      
      //--- Read and process signals
      ProcessSignalFile();
      
      //--- Refresh drawings
      if(InpDrawSMCConcepts)
      {
         LoadAndDrawConcepts();
      }
   }
}

//+------------------------------------------------------------------+
//| Process Signal File                                                |
//+------------------------------------------------------------------+
void ProcessSignalFile()
{
   //--- Open file
   int fileHandle = INVALID_HANDLE;
   
   if(InpSource == MODE_COMMON_FILES)
      fileHandle = FileOpen(g_signalFilePath, FILE_READ|FILE_TXT|FILE_COMMON);
   else
      fileHandle = FileOpen(g_signalFilePath, FILE_READ|FILE_TXT);
   
   if(fileHandle == INVALID_HANDLE)
   {
      // File not found - silent (normal if not generated yet)
      return;
   }
   
   //--- Read signals
   Signal signals[];
   int signalCount = 0;
   
   while(!FileIsEnding(fileHandle))
   {
      string line = FileReadString(fileHandle);
      if(StringLen(line) < 10) continue; // Skip empty/short lines
      
      //--- Parse line: timestamp;symbol;action;price;sl;tp;risk;comment
      string parts[];
      int partCount = StringSplit(line, ';', parts);
      
      if(partCount < 8) continue; // Invalid format
      
      Signal sig;
      sig.timestamp = StringToTime(parts[0]);
      sig.symbol = parts[1];
      sig.action = parts[2];
      sig.price = StringToDouble(parts[3]);
      sig.sl = StringToDouble(parts[4]);
      sig.tp = StringToDouble(parts[5]);
      sig.risk = StringToDouble(parts[6]);
      sig.comment = parts[7];
      
      //--- Filter: only current symbol
      if(sig.symbol != _Symbol) continue;
      
      //--- Filter: not already processed
      if(IsSignalProcessed(sig)) continue;
      
      //--- Add to array
      ArrayResize(signals, signalCount + 1);
      signals[signalCount] = sig;
      signalCount++;
   }
   
   FileClose(fileHandle);
   
   //--- Process new signals
   for(int i = 0; i < signalCount; i++)
   {
      ProcessSignal(signals[i]);
   }
}

//+------------------------------------------------------------------+
//| Check if signal already processed                                  |
//+------------------------------------------------------------------+
bool IsSignalProcessed(Signal &sig)
{
   //--- Check if order exists with same timestamp in comment
   string searchComment = TimeToString(sig.timestamp, TIME_DATE|TIME_MINUTES);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      string posComment = PositionGetString(POSITION_COMMENT);
      if(StringFind(posComment, searchComment) >= 0)
         return true; // Already processed
   }
   
   //--- Check history
   HistorySelect(0, TimeCurrent());
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      
      string dealComment = HistoryDealGetString(ticket, DEAL_COMMENT);
      if(StringFind(dealComment, searchComment) >= 0)
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Process Single Signal                                              |
//+------------------------------------------------------------------+
void ProcessSignal(Signal &sig)
{
   //--- Draw signal arrow
   if(InpDrawSignals)
   {
      DrawSignalArrow(sig);
   }
   
   //--- Draw SL/TP levels
   if(InpDrawLevels)
   {
      DrawLevels(sig);
   }
   
   //--- Execute trade if enabled
   if(InpEnableTrading)
   {
      ExecuteTrade(sig);
   }
   
   //--- Log
   Print("Signal Processed: ", sig.action, " ", sig.symbol, 
         " @ ", sig.price, " SL:", sig.sl, " TP:", sig.tp,
         " [", sig.comment, "]");
}

//+------------------------------------------------------------------+
//| Execute Trade                                                      |
//+------------------------------------------------------------------+
void ExecuteTrade(Signal &sig)
{
   //--- Prepare request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = sig.symbol;
   request.magic = InpMagic;
   request.deviation = InpSlippagePoints;
   request.comment = sig.comment + " " + TimeToString(sig.timestamp, TIME_DATE|TIME_MINUTES);
   
   //--- Determine type
   if(sig.action == "BUY")
   {
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(sig.symbol, SYMBOL_ASK);
   }
   else if(sig.action == "SELL")
   {
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(sig.symbol, SYMBOL_BID);
   }
   else
   {
      Print("Invalid action: ", sig.action);
      return;
   }
   
   //--- Calculate lot size
   double lots = InpFixedLots;
   if(InpUseRiskFromFile && sig.risk > 0)
   {
      // Calculate lot from risk % and SL distance
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskAmount = balance * (sig.risk / 100.0);
      double slDistance = MathAbs(sig.price - sig.sl);
      double tickValue = SymbolInfoDouble(sig.symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(sig.symbol, SYMBOL_TRADE_TICK_SIZE);
      
      if(slDistance > 0 && tickSize > 0)
      {
         lots = riskAmount / (slDistance / tickSize * tickValue);
         
         //--- Normalize
         double minLot = SymbolInfoDouble(sig.symbol, SYMBOL_VOLUME_MIN);
         double maxLot = SymbolInfoDouble(sig.symbol, SYMBOL_VOLUME_MAX);
         double lotStep = SymbolInfoDouble(sig.symbol, SYMBOL_VOLUME_STEP);
         
         lots = MathFloor(lots / lotStep) * lotStep;
         lots = MathMax(minLot, MathMin(maxLot, lots));
      }
   }
   
   request.volume = lots;
   request.sl = sig.sl;
   request.tp = sig.tp;
   
   //--- Send order
   bool sent = OrderSend(request, result);
   
   if(sent && result.retcode == TRADE_RETCODE_DONE)
   {
      Print("✅ Trade Executed: ", sig.action, " ", lots, " lots @ ", result.price);
   }
   else
   {
      Print("❌ Trade Failed: ", result.retcode, " - ", result.comment);
   }
}

//+------------------------------------------------------------------+
//| Draw Signal Arrow                                                  |
//+------------------------------------------------------------------+
void DrawSignalArrow(Signal &sig)
{
   string objName = "SMC_Signal_" + TimeToString(sig.timestamp, TIME_DATE|TIME_MINUTES);
   
   if(ObjectFind(0, objName) >= 0)
      return; // Already drawn
   
   int arrowCode = (sig.action == "BUY") ? 233 : 234; // Up/Down arrows
   color arrowColor = (sig.action == "BUY") ? InpBullishColor : InpBearishColor;
   
   ObjectCreate(0, objName, OBJ_ARROW, 0, sig.timestamp, sig.price);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowColor);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);
   ObjectSetString(0, objName, OBJPROP_TEXT, sig.comment);
}

//+------------------------------------------------------------------+
//| Draw SL/TP Levels                                                  |
//+------------------------------------------------------------------+
void DrawLevels(Signal &sig)
{
   string slName = "SMC_SL_" + TimeToString(sig.timestamp, TIME_DATE|TIME_MINUTES);
   string tpName = "SMC_TP_" + TimeToString(sig.timestamp, TIME_DATE|TIME_MINUTES);
   
   //--- Draw SL
   if(ObjectFind(0, slName) < 0)
   {
      ObjectCreate(0, slName, OBJ_HLINE, 0, 0, sig.sl);
      ObjectSetInteger(0, slName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, slName, OBJPROP_WIDTH, 1);
      ObjectSetString(0, slName, OBJPROP_TEXT, "SL: " + DoubleToString(sig.sl, _Digits));
   }
   
   //--- Draw TP
   if(ObjectFind(0, tpName) < 0)
   {
      ObjectCreate(0, tpName, OBJ_HLINE, 0, 0, sig.tp);
      ObjectSetInteger(0, tpName, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, tpName, OBJPROP_WIDTH, 1);
      ObjectSetString(0, tpName, OBJPROP_TEXT, "TP: " + DoubleToString(sig.tp, _Digits));
   }
}

//+------------------------------------------------------------------+
//| Load and Draw SMC Concepts from JSON                               |
//+------------------------------------------------------------------+
void LoadAndDrawConcepts()
{
   //--- Open drawings file
   int fileHandle = INVALID_HANDLE;
   
   if(InpSource == MODE_COMMON_FILES)
      fileHandle = FileOpen(g_drawingsFilePath, FILE_READ|FILE_TXT|FILE_COMMON);
   else
      fileHandle = FileOpen(g_drawingsFilePath, FILE_READ|FILE_TXT);
   
   if(fileHandle == INVALID_HANDLE)
   {
      // File not found - silent
      return;
   }
   
   //--- Read entire file
   string jsonContent = "";
   while(!FileIsEnding(fileHandle))
   {
      jsonContent += FileReadString(fileHandle) + "\n";
   }
   FileClose(fileHandle);
   
   if(StringLen(jsonContent) < 10)
      return;
   
   //--- Parse JSON (simple parsing - not full JSON parser)
   // Format: {"type":"...", "time1":..., "price1":..., ...}
   
   //--- Split by objects (simple approach)
   string objects[];
   int objCount = SplitJSONObjects(jsonContent, objects);
   
   for(int i = 0; i < objCount; i++)
   {
      DrawJSONObject(objects[i]);
   }
}

//+------------------------------------------------------------------+
//| Split JSON into individual objects                                 |
//+------------------------------------------------------------------+
int SplitJSONObjects(string json, string &objects[])
{
   int count = 0;
   int start = 0;
   int braceCount = 0;
   
   for(int i = 0; i < StringLen(json); i++)
   {
      ushort ch = StringGetCharacter(json, i);
      
      if(ch == '{')
      {
         if(braceCount == 0)
            start = i;
         braceCount++;
      }
      else if(ch == '}')
      {
         braceCount--;
         if(braceCount == 0)
         {
            string obj = StringSubstr(json, start, i - start + 1);
            ArrayResize(objects, count + 1);
            objects[count] = obj;
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Draw single JSON object                                            |
//+------------------------------------------------------------------+
void DrawJSONObject(string json)
{
   //--- Extract type
   string type = GetJSONValue(json, "type");
   if(type == "") return;
   
   //--- Extract common fields
   string objName = GetJSONValue(json, "name");
   if(objName == "") objName = "SMC_" + IntegerToString(GetTickCount());
   
   //--- Check if already drawn
   if(ObjectFind(0, objName) >= 0)
      return;
   
   //--- Draw based on type
   if(type == "htf_bias_background")
   {
      DrawHTFBias(json, objName);
   }
   else if(type == "order_block")
   {
      DrawOrderBlock(json, objName);
   }
   else if(type == "fvg")
   {
      DrawFVG(json, objName);
   }
   else if(type == "liquidity_line")
   {
      DrawLiquidityLine(json, objName);
   }
   else if(type == "sweep_marker")
   {
      DrawSweepMarker(json, objName);
   }
   else if(type == "choch_arrow")
   {
      DrawCHoCHArrow(json, objName);
   }
   else if(type == "bos_line")
   {
      DrawBOSLine(json, objName);
   }
   else if(type == "swing_point")
   {
      DrawSwingPoint(json, objName);
   }
}

//+------------------------------------------------------------------+
//| Get JSON value by key (simple parser)                             |
//+------------------------------------------------------------------+
string GetJSONValue(string json, string key)
{
   string searchKey = "\"" + key + "\":";
   int pos = StringFind(json, searchKey);
   if(pos < 0) return "";
   
   pos += StringLen(searchKey);
   
   //--- Skip whitespace
   while(pos < StringLen(json) && (StringGetCharacter(json, pos) == ' ' || StringGetCharacter(json, pos) == '\t'))
      pos++;
   
   //--- Check if value is string (quoted)
   bool isString = (StringGetCharacter(json, pos) == '"');
   if(isString) pos++; // Skip opening quote
   
   //--- Extract value
   string value = "";
   ushort endChar = isString ? '"' : ',';
   
   while(pos < StringLen(json))
   {
      ushort ch = StringGetCharacter(json, pos);
      if(ch == endChar || ch == '}' || ch == ']')
         break;
      value += CharToString((char)ch);
      pos++;
   }
   
   return value;
}

//+------------------------------------------------------------------+
//| Draw HTF Bias Background                                           |
//+------------------------------------------------------------------+
void DrawHTFBias(string json, string objName)
{
   datetime time1 = StringToTime(GetJSONValue(json, "time1"));
   datetime time2 = StringToTime(GetJSONValue(json, "time2"));
   string direction = GetJSONValue(json, "direction");
   
   color bgColor = (direction == "BULLISH") ? C'144,238,144' : C'255,182,193';
   
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time1, 0, time2, 0);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, bgColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 0);
   
   //--- Set to span full chart height
   double high = ChartGetDouble(0, CHART_PRICE_MAX);
   double low = ChartGetDouble(0, CHART_PRICE_MIN);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, high);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, low);
}

//+------------------------------------------------------------------+
//| Draw Order Block                                                   |
//+------------------------------------------------------------------+
void DrawOrderBlock(string json, string objName)
{
   datetime time1 = StringToTime(GetJSONValue(json, "time1"));
   datetime time2 = StringToTime(GetJSONValue(json, "time2"));
   double price1 = StringToDouble(GetJSONValue(json, "price1"));
   double price2 = StringToDouble(GetJSONValue(json, "price2"));
   string obType = GetJSONValue(json, "ob_type");
   
   color obColor = (obType == "bullish") ? C'0,255,0' : C'255,0,0';
   
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, obColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   
   //--- Add label
   string labelName = objName + "_label";
   datetime labelTime = time1 + (time2 - time1) / 2;
   double labelPrice = (price1 + price2) / 2;
   
   ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, labelPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "OB");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, obColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Draw FVG                                                           |
//+------------------------------------------------------------------+
void DrawFVG(string json, string objName)
{
   datetime time1 = StringToTime(GetJSONValue(json, "time1"));
   datetime time2 = StringToTime(GetJSONValue(json, "time2"));
   double price1 = StringToDouble(GetJSONValue(json, "price1"));
   double price2 = StringToDouble(GetJSONValue(json, "price2"));
   
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
   
   //--- Add label
   string labelName = objName + "_label";
   datetime labelTime = time1 + (time2 - time1) / 2;
   double labelPrice = (price1 + price2) / 2;
   
   ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, labelPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
}

//+------------------------------------------------------------------+
//| Draw Liquidity Line                                                |
//+------------------------------------------------------------------+
void DrawLiquidityLine(string json, string objName)
{
   datetime time1 = StringToTime(GetJSONValue(json, "time1"));
   datetime time2 = StringToTime(GetJSONValue(json, "time2"));
   double price = StringToDouble(GetJSONValue(json, "price1"));
   string liqType = GetJSONValue(json, "liq_type");
   
   color lineColor = (liqType == "high") ? clrOrange : clrBlue;
   
   ObjectCreate(0, objName, OBJ_TREND, 0, time1, price, time2, price);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
   
   //--- Add label
   string labelName = objName + "_label";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, time1, price);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "LIQ");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
}

//+------------------------------------------------------------------+
//| Draw Sweep Marker                                                 |
//+------------------------------------------------------------------+
void DrawSweepMarker(string json, string objName)
{
   datetime time = StringToTime(GetJSONValue(json, "time1"));
   double price = StringToDouble(GetJSONValue(json, "price1"));
   string sweepType = GetJSONValue(json, "sweep_type");
   
   int arrowCode = (sweepType == "high") ? 234 : 233;
   
   ObjectCreate(0, objName, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrPurple);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   
   //--- Add label
   string labelName = objName + "_label";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "SWEEP");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrPurple);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
}

//+------------------------------------------------------------------+
//| Draw CHoCH Arrow                                                   |
//+------------------------------------------------------------------+
void DrawCHoCHArrow(string json, string objName)
{
   datetime time = StringToTime(GetJSONValue(json, "time1"));
   double price = StringToDouble(GetJSONValue(json, "price1"));
   string direction = GetJSONValue(json, "direction");
   
   int arrowCode = (direction == "bullish") ? 233 : 234;
   
   ObjectCreate(0, objName, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrAqua);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);
   
   //--- Add label
   string labelName = objName + "_label";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "CHoCH");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrAqua);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
}

//+------------------------------------------------------------------+
//| Draw BOS Line                                                      |
//+------------------------------------------------------------------+
void DrawBOSLine(string json, string objName)
{
   datetime time1 = StringToTime(GetJSONValue(json, "time1"));
   datetime time2 = StringToTime(GetJSONValue(json, "time2"));
   double price = StringToDouble(GetJSONValue(json, "price1"));
   
   ObjectCreate(0, objName, OBJ_TREND, 0, time1, price, time2, price);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMagenta);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   
   //--- Add label
   string labelName = objName + "_label";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, time1, price);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "BOS");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrMagenta);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Draw Swing Point                                                   |
//+------------------------------------------------------------------+
void DrawSwingPoint(string json, string objName)
{
   datetime time = StringToTime(GetJSONValue(json, "time1"));
   double price = StringToDouble(GetJSONValue(json, "price1"));
   string swingType = GetJSONValue(json, "swing_type");
   
   int arrowCode = (swingType == "high") ? 159 : 159;
   color dotColor = (swingType == "high") ? clrRed : clrBlue;
   
   ObjectCreate(0, objName, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, dotColor);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
}

//+------------------------------------------------------------------+
