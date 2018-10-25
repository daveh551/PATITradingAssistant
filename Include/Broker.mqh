//+------------------------------------------------------------------+
//|                                                       Broker.mqh |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"
#property version   "1.00"
#property strict
#include <Position.mqh>
#include <OrderReliable_2011.01.07.mqh>
const int MAXSELECTRETRIES = 3;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Broker
  {
private:
   int startingPos;
   string symbolPrefix;
   string symbolSuffix;
   Position * NullTrade;
public:
                     Broker(int symbolOffset = 0);
                     
                    ~Broker();
                    string TypeName;
                    virtual int GetNumberOfOrders()
                    {
                     return OrdersTotal();
                    }
                    virtual Position*  GetTrade(int TicketID)
                    {
                     if (SelectOrderByTicket(TicketID)) return (GetPosition());
                     else return new Position(NullTrade);
                    }
                    virtual void SelectOrderByPosition(int position)
                    {
                        OrderSelect(position, SELECT_BY_POS);
                    }
                    virtual bool SelectOrderByTicket(int ticketId)
                    {
                      //return OrderSelect(ticketId, SELECT_BY_TICKET);  
                        int retryCnt;

                     for(retryCnt=0;retryCnt<MAXSELECTRETRIES;retryCnt++)
                       {
                           if(OrderSelect(ticketId, SELECT_BY_TICKET))
                              break;
                           PrintFormat("Attempt #%i to select order %i failed. Error code = %i", retryCnt, ticketId, GetLastError());
                           Sleep(100*(retryCnt+1));  //let's give it a little breather before hitting it again.
                       }
                     if (retryCnt >= MAXSELECTRETRIES)
                     {
                        Alert("Attempt to select order " + IntegerToString(ticketId) + " failed after " + IntegerToString(MAXSELECTRETRIES));
                        return false;
                     }
                     return true;
                    }
                    virtual Position * GetPosition()
                    {
                        Position * newTrade = new Position();
                        newTrade.TicketId = OrderTicket();
                        newTrade.OrderType = OrderType();
                        //newTrade.IsPending = newTrade.OrderType != OP_BUY && newTrade.OrderType != OP_SELL;
                        newTrade.IsPending = (newTrade.OrderType > OP_SELL);
                        newTrade.Symbol = NormalizeSymbol(OrderSymbol());
                        newTrade.OrderOpened = OrderOpenTime();
                        newTrade.OpenPrice = OrderOpenPrice();
                        newTrade.ClosePrice = OrderClosePrice();
                        newTrade.OrderClosed = OrderCloseTime();
                        newTrade.StopPrice = OrderStopLoss();
                        newTrade.TakeProfitPrice = OrderTakeProfit();
                        newTrade.LotSize = OrderLots();
                        return newTrade;
                    }
                    virtual int GetType(int ticketId)
                    {
                     if (SelectOrderByTicket(ticketId)) return OrderType();
                     else return -1;
                    }
                    virtual void GetClose(Position * trade)
                    {
                     if (SelectOrderByTicket(trade.TicketId))
                     {
                        trade.ClosePrice = OrderClosePrice();
                        trade.OrderClosed = OrderCloseTime();
                     }
                     else
                     {
                        trade.ClosePrice = 0.0;
                        trade.OrderClosed = 0;
                     }
                    }
                    virtual void SetSLandTP(Position *trade)
                    {
                     PrintFormat("Entered broker.SetSLandTP(%i)", trade.TicketId);
                     PrintFormat("%s price=%f, stop=%f, TP=%f", trade.Symbol, trade.OpenPrice, trade.StopPrice, trade.TakeProfitPrice);
                     SelectOrderByTicket(trade.TicketId);
                     if ((trade.StopPrice == OrderStopLoss()) &&
                        trade.TakeProfitPrice == OrderTakeProfit())
                     {
                        Print(trade.Symbol + ": Not sending order to broker because SL and TP already set");
                        return;
                     }
                     PrintFormat("Calling OrderModifyReliable()");
                     if (!OrderModifyReliable(trade.TicketId,
                        trade.OpenPrice,
                        trade.StopPrice,
                        trade.TakeProfitPrice,
                        0 ))
                        {
                           Alert("Setting SL and TP for " + trade.Symbol + " failed.");
                        }
                    }
                    
                    virtual void CreateOrder (Position * trade)
                    {
                        int tradeId;
                        if (trade.LotSize == 0.0)
                          {
                           Alert("Trade with zero lot size cannot be entered.");
                           return;
                          }
                        tradeId = OrderSendReliable(
                           symbolPrefix + trade.Symbol + symbolSuffix, 
                           trade.OrderType,
                           trade.LotSize,
                           trade.OpenPrice,
                           0,
                           0.0,
                           0.0,
                           "",
                           0);
                         if (tradeId != -1) trade.TicketId = tradeId;
                    }
                    
                    virtual void DeletePendingTrade ( Position * trade)
                    {
                        if(trade.OrderType < 2) // then not a pending order
                          {
                           Alert("Attempt to delete an open trade. Close order instead of Deleting it.");
                           return;
                          }
                        OrderDelete(trade.TicketId);
                    }
                    
                    virtual void CloseTrade(int ticketId)
                    {
                        SelectOrderByTicket(ticketId);
                        OrderCloseReliable(ticketId, OrderLots(), (OrderType() == OP_BUY)?Bid:Ask, 0);
                    }
                    virtual Position * FindLastTrade() 
                    {
                        for(int ix=OrdersHistoryTotal()-1;ix>=0;ix--)
                          {
                              OrderSelect(ix, SELECT_BY_POS, MODE_HISTORY); 
                              if(OrderSymbol() == Symbol()) return GetPosition();
                               
                          }
                          return NULL;
                    }
            
 string NormalizeSymbol(string symbol)
{
   return (StringSubstr(symbol, startingPos, 6));
}

};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Broker::Broker(int symbolOffset = 0)
  {
   TypeName = "RealBroker";
   startingPos = symbolOffset;
   string symbol = Symbol();
   if (symbolOffset == 0)
      symbolPrefix = "";
   else
      symbolPrefix = StringSubstr(symbol, 0, symbolOffset);
   symbolSuffix = StringSubstr(symbol,6+symbolOffset);
   NullTrade = new Position();
                        NullTrade.TicketId = -1;
                        NullTrade.OrderType = 999;
                        NullTrade.IsPending = false;
                        NullTrade.Symbol = NormalizeSymbol(Symbol());
                        NullTrade.OrderOpened = 0;
                        NullTrade.OpenPrice = 0.0;
                        NullTrade.ClosePrice = 0.0;
                        NullTrade.OrderClosed = 0;
                        NullTrade.StopPrice = 0.0;
                        NullTrade.TakeProfitPrice = 0.0;
                        NullTrade.LotSize = 0.0;     
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Broker::~Broker()
  {
   delete NullTrade;
  }
//+------------------------------------------------------------------+



