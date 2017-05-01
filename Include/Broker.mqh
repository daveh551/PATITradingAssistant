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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Broker
  {
private:
   int startingPos;
   string symbolPrefix;
   string symbolSuffix;
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
                     SelectOrderByTicket(TicketID);
                     return (GetPosition());
                    }
                    virtual void SelectOrderByPosition(int position)
                    {
                        OrderSelect(position, SELECT_BY_POS);
                    }
                    virtual void SelectOrderByTicket(int ticketId)
                    {
                     OrderSelect(ticketId, SELECT_BY_TICKET);                        
                    }
                    virtual Position * GetPosition()
                    {
                        Position * newTrade = new Position();
                        newTrade.TicketId = OrderTicket();
                        newTrade.OrderType = OrderType();
                        newTrade.IsPending = newTrade.OrderType != OP_BUY && newTrade.OrderType != OP_SELL;
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
                     SelectOrderByTicket(ticketId);
                     return OrderType();
                    }
                    virtual void GetClose(Position * trade)
                    {
                     SelectOrderByTicket(trade.TicketId);
                     trade.ClosePrice = OrderClosePrice();
                     trade.OrderClosed = OrderCloseTime();
                    }
                    virtual void SetSLandTP(Position *trade)
                    {
                     SelectOrderByTicket(trade.TicketId);
                     if ((trade.StopPrice == OrderStopLoss()) &&
                        trade.TakeProfitPrice == OrderTakeProfit())
                     {
                        Print(trade.Symbol + ": Not sending order to broker because SL and TP already set");
                        return;
                     }
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
                        if (trade.LotSize == 0.0)
                          {
                           Alert("Trade with zero lot size cannot be entered.");
                           return;
                          }
                        OrderSendReliable(
                           symbolPrefix + trade.Symbol + symbolSuffix, 
                           trade.OrderType,
                           trade.LotSize,
                           trade.OpenPrice,
                           0,
                           0.0,
                           0.0,
                           "",
                           0);
                           
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
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Broker::~Broker()
  {
  }
//+------------------------------------------------------------------+



