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
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Broker::~Broker()
  {
  }
//+------------------------------------------------------------------+



