//+------------------------------------------------------------------+
//|                                            NewTradeIndicator.mq4 |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"
#property version   "0.33"
#property strict
#property indicator_chart_window
#include <stdlib.mqh>
#include <stderror.mqh>
#include <Broker.mqh>
#include <Assert.mqh>
#include "NTI_RunTests.mqh"

string Title="New Trade Indicator"; 
string Prefix="NTI_";
string Version="v0.33";


string TextFont="Verdana";
int FiveDig;
double AdjPoint;
int MaxInt=2147483646;
color TextColor=Goldenrod;
bool debug = true;
bool HeartBeat = true;

extern bool Testing = false;
extern int PairOffsetWithinSymbol = 0;
extern bool ScanAllTradesEveryTick = true; 
//Two times when this needs to be true - 
// a) when using a broker such as OANDA that creates a new trade/new tradeID when triggering a pending order
// b) when using the Draw Range Lines together with the SetPendingOrdersOnRanges option

Broker *broker;
int numbOpenOrders;
Position* trades[];
const int TRADESRESERVESIZE = 20;
string GVLastCheck;
string GVNumbOpenOrders;
class GlobalVariablePair
{
   string GVName;
   int   OrderId;
};
GlobalVariablePair *currentGVs[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if (Testing)
   {
     
      RunTests();
      return (INIT_FAILED);
   }
   broker = new Broker(PairOffsetWithinSymbol);
   SetupGlobalVariables();
   EventSetTimer(1);
      
//---
   return(INIT_SUCCEEDED);
  }
  //+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//| Required function even though we won't use it
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      int openOrdersThisTime = broker.GetNumberOfOrders();
      GlobalVariableSet(GVNumbOpenOrders, (double) openOrdersThisTime);
      GlobalVariableSet(GVLastCheck, (double) (int) TimeLocal());
      if (ScanAllTradesEveryTick || (openOrdersThisTime != numbOpenOrders))
      {
         Position * existingOrderId[];
         int tradeSize = ArraySize(trades);
         ArrayResize(existingOrderId, tradeSize, TRADESRESERVESIZE);
         //ArrayCopy(existingOrderId, trades,0, 0, WHOLE_ARRAY);
         for(int ix=0;ix<tradeSize;ix++)
           {
            existingOrderId[ix] = trades[ix];
           }
         for (int i = 0; i < openOrdersThisTime; i++)
         {
            broker.SelectOrderByPosition(i);
            Position * selectTrade = broker.GetPosition();
            //Does this trade already exist?
            Position * trade = FindOpenTrade(selectTrade.TicketId);
            if (trade == NULL)
               //If not, then add it.
               AddTrade(selectTrade);
            else // if it wasn't a new trade, then remove it from the copy
            {
               
               int startingSize = ArraySize(existingOrderId);
               for (int j=0; j< startingSize; j++)
               {
                  if (existingOrderId[j] != NULL &&  existingOrderId[j].TicketId == trade.TicketId)
                  {
                     existingOrderId[j] = NULL;
                     break;
                  }
               }
               delete selectTrade; // We aren't adding it to an array, so delete it to avoid memory leaks
            }
          }
          for (int j=0; j < ArraySize(existingOrderId); j++)
          {
            if(existingOrderId[j] != NULL)
            {
               Position * closedTrade = existingOrderId[j];
               string closedTradeGlobal = FindGVname(closedTrade.Symbol, closedTrade.TicketId);
               Print ("Setting Global Variable " + closedTradeGlobal + " to 0 in OnTimer");
               GlobalVariableSet(closedTradeGlobal, 0);
               RemoveClosedTrade(closedTrade);
               if (CheckPointer(closedTrade) == POINTER_DYNAMIC)
               {
                  delete(closedTrade);
               }
            }
          
          }
          
          //Update numbOpenOrders to the size of our trades array
          //which should have a record of all our open orders
          numbOpenOrders = ArraySize(trades);
        } 
  
  }
//+------------------------------------------------------------------+


void Initialize()
{
   if (ArraySize(trades) > 0)
   {
      for(int ix=0;ix<ArraySize(trades);ix++)
        {
         if(trades[ix] != NULL)
           {
            Position * oldTrade = trades[ix];
            delete oldTrade;
            trades[ix] = NULL;
           }
        }
      ArrayResize(trades, 0, TRADESRESERVESIZE);      
   }
   numbOpenOrders = 0;
}
void OnDeinit(const int reason)
{
   if (CheckPointer(broker) == POINTER_DYNAMIC)
      delete broker;
}
void SetupGlobalVariables()
{
   GVNumbOpenOrders = Prefix + "NumberOfOpenOrders";

   int numbOrders = broker.GetNumberOfOrders();
   GlobalVariableSet(GVNumbOpenOrders, (double) numbOrders);
   GVLastCheck = Prefix + "LastUpdateTime";
   
   GlobalVariableSet(GVLastCheck, (double) (int) TimeLocal());
   ZeroGlobalVariables();
}

void ZeroGlobalVariables()
{
   for(int ix=0;ix<GlobalVariablesTotal();ix++)
     {
         string gvName = GlobalVariableName(ix);
         if (StringSubstr(gvName, 0, StringLen(Prefix)) == Prefix && StringFind(gvName, "LastOrderId") != -1)
         {
            Print ("Setting Global Variable " + gvName + " to zero in ZeroGlobalVariables");
            GlobalVariableSet(gvName, 0);
         }
     }
}

string FindGVname(string symbol, int orderId)
{
   int seqNo = 1;
   while (true)
   {
      string gvName = MakeGVname(symbol, seqNo);
      if (GlobalVariableCheck(gvName))
      {
         if (GlobalVariableGet(gvName) == (double) orderId)
            return gvName;
         else
         {
            seqNo++;
            continue;
         }
      }
      else
      {
         return "";
      }
   }
   return "";
}

Position * FindOpenTrade(int ticketID)
{
   for (int ix=0; ix< ArraySize(trades); ix++)
   {
      if (trades[ix].TicketId == ticketID)
         return trades[ix];
   }
   return NULL;
}

void AddTrade(Position * newTrade)
{
   int arrayLen = ArraySize(trades);
   ArrayResize(trades, arrayLen+1, TRADESRESERVESIZE);
   trades[arrayLen] = newTrade;
   string gvName = AddGVname(newTrade.Symbol, newTrade.TicketId);
   Print ("Setting GlobalVariable " + gvName + " to " + IntegerToString(newTrade.TicketId) + " in AddTrade");
   GlobalVariableSet(gvName, (double) newTrade.TicketId);
}

string AddGVname(string symbol, int ticketId)
{
   int seqNo = 1;
   while (true)
   {
      string gvName = MakeGVname(symbol, seqNo);
      if (GlobalVariableCheck(gvName))
      {
         if (GlobalVariableGet(gvName) == 0)
         {
            Print ("Setting GlobalVariale " + gvName + " to " + IntegerToString(seqNo) + " in AddGname");
            GlobalVariableSet(gvName, (double) seqNo);
            return (gvName);
         }
         else 
         {
            if (GlobalVariableGet(gvName) == (double) ticketId)
            {
               return ""; // Global Variable already exists - don't add it.
            }
            else
               seqNo++;
         }
      }
      else
      {
         // Make a new global variable
         Print ("Setting GlobalVariable " + gvName + " to " + IntegerToString(ticketId) + " in AddGVname");
         GlobalVariableSet(gvName, (double) ticketId);
         return gvName;
      }
   }
   // Should never return from here - should always
   return "";
     
}

string MakeGVname(string symbol, int seqNo)
{
   
   string GVname = Prefix + symbol + IntegerToString(seqNo) + "LastOrderId";
   return (GVname);
}

void RemoveClosedTrade(Position *trade)
{
   int existingArraySize = ArraySize(trades);
   for (int i=0; i<existingArraySize; i++)
   {
      if(trades[i].TicketId == trade.TicketId)
      {
         
         if (i < existingArraySize)
         {
            for (int j=i; j<existingArraySize-1; j++)
            {
               trades[j] = trades[j+1];
            }
         }
         break;
      }
   }
   ArrayResize(trades, existingArraySize-1, TRADESRESERVESIZE);
}
