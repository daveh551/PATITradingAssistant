//+------------------------------------------------------------------+
//|                                             GenericStartCode.mq4 |
//|                                                        Tim Black |
//|                                    http://winnersedgetrading.com |
//+------------------------------------------------------------------+
#property copyright "Tim Black"
#property copyright "
#property link "http://winnersedgetrading.com"
#property copyright "Copyright © 2012, T Black & Associates"

#include <stdlib.mqh>
#include <stderror.mqh> 
#include <OrderReliable_2011.01.07.mqh>
#include <PcntTradeSize.mqh>

string Title="GenericStartCode"; 
string Prefix="GSC_";
string Version="v0.10";
datetime ExpireDate=D'2041.11.30 00:01';

extern double RiskPcnt=1.0;
extern int MagicNumber=1111234;

string TextFont="Verdana";
int FiveDig;
int MaxInt=2147483646;
int LotDigits;
bool MarginAlert=false;
double AdjPoint;
static datetime LastTradeTime=0;
color TextColor=Goldenrod;
bool debug = true;
bool HeartBeat = true;

//+------------------------------------------------------------------+
//| expert initialization function |
//+------------------------------------------------------------------+
int init()
   {
   //----
   Print("---------------------------------------------------------");
   Print("-----",Title," ",Version," Initializing ",Symbol(),"-----"); 
   if(Digits==5||Digits==3)
      FiveDig = 10;
   else
      FiveDig = 1;
   AdjPoint = Point * FiveDig;
   DrawVersion(); 

   if(MarketInfo(Symbol(),MODE_LOTSTEP) < 0.1)
      LotDigits = 2;
   else if(MarketInfo(Symbol(),MODE_LOTSTEP) < 1.0)
      LotDigits = 1;
   else
      LotDigits = 0;

   if(GlobalVariableCheck(StringConcatenate(Prefix,"debug")))
      {
      if(GlobalVariableGet(StringConcatenate(Prefix,"debug")) == 1)
         debug = true;
      else
         debug = false;
      }

   if(GlobalVariableCheck(StringConcatenate(Prefix,"HeartBeat")))
      {
      if(GlobalVariableGet(StringConcatenate(Prefix,"HeartBeat")) == 1)
         HeartBeat = true;
      else
         HeartBeat = false;
      }
  //---------------------------------------------------- 

  //----
  return(0);
  }  //int init()

//+------------------------------------------------------------------+
//| expert deinitialization function |
//+------------------------------------------------------------------+
int deinit()
   {
   //----
   DeleteAllObjects();

   //----
   return(0);
   }  //int deinit()

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
   if(debug)
      Print("###Set GV ",strVarName," Value=",VarVal);
   } //void SetGV

double GetGV(string VarName)
   {
   string strVarName = StringConcatenate(Prefix,Symbol(),"_",VarName);
   double VarVal = -99999999;

   if(GlobalVariableCheck(strVarName))
      {
      VarVal = GlobalVariableGet(strVarName);
      if(debug)
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
         Print(Version," HeartBeat ",TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES));
         LastHeartBeat = CurrentTime;
         } //if(CurrentTime > ...
      } //if(HeartBeat)

   } //HeartBeat()
  //------------------------------------------------------
 
//+------------------------------------------------------------------+
//| expert start function |
//+------------------------------------------------------------------+
int start()
   {
  //----
   if(HeartBeat)
      HeartBeat();
  //----
   return(0);
   }  //int start()
//+------------------------------------------------------------------+