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
                    Position(const Position & source);
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
Position::Position(const Position  &source)
{
   
   ClosePrice = source.ClosePrice;
   IsPending = source.IsPending;
   LotSize = source.LotSize;
   OpenPrice = source.OpenPrice;
   OrderClosed = source.OrderClosed;
   OrderEntered = source.OrderEntered;
   OrderOpened = source.OrderOpened;
   OrderType = source.OrderType;
   StopPrice = source.StopPrice;
   Symbol = source.Symbol;
   TakeProfitPrice = source.TakeProfitPrice;
   TicketId = source.TicketId;
   
}