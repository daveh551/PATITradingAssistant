//+------------------------------------------------------------------+
//|                                         PATITradingAssistant.mq4 |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"
#property version   "0.21"
#property strict

#include <stdlib.mqh>
#include <stderror.mqh> 
#include <OrderReliable_2011.01.07.mqh>
#include <Assert.mqh>
#include <Position.mqh>
#include <Broker.mqh>
#include "PTA_Runtests.mqh"

string Title="PATI Trading Assistant"; 
string Prefix="PTA_";
string Version="v0.21";
string NTIPrefix = "NTI_";
int DFVersion = 1;


string TextFont="Verdana";
int FiveDig;
double AdjPoint;
int MaxInt=2147483646;
color TextColor=Goldenrod;
int debug = true;
#define DEBUG_EXIT  ((debug & 0x0001) == 0x0001)
#define DEBUG_GLOBAL  ((debug & 0x0002) == 0x0002)
#define DEBUG_ENTRY ((debug & 0x0004) == 0x0004)
bool HeartBeat = true;

extern bool Testing = false;
extern int PairOffsetWithinSymbol = 0;
extern int DefaultStopPips = 12;
extern string ExceptionPairs = "EURUSD/8;AUDUSD,GBPUSD,EURJPY,USDJPY,USDCAD/10";
extern bool UseNextLevelTPRule = true;
extern double MinRewardRatio = 1.5;
extern bool ShowNoEntryZone = true;
extern color NoEntryZoneColor = DarkGray;
extern double MinNoEntryPad = 15;
extern int EntryIndicator = 2;
extern bool ShowInitialStop = true;
extern bool ShowExit = true;
extern color WinningExitColor = Green;
extern color LosingExitColor = Red;
extern bool ShowTradeTrendLine = true;
extern color TradeTrendLineColor = Blue;
extern bool SendSLandTPToBroker = false;
extern bool SaveConfiguration = false;

const double GVUNINIT = -99999999;
const string LASTUPDATENAME = "NTI_LastUpdateTime";


//Copies of configuration variables
bool _testing;
int _pairOffsetWithinSymbol;
int _defaultStopPips;
string _exceptionPairs;
bool _useNextLevelTPRule;
double _minRewardRatio;
bool _showNoEntryZone;
color _noEntryZoneColor;
double _minNoEntryPad;
int _entryIndicator;
bool _showInitialStop;
bool _showExit;
color _winningExitColor;
color _losingExitColor;
bool _showTradeTrendLine;
color _tradeTrendLineColor;
bool _sendSLandTPToBroker;

bool alertedThisBar = false;
datetime time0;

int longTradeNumberForDay = 0;
int shortTradeNumberForDay =0;
datetime endOfDay;
string normalizedSymbol;
string globalLastTradeName;
string saveFileName;
string configFileName;
datetime lastUpdateTime;
int lastTradeId = 0;
int oldTradeId = 0;
bool lastTradePending = false;
double stopLoss;
double noEntryPad;
Position * lastTrade = NULL;
Broker * broker;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
     Print("---------------------------------------------------------");
   Print("-----",Title," ",Version," Initializing ",Symbol(),"-----"); 
   if(Digits==5||Digits==3)
      FiveDig = 10;
   else
      FiveDig = 1;
   AdjPoint = Point * FiveDig;
   DrawVersion(); 

   UpdateGV();
   CopyInitialConfigVariables();

   
//--- create timer
//   EventSetTimer(60);
      
//---
   if (_testing)
   {
      RunTests();
      return (INIT_FAILED);  // Keep the EA from running if just testing
   }
   Initialize();
   EventSetTimer(600);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   //EventKillTimer();
   //----
   if (reason != REASON_CHARTCHANGE && reason!= REASON_PARAMETERS && reason != REASON_RECOMPILE)
      DeleteAllObjects();
   if (CheckPointer(lastTrade) == POINTER_DYNAMIC) delete lastTrade;
   if (CheckPointer(broker) == POINTER_DYNAMIC) delete broker;
   //----
   return;
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (CheckNewBar())
   {
      alertedThisBar = false;
      if (Time[0] >= endOfDay)
      {
         UpdateGV();
         endOfDay += 24*60*60;
         CleanupEndOfDay();
      }
   }
   if (!alertedThisBar)
   {
      CheckNTI();
   }
   if (lastTradeId == 0 || lastTradePending)
   {
      if(CheckForNewTrade())
        {
         HandleNewEntry();
        }
   }
   else
   {
      if(CheckForClosedTrade())
        {
         HandleClosedTrade();
        }
   }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      HeartBeat();
  }
//+------------------------------------------------------------------+
void DeleteAllObjects()
   {
   int objs = ObjectsTotal();
   string name;
   for(int cnt=ObjectsTotal()-1;cnt>=0;cnt--)
      {
      name=ObjectName(cnt);
      if (StringFind(name,Prefix,0)>-1) 
         ObjectDelete(name);
      WindowRedraw();
      }
   } //void DeleteAllObjects()
 
void DrawVersion()
   {
   string name;
   name = StringConcatenate(Prefix,"Version");
   ObjectCreate(name,OBJ_LABEL,0,0,0);
   ObjectSetText(name,Version,8,TextFont,TextColor);
   ObjectSet(name,OBJPROP_CORNER,2);
   ObjectSet(name,OBJPROP_XDISTANCE,5);
   ObjectSet(name,OBJPROP_YDISTANCE,2);
   } //void DrawVersion()

void SetGV(string VarName,double VarVal)
   {
   string strVarName = StringConcatenate(Prefix,Symbol(),"_",VarName);

   GlobalVariableSet(strVarName,VarVal);
   if(DEBUG_GLOBAL)
      Print("###Set GV ",strVarName," Value=",VarVal);
   } //void SetGV

double GetGV(string VarName)
   {
   string strVarName = StringConcatenate(Prefix,Symbol(),"_",VarName);
   double VarVal = GVUNINIT;

   if(GlobalVariableCheck(strVarName))
      {
      VarVal = GlobalVariableGet(strVarName);
      if(DEBUG_GLOBAL)
         Print("###Get GV ",strVarName," Value=",VarVal);
      }

   return(VarVal); 
   } //double GetGV(string VarName)

void HeartBeat(int TimeFrame=PERIOD_H1)
   {
   static datetime LastHeartBeat;
   datetime CurrentTime;

   if(GlobalVariableCheck(StringConcatenate(Prefix,"HeartBeat")))
      {
      if(GlobalVariableGet(StringConcatenate(Prefix,"HeartBeat")) == 1)
         HeartBeat = true;
      else
         HeartBeat = false;
   }  //void HeartBeat(int TimeFrame=PERIOD_H1)

   if(HeartBeat)
      { 
      CurrentTime = iTime(NULL,TimeFrame,0);
      if(CurrentTime > LastHeartBeat)
         {
         Print(Version," HeartBeat ",TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES));
         LastHeartBeat = CurrentTime;
         } //if(CurrentTime > ...
      } //if(HeartBeat)

   } //HeartBeat()
  //------------------------------------------------------

void Initialize()
{
  lastUpdateTime = 0;
  double updateVar;
  if (GlobalVariableCheck(LASTUPDATENAME))
  {
    GlobalVariableGet(LASTUPDATENAME, updateVar);
    lastUpdateTime = (datetime) (int) updateVar;
  }
  broker = new Broker(_pairOffsetWithinSymbol);
  configFileName = Prefix + Symbol() + "_Configuration.txt";
  
     if (!SaveConfiguration)
      ApplyConfiguration();
   else
      SaveConfigurationFile();

  normalizedSymbol = broker.NormalizeSymbol(Symbol());
  saveFileName = Prefix + normalizedSymbol + "_SaveFile.txt";
  configFileName = Prefix + normalizedSymbol + "_Configuration.txt";
  stopLoss = CalculateStop(normalizedSymbol) * AdjPoint;
  noEntryPad = _minNoEntryPad * AdjPoint;
  globalLastTradeName = NTIPrefix + normalizedSymbol + "LastOrderId";
  Print("globalLastTradeNaem = " + globalLastTradeName);
  MqlDateTime dtStruct;
  TimeToStruct(TimeCurrent(), dtStruct);
  dtStruct.hour = 0;
  dtStruct.min = 0;
  dtStruct.sec = 0;
  endOfDay = StructToTime(dtStruct) +(24*60*60);
  longTradeNumberForDay = 0;
  shortTradeNumberForDay = 0;
  ReadOldTrades();
  lastTradeId = 0;
  CheckForNewTrade();
  

}

void CheckNTI()
{
   double updateVar;
   GlobalVariableGet(LASTUPDATENAME, updateVar);
   lastUpdateTime = (datetime) (int) updateVar;
   datetime currentTime = TimeLocal();
   int timeDifference = (int) currentTime - (int) lastUpdateTime;
   if (timeDifference > 5)
   {
      Alert("NewTradeIndicator has stopped updating");
      alertedThisBar = true;
   }
}

void CopyInitialConfigVariables()
{
   _testing=Testing;
   _pairOffsetWithinSymbol = PairOffsetWithinSymbol;
   _defaultStopPips = DefaultStopPips;
   _exceptionPairs = ExceptionPairs;
   _useNextLevelTPRule = UseNextLevelTPRule;
   _showNoEntryZone = ShowNoEntryZone;
   _noEntryZoneColor = NoEntryZoneColor;
   _minNoEntryPad = MinNoEntryPad;
   _entryIndicator = EntryIndicator;
   _showInitialStop = ShowInitialStop;
   _showExit = ShowExit;
   _winningExitColor = WinningExitColor;
   _losingExitColor = LosingExitColor;
   _showTradeTrendLine = ShowTradeTrendLine;
   _tradeTrendLineColor = TradeTrendLineColor;
   _minRewardRatio = MinRewardRatio;
   _sendSLandTPToBroker = SendSLandTPToBroker;

}

bool CheckNewBar()
{
   if(Time[0] == time0) return false;
     {
      time0 = Time[0];
      return true;
     }
   
}

void ApplyConfiguration()
{
   int fileHandle = FileOpen(configFileName, FILE_ANSI | FILE_TXT | FILE_READ);
   if (fileHandle == -1) 
   {
      int errcode = GetLastError();
      Print("Failed to open configFile. Error = " + IntegerToString(errcode));
      return;
   }
   while(!FileIsEnding(fileHandle))
     {
      string line = FileReadString(fileHandle);
      string stringParts[];
      int pos = StringSplit(line, ':', stringParts);
      if(pos > 1)
        {
         string var = stringParts[0];
         string value = StringTrimLeft( stringParts[1]);
         if (var == "NoEntryZoneColor")
         {
            _noEntryZoneColor = StringToColor(value);
         }
         else if(var == "Testing")
                {
                  _testing = (bool) StringToInteger(value);
                }
         else if(var == "PairOffsetWithinSymbo")
                {
                  _pairOffsetWithinSymbol =  StringToInteger(value);
                }
         else if(var == "DefaultStopPips")
                {
                  _defaultStopPips =  StringToInteger(value);
                }
         else if(var == "ExceptionPairs")
                {
                  _exceptionPairs = value;
                }
         else if(var == "UseNextLevelTPRule")
                {
                  _useNextLevelTPRule = (bool) StringToInteger(value);
                }
         else if(var == "MinRewardRatio")
                {
                  _minRewardRatio =  StringToDouble(value);
                }
         else if(var == "ShowNoEntryZone")
                {
                  _showNoEntryZone = (bool) StringToInteger(value);
                }
         else if(var == "MinNoEntryPad")
                {
                  _minNoEntryPad = StringToInteger(value);
                }
         else if(var == "EntryIndicator")
                {
                  _entryIndicator =  StringToInteger(value);
                }
         else if(var == "ShowInitialStop")
                {
                  _showInitialStop = (bool) StringToInteger(value);
                }
         else if(var == "ShowExit")
                {
                  _showExit = (bool) StringToInteger(value);
                }
         else if(var == "WinningExitColor")
                {
                  _winningExitColor = StringToColor(value);
                }
         else if(var == "LosingExitColor")
                {
                  _losingExitColor = StringToColor(value);
                }
         else if(var == "ShowTradeTrendLine")
                {
                  _showTradeTrendLine = (bool) StringToInteger(value);
                }
         else if(var == "TradeTrendLineColor")
                {
                  _tradeTrendLineColor = StringToColor(value);
                }
         else if(var == "SendSLandTPToBroker")
                {
                  _sendSLandTPToBroker = (bool) StringToInteger(value);
                }
        }
     }
   FileClose(fileHandle);
}

void SaveConfigurationFile()
{
   if (FileIsExist(configFileName))
   {
      FileDelete(configFileName);
   }
   int fileHandle = FileOpen(configFileName, FILE_ANSI | FILE_TXT | FILE_WRITE);
   FileWriteString(fileHandle, "Testing: " + IntegerToString((int) _testing) + "\r\n");

   FileWriteString(fileHandle, "PairOffsetWithinSymbol: " + IntegerToString(_pairOffsetWithinSymbol) + "\r\n");
   FileWriteString(fileHandle, "DefaultStopPips: " + IntegerToString(_defaultStopPips) + "\r\n");
   FileWriteString(fileHandle, "ExceptionPairs: " + _exceptionPairs +"\r\n");
   FileWriteString(fileHandle, "UseNextLevelTPRule: " + IntegerToString((int) _useNextLevelTPRule ) + "\r\n");
   FileWriteString(fileHandle, "MinRewardRatio: " + DoubleToString(_minRewardRatio, 2 ) + "\r\n");
   FileWriteString(fileHandle, "ShowNoEntryZone: " + IntegerToString((int) _showNoEntryZone ) + "\r\n");
   FileWriteString(fileHandle, "NoEntryZoneColor: " + (string) _noEntryZoneColor + "\r\n");
   FileWriteString(fileHandle, "MinNoEntryPad: " + IntegerToString(_minNoEntryPad) + "\r\n");
   FileWriteString(fileHandle, "EntryIndicator: " + IntegerToString(_entryIndicator) + "\r\n");
   FileWriteString(fileHandle, "ShowInitialStop: " + IntegerToString((int) _showInitialStop) + "\r\n");
   FileWriteString(fileHandle, "ShowExit: " + IntegerToString((int) _showExit) + "\r\n");
   FileWriteString(fileHandle, "WinningExitColor: " + (string) _winningExitColor + "\r\n");
   FileWriteString(fileHandle, "LosingExitColor: " + (string) _losingExitColor + "\r\n");
   FileWriteString(fileHandle, "ShowTradeTrendLine: " + IntegerToString((int) _showTradeTrendLine) + "\r\n");
   FileWriteString(fileHandle, "TradeTrendLineColor: " + (string) _tradeTrendLineColor+ "\r\n");
   FileWriteString(fileHandle, "SendSLandTPToBroker: " + IntegerToString((int) _sendSLandTPToBroker) + "\r\n");


   
   FileClose(fileHandle);
}

bool CheckForNewTrade()
{
   if (lastTradePending)
   {
      int orderType = broker.GetType(lastTradeId);
      if (orderType == OP_BUY || orderType == OP_SELL)
        {
            lastTradePending = false;
            return true;
        }
      return false;
   }
   lastTradeId = GetNewTradeId();
   if (lastTradeId == 0) return false;
   lastTrade = broker.GetTrade(lastTradeId);
   int orderType = lastTrade.OrderType;
   if (orderType == OP_BUY || orderType == OP_SELL) 
   {
      lastTradePending = false;
      return true;
   }
   lastTradePending = true;
   return false;
}

int GetNewTradeId()
{
   double id;
   GlobalVariableGet(globalLastTradeName, id);
   return ((int) id);
}

void HandleNewEntry(bool savedTrade = false)
{
   if (CheckPointer(lastTrade) == POINTER_DYNAMIC) delete lastTrade;
   lastTrade = broker.GetTrade(lastTradeId);
   if (!savedTrade)
   {
      Alert("New Trade Entered for " + normalizedSymbol + ". Id = " + IntegerToString(lastTradeId) +". OpenPrice = " + DoubleToStr(lastTrade.OpenPrice, 5));
      SaveTradeToFile();
   }

   string objectName = Prefix + "Entry";
   if (lastTrade.OrderType == OP_BUY)
   {
      lastTrade.StopPrice = lastTrade.OpenPrice - stopLoss;
      if (_useNextLevelTPRule)
         lastTrade.TakeProfitPrice = GetNextLevel(lastTrade.OpenPrice + _minRewardRatio*stopLoss, 1);
      objectName = objectName + "L" + IntegerToString(++longTradeNumberForDay);
   }  
   else
   {
      lastTrade.StopPrice = lastTrade.OpenPrice + stopLoss;
      if (_useNextLevelTPRule)
         lastTrade.TakeProfitPrice = GetNextLevel(lastTrade.OpenPrice-_minRewardRatio*stopLoss, -1);
      objectName = objectName + "S" + IntegerToString(++shortTradeNumberForDay);
   }
   ObjectCreate(0, objectName, OBJ_ARROW, 0, lastTrade.OrderOpened, lastTrade.OpenPrice);
   ObjectSetInteger(0, objectName, OBJPROP_ARROWCODE, _entryIndicator);
   ObjectSetInteger(0, objectName, OBJPROP_COLOR, Blue);
   if (DEBUG_ENTRY)
   {
      Print("Setting TakeProfit targe at " + DoubleToStr(lastTrade.TakeProfitPrice, Digits));
   }
   if (_showInitialStop)
   {
      StringReplace(objectName, "Entry","Stop");
      ObjectCreate(0, objectName, OBJ_ARROW, 0, lastTrade.OrderOpened, lastTrade.StopPrice);
      ObjectSetInteger(0, objectName, OBJPROP_ARROWCODE, 4);
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, Red);
   }
   if (_sendSLandTPToBroker)
   {
      broker.SetSLandTP(lastTrade);
   }    

}

bool CheckForClosedTrade()
{
    oldTradeId = lastTradeId;
   lastTradeId = GetNewTradeId();
   if(lastTradeId == 0)
   {
      return true;
   }
   return false;

}

void HandleClosedTrade(bool savedTrade = false)
{
   if(CheckPointer(lastTrade) == POINTER_INVALID)
   {
      if (!savedTrade)
         Alert("Old Trade " + IntegerToString(oldTradeId) + " closed. INVALID POINTER for lastTrade");
   }
   else
   {
      if (!savedTrade)
      {
         Alert("Old Trade " + IntegerToString(oldTradeId) + " (", + lastTrade.Symbol +") closed.");
   
         Print("Handling closed trade.  OrderType= " + IntegerToString(lastTrade.OrderType));
         broker.GetClose(lastTrade);
      }
      if (_showExit)
      {
         string objName = Prefix + "Exit";
         color arrowColor;
         if(lastTrade.OrderType == OP_BUY)
         {
            objName += "L" + IntegerToString(longTradeNumberForDay);
         }
         else
         {  
            objName += "S" + IntegerToString(shortTradeNumberForDay);
         }
      
         ObjectCreate(0, objName, OBJ_ARROW, 0, lastTrade.OrderClosed, lastTrade.ClosePrice);
         ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, _entryIndicator + 1);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowColor);
         if (_showTradeTrendLine)
         {
            
            string trendLineName = objName;
            StringReplace(trendLineName, "Exit", "Trend");
            ObjectCreate(0, trendLineName, OBJ_TREND, 0, lastTrade.OrderOpened, lastTrade.OpenPrice, lastTrade.OrderClosed, lastTrade.ClosePrice);
            ObjectSetInteger(0, trendLineName, OBJPROP_COLOR, Blue);
            ObjectSetInteger(0, trendLineName, OBJPROP_RAY, false);
            ObjectSetInteger(0, trendLineName, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, trendLineName, OBJPROP_WIDTH, 1);
         }
         if ( (lastTrade.OrderType == OP_BUY && lastTrade.ClosePrice >= lastTrade.OpenPrice) ||
            (lastTrade.OrderType == OP_SELL && lastTrade.ClosePrice <= lastTrade.OpenPrice)) // Winning trade
            {
               ObjectSetInteger(0, objName, OBJPROP_COLOR, _winningExitColor);
            }
         else //losing trade
           {
               ObjectSetInteger(0, objName, OBJPROP_COLOR, _losingExitColor);
               if (_showNoEntryZone)
               {
                  double rectHigh = NormalizeDouble(GetNextLevel(lastTrade.OpenPrice + noEntryPad,1), Digits);
                  if (DEBUG_EXIT)
                  {
                     PrintFormat("ExitZone high = %s (OpenPrice= %s, noEntryPad=%s, arg=%s", DoubleToStr(rectHigh, Digits),
                        DoubleToStr(lastTrade.OpenPrice, Digits), DoubleToStr(noEntryPad, Digits), DoubleToStr(lastTrade.OpenPrice + noEntryPad));
                  }
                  double rectLow = NormalizeDouble(GetNextLevel(lastTrade.OpenPrice - noEntryPad, -1), Digits);
                  if (DEBUG_EXIT)
                  {
                     PrintFormat("ExitZone low = %s (OpenPrice= %s, noEntryPad=%s, arg=%s", DoubleToStr(rectLow, Digits),
                        DoubleToStr(lastTrade.OpenPrice, Digits), DoubleToStr(noEntryPad, Digits), DoubleToStr(lastTrade.OpenPrice - noEntryPad));
                  }
                  string rectName = Prefix + "NoEntryZone";
                  if (ObjectFind(rectName) >= 0) ObjectDelete(rectName);  // For right now, just delete it.  We may want to extend it instead
                  ObjectCreate(0,rectName, OBJ_RECTANGLE, 0, lastTrade.OrderClosed, rectHigh, endOfDay, rectLow);
                  ObjectSetInteger(0, rectName, OBJPROP_COLOR, _noEntryZoneColor);
               }
           }
      }
      if (CheckPointer(lastTrade) == POINTER_DYNAMIC)
         delete lastTrade;
   }
   lastTrade = NULL;
   
}

int CalculateStop(string symbol)
{
   int stop = _defaultStopPips;
   int pairPosition = StringFind(_exceptionPairs, symbol, 0);
   if (pairPosition >=0)
   {
      int slashPosition = StringFind(_exceptionPairs, "/", pairPosition) + 1;
      stop = StringToInteger(StringSubstr(_exceptionPairs,slashPosition));
   }
   return stop;
}

double GetNextLevel(double currentLevel, int direction /* 1 = UP, -1 = down */)
{
   double currentBaseLevel;
   string baseString;
   double isolatedLevel;
   double nextLevel;
   if (currentLevel > 50) // Are we dealing with Yen's or other pairs?
   {
      baseString = DoubleToStr(currentLevel, 3);
      baseString = StringSubstr(baseString, 0, StringLen(baseString) - 3);
      isolatedLevel = currentLevel -  StrToDouble(baseString) ;
   }
   else
   {
      baseString  = DoubleToStr(currentLevel, 5);
      baseString = StringSubstr(baseString,0, StringLen(baseString) - 3);
      isolatedLevel = (currentLevel - StrToDouble(baseString)) * 100;
   }
   if (direction > 0)
   {
      if (isolatedLevel >= .7999)
         nextLevel = 1.00;
      else if (isolatedLevel >= .4999)
         nextLevel = .80;
      else if (isolatedLevel >= .1999)
         nextLevel = .50;
      else nextLevel = .20;   
   }
   else
   {
      if (isolatedLevel >.79999)
         nextLevel = .80;
      else if (isolatedLevel > .49999)
         nextLevel = .50;
      else if (isolatedLevel > .19999)
         nextLevel = .20;
      else nextLevel = .00;
   }
   if (currentLevel > 50)
   {
      return StrToDouble(baseString) + nextLevel;
   }
   else
      return (StrToDouble(baseString) + nextLevel/100);
      
}

void CleanupEndOfDay()
{
   if (FileIsExist(saveFileName))
      FileDelete(saveFileName);
   DeleteAllObjects();
   // Replace the version legend
   DrawVersion();
}

void SaveTradeToFile()
{
   int fileHandle = FileOpen(saveFileName, FILE_TXT | FILE_ANSI | FILE_WRITE | FILE_READ);
   if (fileHandle != -1)
   {
      FileSeek(fileHandle, 0, SEEK_END);
      ulong filePos = FileTell(fileHandle);
      if (filePos == 0)// First write to this file
      {
         FileWriteString(fileHandle,StringFormat("DataVersion: %i\r\n", DFVersion));
         FileWriteString(fileHandle, StringFormat("Server Trade Date: %s\r\n", TimeToString(TimeCurrent(), TIME_DATE)));
      }
      FileWriteString(fileHandle, StringFormat("Trade ID: %i\r\n", lastTradeId));
      FileClose(fileHandle);
   }
}

void UpdateGV()
{
   if(GlobalVariableCheck(StringConcatenate(Prefix,"debug")))
      {
      if(GlobalVariableGet(StringConcatenate(Prefix,"debug")) != 0)
         debug = GlobalVariableGet(StringConcatenate(Prefix, "debug"));
      else
         debug = 0;
      }

   if(GlobalVariableCheck(StringConcatenate(Prefix,"HeartBeat")))
      {
      if(GlobalVariableGet(StringConcatenate(Prefix,"HeartBeat")) == 1)
         HeartBeat = true;
      else
         HeartBeat = false;
      }

}

void ReadOldTrades()
{
   int fileHandle = FileOpen(saveFileName, FILE_ANSI | FILE_TXT | FILE_READ);
   if (fileHandle != -1)
   {
      string line = FileReadString(fileHandle);
      if (line == StringFormat("DataVersion: %i", DFVersion)) // versions match
      {
         line = FileReadString(fileHandle);
         StringReplace(line, "Server Trade Date: ", "");
         datetime day = StrToTime(line); 
         if (day == GetDate(TimeCurrent()))
         {
            while (!FileIsEnding(fileHandle))
            {
               line = FileReadString(fileHandle);
               StringReplace(line, "Trade ID: ", "");
               int tradeId = StrToInteger(line);
               lastTradeId = tradeId;
               HandleNewEntry(true);
               if (lastTrade.OrderClosed != 0)
               {
                  HandleClosedTrade(true);
               }
            }
         }
         
      }
      FileClose(fileHandle);
   }
}

datetime GetDate(datetime time)
{
   MqlDateTime timeStruct;
   TimeToStruct(time, timeStruct);
   timeStruct.hour = 0; timeStruct.min = 0; timeStruct.sec = 0;
   return (StructToTime(timeStruct));
}