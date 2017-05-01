//+------------------------------------------------------------------+
//|                                                     Position.mqh |
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
class Position
  {
private:

public:
                     Position();
                    ~Position();
                     int TicketId;
                     string Symbol;
                    datetime OrderEntered;
                    datetime OrderOpened;
                    datetime OrderClosed;
                    double OpenPrice;
                    double ClosePrice;
                    double StopPrice;
                    double TakeProfitPrice;
                    double LotSize;
                    int OrderType;                    
                    bool IsPending;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Position::Position()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Position::~Position()
  {
  }
//+------------------------------------------------------------------+
