//+------------------------------------------------------------------+
//|                                            NewTradeIndicator.mq4 |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#include <Broker.mqh>
#include <Assert.mqh>
#include "NTI_RunTests.mqh"

string Title="New Trade Indicator"; 
string Prefix="NTI_";
string Version="v0.10";


string TextFont="Verdana";
int FiveDig;
double AdjPoint;
int MaxInt=2147483646;
color TextColor=Goldenrod;
bool debug = true;
bool HeartBeat = true;

extern bool Testing = true;

Broker *broker;
int numbOpenOrders;
Position* trades[];
const int TRADESRESERVESIZE = 20;
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
   broker = new Broker();
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
      if (openOrdersThisTime != numbOpenOrders)
      {
         Position * existingOrderId[];
         ArrayCopy(existingOrderId, trades);
         for (int i = 0; i < openOrdersThisTime; i++)
         {
            broker.SelectOrder(i);
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
                  if (existingOrderId[j].TicketId == trade.TicketId)
                  {
                     existingOrderId[j] = NULL;
                     ArrayResize(existingOrderId, startingSize - 1, TRADESRESERVESIZE);
                     break;
                  }
               }
            }
          }
          for (int j=0; j < ArraySize(existingOrderId); j++)
          {
            if(existingOrderId[j] != NULL)
            {
               Position * closedTrade = existingOrderId[j];
               string closedTradeGlobal = MakeGVname(closedTrade.Symbol);
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
            trades[ix] = NULL;
           }
        }
      ArrayResize(trades, 0, TRADESRESERVESIZE);      
   }
   numbOpenOrders = 0;
}
void SetupGlobalVariables()
{
   string GVNumbOpenOrders = Prefix + "NumberOfOpenOrders";

   int numbOrders = broker.GetNumberOfOrders();
   GlobalVariableSet(GVNumbOpenOrders, (double) numbOrders);
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
   string gvName = MakeGVname(newTrade.Symbol);
   GlobalVariableSet(gvName, (double) newTrade.TicketId);
}

string MakeGVname(string symbol)
{
   string GVname = Prefix + symbol + "LastOrderId";
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
      }
      break;
   }
   ArrayResize(trades, existingArraySize-1, TRADESRESERVESIZE);
}