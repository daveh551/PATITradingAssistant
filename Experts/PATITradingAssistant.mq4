//+------------------------------------------------------------------+
//|                                         PATITradingAssistant.mq4 |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"
#property version   "0.33"
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
string Version="v0.33";
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
#define DEBUG_CONFIG ((debug & 0x0008) == 0x0008)
bool HeartBeat = true;

extern bool Testing = false;
extern int PairOffsetWithinSymbol = 0;
extern int DefaultStopPips = 12;
extern string ExceptionPairs = "EURUSD/8;AUDUSD,GBPUSD,EURJPY,USDJPY,USDCAD/10";
extern bool UseNextLevelTPRule = true;
extern bool ShowNoEntryZone = true;
extern bool ShowEntry = true;
extern bool ShowInitialStop = true;
extern bool ShowExit = true;
extern bool ShowTradeTrendLine = true;
extern bool SendSLandTPToBroker = true;
extern bool AlertOnTrade=true;
extern double MinNoEntryPad = 15;
extern int EntryIndicator = 2;
extern double MinRewardRatio = 1.5;
extern color NoEntryZoneColor = DarkGray;
extern color WinningExitColor = Green;
extern color LosingExitColor = Red;
extern color TradeTrendLineColor = Blue;
extern bool SaveConfiguration = false;
extern int EndOfDayOffsetHours = 0;
extern bool SetLimitsOnPendingOrders = true;
extern bool AdjustStopOnTriggeredPendingOrders = true;

const double GVUNINIT = -99999999;
const string LASTUPDATENAME = "NTI_LastUpdateTime";
string GVPrefix;

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
bool _showEntry;
bool _alertOnTrade;
int _endOfDayOffsetHours;
bool _setLimitsOnPendingOrders;
bool _adjustStopOnTriggeredPendingOrders;

bool alertedThisBar = false;
datetime time0;

int longTradeNumberForDay = 0;
int shortTradeNumberForDay =0;
datetime endOfDay;
string normalizedSymbol;
string saveFileName;
string configFileName;
string globalConfigFileName;
datetime lastUpdateTime;
int lastTradeId = 0;
bool lastTradePending = false;
double stopLoss;
double noEntryPad;
Position * activeTrade = NULL;
Broker * broker;
int totalActiveTrades;
Position * activeTrades[];
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
   InitializeActiveTradeArray();

   
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
   if (CheckPointer(activeTrade) == POINTER_DYNAMIC) delete activeTrade;
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
   if (!_testing)
   { 
      if ( CheckNewBar())
      {
         alertedThisBar = false;
         UpdateGV();
         if (Time[0] >= endOfDay)
         {
           endOfDay += 24*60*60;
           CleanupEndOfDay();
         }
      }
      if (!alertedThisBar)
      {
         CheckNTI();
      }
   }
   CheckForClosedTrades();
   CheckForPendingTradesGoneActive();
   CheckForNewTrades();
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      HeartBeat();
  }
  
  string MakeGVname( int sequence)
  {
   return GVPrefix + IntegerToString(sequence) + "LastOrderId";
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
  GVPrefix = NTIPrefix + broker.NormalizeSymbol(Symbol());
  configFileName = Prefix + Symbol() + "_Configuration.txt";
  globalConfigFileName = Prefix + "_Configuration.txt";
  
     if (!SaveConfiguration)
      ApplyConfiguration();
   else
      SaveConfigurationFile();

  PrintConfigValues();
  normalizedSymbol = broker.NormalizeSymbol(Symbol());
  saveFileName = Prefix + normalizedSymbol + "_SaveFile.txt";
  stopLoss = CalculateStop(normalizedSymbol) * AdjPoint;
  noEntryPad = _minNoEntryPad * AdjPoint;
  MqlDateTime dtStruct;
  TimeToStruct(TimeCurrent(), dtStruct);
  dtStruct.hour = 0;
  dtStruct.min = 0;
  dtStruct.sec = 0;
  endOfDay = StructToTime(dtStruct) +(24*60*60) + (_endOfDayOffsetHours * 60 * 60);
  longTradeNumberForDay = 0;
  shortTradeNumberForDay = 0;
  if (CheckSaveFileValid())
   ReadOldTrades();
  else
   DeleteSaveFile();
  lastTradeId = 0;
 
  

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
   _showEntry = ShowEntry;
   _alertOnTrade = AlertOnTrade;
   _endOfDayOffsetHours = EndOfDayOffsetHours;
   _setLimitsOnPendingOrders = SetLimitsOnPendingOrders;
   _adjustStopOnTriggeredPendingOrders = AdjustStopOnTriggeredPendingOrders;

}

bool CheckNewBar()
{
   if(Time[0] == time0) return false;
   time0 = Time[0];
   return true;
   
}

void ApplyConfiguration()
{
   ApplyConfiguration(globalConfigFileName);
   ApplyConfiguration(configFileName);
}

void ApplyConfiguration(string fileName)
{
   if (!FileIsExist(fileName)) return;
   int fileHandle = FileOpen(fileName, FILE_ANSI | FILE_TXT | FILE_READ);
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
         else if(var == "ShowEntry")
                {
                  _showEntry = (bool) StringToInteger(value);
                }
         else if(var == "AlertOnTrade")
                {
                  _alertOnTrade = (bool) StringToInteger(value);
                }
         else if (var == "EndOfDayOffsetHours")
               {
                  _endOfDayOffsetHours = StringToInteger(value);
               }
         else if (var == "SetLimitsOnPendingOrder")
               {
                  _setLimitsOnPendingOrders = (bool) StringToInteger(value);
               }
         else if (var == "AdjustStopOnTriggeredPendingOrders")
               {
                  _adjustStopOnTriggeredPendingOrders = (bool) StringToInteger(value);
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
   FileWriteString(fileHandle, "ShowEntry: " + IntegerToString((int) _showEntry) + "\r\n");
   FileWriteString(fileHandle, "AlertOnTrade: " + IntegerToString((int) _alertOnTrade) + "\r\n");
   FileWriteString(fileHandle, "EndOfDayOffsetHours: " + IntegerToString(_endOfDayOffsetHours) + "\r\n");
   FileWriteString(fileHandle, "SetLimitsOnPendingOrders: " + IntegerToString((int) _setLimitsOnPendingOrders) + "\r\n");
   FileWriteString(fileHandle, "AdjustStopOnTriggeredPendingOrders: " + IntegerToString((int) _adjustStopOnTriggeredPendingOrders) + "\r\n");


   
   FileClose(fileHandle);
}

void PrintConfigValues()
{
   if (!DEBUG_CONFIG) return;
   Print( "PairOffsetWithinSymbol: " + IntegerToString(_pairOffsetWithinSymbol) + "\r\n");
   Print( "DefaultStopPips: " + IntegerToString(_defaultStopPips) + "\r\n");
   Print( "ExceptionPairs: " + _exceptionPairs +"\r\n");
   Print( "UseNextLevelTPRule: " + IntegerToString((int) _useNextLevelTPRule ) + "\r\n");
   Print( "MinRewardRatio: " + DoubleToString(_minRewardRatio, 2 ) + "\r\n");
   Print( "ShowNoEntryZone: " + IntegerToString((int) _showNoEntryZone ) + "\r\n");
   Print( "NoEntryZoneColor: " + (string) _noEntryZoneColor + "\r\n");
   Print( "MinNoEntryPad: " + IntegerToString(_minNoEntryPad) + "\r\n");
   Print( "EntryIndicator: " + IntegerToString(_entryIndicator) + "\r\n");
   Print( "ShowInitialStop: " + IntegerToString((int) _showInitialStop) + "\r\n");
   Print( "ShowExit: " + IntegerToString((int) _showExit) + "\r\n");
   Print( "WinningExitColor: " + (string) _winningExitColor + "\r\n");
   Print( "LosingExitColor: " + (string) _losingExitColor + "\r\n");
   Print( "ShowTradeTrendLine: " + IntegerToString((int) _showTradeTrendLine) + "\r\n");
   Print( "TradeTrendLineColor: " + (string) _tradeTrendLineColor+ "\r\n");
   Print( "SendSLandTPToBroker: " + IntegerToString((int) _sendSLandTPToBroker) + "\r\n");
   Print( "ShowEntry: " + IntegerToString((int) _showEntry) + "\r\n");
   Print( "AlertOnTrade: " + IntegerToString((int) _alertOnTrade) + "\r\n");
   Print( "EndOfDayOffsetHours: " + IntegerToString(_endOfDayOffsetHours) + "\r\n");
   Print("SetLimitsOnPendingOrders: " + IntegerToString((int) _setLimitsOnPendingOrders) + "\r\n");
   Print("AdjustStopOnTriggeredPendingOrders: " + IntegerToString((int) _adjustStopOnTriggeredPendingOrders) + "\r\n");
}

   void CheckForClosedTrades()
   {
      int currentlyActiveTradeIds[];
      bool foundAClosedTrade = false;
      int maxSeqNo = 0;
      int maxActiveTrade = 0;
      int seqNo = 1;
      ArrayResize(currentlyActiveTradeIds, 0, 10);
      int tradeId;
      while (true)
      {
         //We're going to (maybe) cycle through the global variables twice
         // - once to build a list of those that remain
         // - and the second time to find those that have been deleted.
         // If none of the GV's are 0, then we can skip this whole thing
         
         string gvName = GVPrefix + IntegerToString(seqNo) + "LastOrderId";
         if (!GlobalVariableCheck(gvName)) break;
         tradeId = (int) GlobalVariableGet(gvName);
         if (tradeId == 0)
         {
            foundAClosedTrade = true;
         }
         else
         {
            maxSeqNo = seqNo;
            ArrayResize(currentlyActiveTradeIds, ++maxActiveTrade, 10);
            currentlyActiveTradeIds[maxActiveTrade - 1] = tradeId;
         }
         seqNo++;
      }
      if (foundAClosedTrade) 
      {
           //Now any Ids that are in activeTrades not in currentlyActiveTrades are deleted
           for(int ix=totalActiveTrades-1;ix >= 0;ix--)
           {
               bool foundThisTrade = false;
              tradeId = activeTrades[ix].TicketId;
              for(int jx=0;jx<maxActiveTrade;jx++)
                {
                  if (currentlyActiveTradeIds[jx] == tradeId)
                  {
                     foundThisTrade = true;
                     break;
                  }
                }
              if (!foundThisTrade)
              {
                  activeTrade = activeTrades[ix];
                  if (!activeTrade.IsPending)
                     HandleClosedTrade();
                  else
                     HandleDeletedTrade();
              }
           }           
      }
   }
   
   void CheckForPendingTradesGoneActive()
   {
      int seqNo = 1;
      while (true)
      {
         string gvName = GVPrefix + IntegerToString(seqNo) + "LastOrderId";
         if (!GlobalVariableCheck(gvName)) break;
         int tradeId = (int) GlobalVariableGet(gvName);
         if (tradeId != 0)
         {
            for(int ix=0;ix<totalActiveTrades;ix++)
              {
                  if (activeTrades[ix] !=NULL &&activeTrades[ix].TicketId == tradeId)
                  {
                     if (activeTrades[ix].IsPending)
                     {
                        int orderType = broker.GetType(tradeId);
                        if (orderType == OP_BUY || orderType == OP_SELL) //then no longer pending.
                        {
                           if (CheckPointer(activeTrades[ix]) == POINTER_DYNAMIC) delete activeTrades[ix];
                           activeTrades[ix] = broker.GetTrade(tradeId);
                           activeTrade = activeTrades[ix];
                           HandlePendingTradeGoneActive();
                        }
                     }
                     break;
                  }
              }
           }
         seqNo++;
      }

   }
   
   void CheckForNewTrades()
   {
      int seqNo = 1;
      while (true)
      {
         string gvName = GVPrefix + IntegerToString(seqNo) + "LastOrderId";
         if (!GlobalVariableCheck(gvName)) break;
         int tradeId = (int) GlobalVariableGet(gvName);
         if(CheckForNewTrade(tradeId))
           {
              HandleNewEntry(tradeId);
           }
         seqNo++;
      }
   }

bool CheckForNewTrade(int tradeId)
{
   if (tradeId == 0) return false;
   if (ArraySize(activeTrades)== 0) return true;
   for(int ix=0;ix<ArraySize(activeTrades);ix++)
     {
      if(activeTrades[ix]  != NULL && activeTrades[ix].TicketId== tradeId) return false;
     }
   return true;
}

void HandleNewEntry( int tradeId, bool savedTrade = false)
{
   // don't want to delete activeTrade anymore since it's only a copy of the main pointer
   //if (CheckPointer(activeTrade) == POINTER_DYNAMIC) delete activeTrade;
   totalActiveTrades++;
   if (totalActiveTrades > ArraySize(activeTrades))
      ArrayResize(activeTrades, totalActiveTrades, 10);
   activeTrades[totalActiveTrades-1] = broker.GetTrade(tradeId);
   activeTrade = activeTrades[totalActiveTrades -1];
   lastTradeId = tradeId;
   lastTradePending = activeTrade.IsPending;
   if (activeTrade.IsPending && !savedTrade)
   {
      if (DEBUG_ENTRY)
      {
         Print("New Pending order found: Symbol: " + activeTrade.Symbol + 
            " OpenPrice: " + DoubleToStr(activeTrade.OpenPrice, 5) + 
            " TakeProfit: " + DoubleToStr(activeTrade.TakeProfitPrice, 5));
      }
      if(_setLimitsOnPendingOrders)
         SetStopAndProfitLevels(activeTrade, false);
      return;
   }
   HandleTradeEntry(false, savedTrade);
}

void HandlePendingTradeGoneActive()
{
   HandleTradeEntry(true);
}
void HandleTradeEntry(bool wasPending, bool savedTrade = false)
{
      if(!savedTrade &&  !activeTrade.IsPending)
        {
         if (_alertOnTrade)
            Alert("New Trade Entered for " + normalizedSymbol + ". Id = " + IntegerToString(activeTrade.TicketId) +". OpenPrice = " + DoubleToStr(activeTrade.OpenPrice, 5));
         SaveTradeToFile(activeTrade);
        }
   string objectName = Prefix + "Entry";
   if (!savedTrade) SetStopAndProfitLevels(activeTrade, wasPending);
   if (activeTrade.OrderType == OP_BUY)
   {
      objectName = objectName + "L" + IntegerToString(++longTradeNumberForDay);
   }  
   else
   {
      objectName = objectName + "S" + IntegerToString(++shortTradeNumberForDay);
   }
   if (_showEntry)
   {
   ObjectCreate(0, objectName, OBJ_ARROW, 0, activeTrade.OrderOpened, activeTrade.OpenPrice);
   ObjectSetInteger(0, objectName, OBJPROP_ARROWCODE, _entryIndicator);
   ObjectSetInteger(0, objectName, OBJPROP_COLOR, Blue);
   }
   if (DEBUG_ENTRY)
   {
      Print("Setting TakeProfit target at " + DoubleToStr(activeTrade.TakeProfitPrice, Digits));
   }
   if (_showInitialStop)
   {
      StringReplace(objectName, "Entry","Stop");
      ObjectCreate(0, objectName, OBJ_ARROW, 0, activeTrade.OrderOpened, activeTrade.StopPrice);
      ObjectSetInteger(0, objectName, OBJPROP_ARROWCODE, 4);
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, Red);
   }
}

void SetStopAndProfitLevels(Position * trade, bool wasPending)
{
      
      if //(trade.OrderType == OP_BUY || trade.OrderType == OP_BUYLIMIT || trade.OrderType == OP_BUYSTOP))
         ((trade.OrderType & 0x0001) == 0)  // All BUY order types are even
      {
         if (trade.StopPrice == 0 || (wasPending && _adjustStopOnTriggeredPendingOrders)) trade.StopPrice = trade.OpenPrice - stopLoss;
         if (DEBUG_ENTRY)
         {
            Print ("Setting stoploss for BUY order (" + IntegerToString(trade.OrderType) +") StopLoss= " + DoubleToStr(trade.StopPrice, 5) + "(OpenPrice = " + DoubleToStr(trade.OpenPrice, 5) + ", stopLoss = " + DoubleToStr(stopLoss, 8));
         }
         if (_useNextLevelTPRule)
            if (trade.TakeProfitPrice == 0 || (wasPending && _adjustStopOnTriggeredPendingOrders)) trade.TakeProfitPrice = GetNextLevel(trade.OpenPrice + _minRewardRatio*stopLoss, 1);
      }
      else //SELL type
      {
         if (trade.StopPrice ==0 ||(wasPending && _adjustStopOnTriggeredPendingOrders ) )trade.StopPrice = trade.OpenPrice + stopLoss;
         if (DEBUG_ENTRY)
         {
            Print ("Setting stoploss for SELL order (" + IntegerToString(trade.OrderType) + ") StopLoss= " + DoubleToStr(trade.StopPrice, 5) + "(OpenPrice = " + DoubleToStr(trade.OpenPrice, 5) + ", stopLoss = " + DoubleToStr(stopLoss, 8));
         }
         
         if (_useNextLevelTPRule)
            if (trade.TakeProfitPrice == 0 || (wasPending && _adjustStopOnTriggeredPendingOrders)) trade.TakeProfitPrice = GetNextLevel(trade.OpenPrice-_minRewardRatio*stopLoss, -1);
      }
      if (_sendSLandTPToBroker && !_testing)
      {
         if (DEBUG_ENTRY)
         {
            Print("Sending to broker: TradeType=" + IntegerToString(trade.OrderType) + 
               " OpenPrice=" + DoubleToString(trade.OpenPrice,Digits) + 
               " StopPrice=" + DoubleToString(trade.StopPrice, Digits) +
               " TakeProfit=" + DoubleToString(trade.TakeProfitPrice, Digits)
               );
         }
         broker.SetSLandTP(trade);
      }    

}
void HandleClosedTrade(bool savedTrade = false)
{
   if(CheckPointer(activeTrade) == POINTER_INVALID)
   {
      if (!savedTrade)
      {
         if(_alertOnTrade)
           {
               Alert("Old Trade "  + " closed. INVALID POINTER for activeTrade");      
           }
      }
   }
   else
   {
      if (!savedTrade)
      {
         broker.GetClose(activeTrade);
         double profit = activeTrade.ClosePrice - activeTrade.OpenPrice;
         if (activeTrade.OrderType == OP_SELL) profit = profit * -1;
         profit = NormalizeDouble(profit, Digits)/Point; 
         if (FiveDig) profit *= .1;
         if(_alertOnTrade)
           {
               Alert("Old Trade " + IntegerToString(activeTrade.TicketId) + " (", + activeTrade.Symbol +") closed. (" + DoubleToStr(profit, 1) + ")");            
           }
   
         Print("Handling closed trade.  OrderType= " + IntegerToString(activeTrade.OrderType));
         if (activeTrade.OrderClosed == 0) return;
      }
      if (_showExit)
      {
         string objName = Prefix + "Exit";
         color arrowColor;
         if(activeTrade.OrderType == OP_BUY)
         {
            objName += "L" + IntegerToString(longTradeNumberForDay);
         }
         else
         {  
            objName += "S" + IntegerToString(shortTradeNumberForDay);
         }
      
         ObjectCreate(0, objName, OBJ_ARROW, 0, activeTrade.OrderClosed, activeTrade.ClosePrice);
         ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, _entryIndicator + 1);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowColor);
         if (_showTradeTrendLine)
         {
            
            string trendLineName = objName;
            StringReplace(trendLineName, "Exit", "Trend");
            ObjectCreate(0, trendLineName, OBJ_TREND, 0, activeTrade.OrderOpened, activeTrade.OpenPrice, activeTrade.OrderClosed, activeTrade.ClosePrice);
            ObjectSetInteger(0, trendLineName, OBJPROP_COLOR, Blue);
            ObjectSetInteger(0, trendLineName, OBJPROP_RAY, false);
            ObjectSetInteger(0, trendLineName, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, trendLineName, OBJPROP_WIDTH, 1);
         }
         if ( (activeTrade.OrderType == OP_BUY && activeTrade.ClosePrice >= activeTrade.OpenPrice) ||
            (activeTrade.OrderType == OP_SELL && activeTrade.ClosePrice <= activeTrade.OpenPrice)) // Winning trade
            {
               ObjectSetInteger(0, objName, OBJPROP_COLOR, _winningExitColor);
            }
         else //losing trade
           {
               ObjectSetInteger(0, objName, OBJPROP_COLOR, _losingExitColor);
               if (_showNoEntryZone)
               {
                  datetime rectStart = activeTrade.OrderClosed;
                  if (rectStart == 0) return;
                  double rectHigh = NormalizeDouble(GetNextLevel(activeTrade.OpenPrice + noEntryPad,1), Digits);
                  if (DEBUG_EXIT)
                  {
                     PrintFormat("ExitZone high = %s (OpenPrice= %s, noEntryPad=%s, arg=%s", DoubleToStr(rectHigh, Digits),
                        DoubleToStr(activeTrade.OpenPrice, Digits), DoubleToStr(noEntryPad, Digits), DoubleToStr(activeTrade.OpenPrice + noEntryPad));
                  }
                  double rectLow = NormalizeDouble(GetNextLevel(activeTrade.OpenPrice - noEntryPad, -1), Digits);
                  if (DEBUG_EXIT)
                  {
                     PrintFormat("ExitZone low = %s (OpenPrice= %s, noEntryPad=%s, arg=%s", DoubleToStr(rectLow, Digits),
                        DoubleToStr(activeTrade.OpenPrice, Digits), DoubleToStr(noEntryPad, Digits), DoubleToStr(activeTrade.OpenPrice - noEntryPad));
                  }
                  string rectName = Prefix + "NoEntryZone";
                  if (ObjectFind(rectName) >= 0) 
                  {
                     double existingHigh = ObjectGetDouble(0, rectName, OBJPROP_PRICE1);
                     if (DEBUG_EXIT)
                     {
                        PrintFormat("Existing ExitZone rectangle high = %s", DoubleToString(existingHigh, Digits));
                     }
                     if(existingHigh > rectHigh)
                       {
                         rectHigh = existingHigh;
                       }
                     double existingLow = ObjectGetDouble(0, rectName, OBJPROP_PRICE2);
                      if (DEBUG_EXIT)
                     {
                        PrintFormat("Existing ExitZone rectangle low = %s", DoubleToString(existingLow, Digits));
                     }
                     if (existingLow < rectLow)
                     {
                        if (DEBUG_EXIT)
                           PrintFormat("Existing log (%s) substituted for new Low(%S)", DoubleToStr(existingLow,Digits), DoubleToStr(rectLow, Digits));
                        rectLow = existingLow;
                     }
                     datetime existingStart = ObjectGetInteger(0, rectName, OBJPROP_TIME1);
                     if (existingStart < rectStart)
                     {
                        rectStart = existingStart;
                     }
                  }
                  ObjectDelete(0, rectName); // Just in case it already exists.
                  ObjectCreate(0,rectName, OBJ_RECTANGLE, 0, rectStart, rectHigh, endOfDay, rectLow);
                  ObjectSetInteger(0, rectName, OBJPROP_COLOR, _noEntryZoneColor);
               }
           }
      }
      HandleDeletedTrade();
   }
   activeTrade = NULL;
   
}
void HandleDeletedTrade()
{
         for(int ix=0;ix<totalActiveTrades;ix++)
        {
         if (activeTrades[ix].TicketId == activeTrade.TicketId)
         {
            if (CheckPointer(activeTrades[ix]) == POINTER_DYNAMIC)
               delete activeTrades[ix];
            for(int jx=ix;jx<totalActiveTrades-1;jx++)
              {
               activeTrades[jx] = activeTrades[jx+1];
              }
            activeTrades[totalActiveTrades-1] = NULL;
            totalActiveTrades--;
         }
        }
      if (CheckPointer(activeTrade) == POINTER_DYNAMIC)
         delete activeTrade;
      activeTrade = NULL;

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

bool CheckSaveFileValid()
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
         FileClose(fileHandle);
         if (day == GetDate(TimeCurrent())) return true;
         else return false;
      }
   }
   return false;
}
void CleanupEndOfDay()
{
   DeleteSaveFile();
   DeleteAllObjects();
   // Replace the version legend
   DrawVersion();
}

void DeleteSaveFile()
{
   if (FileIsExist(saveFileName))
      FileDelete(saveFileName);
}
void SaveTradeToFile(Position *trade)
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
      FileWriteString(fileHandle, StringFormat("Trade ID: %i\r\n", trade.TicketId));
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
               HandleNewEntry(tradeId,true);
               if (activeTrade.OrderClosed != 0)
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
void InitializeActiveTradeArray()
{
   ArrayResize(activeTrades, 0, 10);
   totalActiveTrades = 0;  
}