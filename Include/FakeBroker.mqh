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
                    virtual void SelectOrder(int pos)
                    {
                        selectedPosition = pos;
                    }
                    virtual Position *GetPosition()
                    {
                        cntGetPosition++;
                        Position * selectedTrade = OrdersToReturn[selectedPosition];
                       
                        return selectedTrade;
                    }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FakeBroker::FakeBroker()
  {
   TypeName = "FakeBroker";
   ArrayResize(OrdersToReturn,1,5);
      Position* order = new Position();
   order.TicketId = 12345;
   order.Symbol = "EURUSD";

   OrdersToReturn[0] = order;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FakeBroker::~FakeBroker()
  {
  }
//+------------------------------------------------------------------+

