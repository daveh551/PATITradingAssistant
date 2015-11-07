//+------------------------------------------------------------------+
//|                                                   FakeBroker.mqh |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class FakeBroker : public Broker
  {
private:
         int cntGetNumberOfOrders;
         int cntGetPosition;
         
         int selectedPosition;
public:
                     FakeBroker();
                    ~FakeBroker();
                    int TotalOrdersToReturn;
                    Position *OrdersToReturn[];
                    int OrderIndex[];
                    virtual int GetNumberOfOrders()
                    {
                        cntGetNumberOfOrders++;
                        return (TotalOrdersToReturn);
                    }
                    
                    void ResetVerifications()
                    {
                        cntGetNumberOfOrders = 0;
                        cntGetPosition = 0;
                    }
                    bool VerifyGetNumberOfOrdersCalled()
                    {
                        return (cntGetNumberOfOrders > 0);
                    }
                    bool VerifyGetPositionCalled()
                    {
                        return (cntGetPosition > 0);
                    }
                    virtual void SelectOrderByPosition(int pos)
                    {
                        selectedPosition = pos;
                    }
                    virtual void SelectOrderByTicket(int ticketId)
                    {
                     for(int ix=0;ix<ArraySize(OrderIndex);ix++)
                       {
                        if(OrdersToReturn[OrderIndex[ix]].TicketId == ticketId)
                        {
                           selectedPosition = ix;
                           return;
                        }
                       }
                    }
                    
                    virtual int GetType(int ticketId)
                    {
                     SelectOrderByTicket(ticketId);
                     return OrdersToReturn[OrderIndex[selectedPosition]].OrderType;
                    }
                    virtual Position *GetPosition()
                    {
                        cntGetPosition++;
                        Position * selectedTrade = OrdersToReturn[OrderIndex[selectedPosition]];
                        Position * newTrade = new Position();
                        newTrade.Symbol = selectedTrade.Symbol;
                        newTrade.TicketId = selectedTrade.TicketId;
                        newTrade.OrderEntered = selectedTrade.OrderEntered;
                        newTrade.OrderOpened = selectedTrade.OrderOpened;
                        newTrade.OrderClosed = selectedTrade.OrderClosed;
                        newTrade.OpenPrice = selectedTrade.OpenPrice;
                        newTrade.ClosePrice = selectedTrade.ClosePrice;
                        newTrade.OrderType = selectedTrade.OrderType;
                        newTrade.IsPending = (selectedTrade.OrderType != OP_BUY && selectedTrade.OrderType != OP_SELL);
                        return newTrade;
                    }
                    virtual void GetClose(Position * trade)
                    {
                        SelectOrderByTicket(trade.TicketId);
                        Position * selectedTrade = OrdersToReturn[OrderIndex[selectedPosition]];
                        trade.ClosePrice = selectedTrade.ClosePrice;
                        trade.OrderClosed = selectedTrade.OrderClosed;
                    }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FakeBroker::FakeBroker()
  {
   TypeName = "FakeBroker";
   int ix = 0;
   ArrayResize(OrdersToReturn,5,5);
      Position* order = new Position();
   order.TicketId = 12345;
   order.Symbol = "EURUSD";

   OrdersToReturn[ix++] = order;
   
   //Change so first two orders returned are both EURUSD
   
   order = new Position();
   order.TicketId = 98765;
   order.Symbol = "EURUSD";
   OrdersToReturn[ix++] = order;
   
   order = new Position();
   order.TicketId = 23456;
   order.Symbol = "GBPUSD";
   OrdersToReturn[ix++] = order;

   order = new Position();
   order.TicketId = 34567;
   order.Symbol = "GBPJPY";
   OrdersToReturn[ix++] = order;

   order = new Position();
   order.TicketId = 45678;
   order.Symbol = "GBPAUD";
   OrdersToReturn[ix++] = order;
   
   ArrayResize(OrderIndex, 5, 5);
   for(int i=0;i<ArraySize(OrderIndex);i++)
     {
      OrderIndex[i] = i;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FakeBroker::~FakeBroker()
  {
   for(int ix=0;ix<ArraySize(OrdersToReturn);ix++)
     {
      if (CheckPointer(OrdersToReturn[ix]) == POINTER_DYNAMIC)
         delete OrdersToReturn[ix];
     }
  }
//+------------------------------------------------------------------+

