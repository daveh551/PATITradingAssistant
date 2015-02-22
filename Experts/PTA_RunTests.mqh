//+------------------------------------------------------------------+
//|                                                     RunTests.mq4 |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);

// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import

//+------------------------------------------------------------------+
//| EX4 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex4"
//   string ErrorDescription(int error_code);
// #import
#include <FakeBroker.mqh>
//+------------------------------------------------------------------+
void RunTests()
{

   int totalTests = 0;
   int testsPassed = 0;
   
   broker = new FakeBroker();
   Print("Beginning Unit Tests");
   // Run the individual tests


   if (CanCalculateStopsForDefault())
      ++testsPassed;
   totalTests++;
   if (CanCalculateStopsForEURUSD())
      ++testsPassed;
   totalTests++;
   if (CanCalculateStopsForAUDUSD())
      ++testsPassed;
   totalTests++;
   if(CanDetectNewPendingOrder())
      ++testsPassed;
   totalTests++;
   double nextLevelTestValues[] = {110.80,110.00, 110.01, 110.05, 110.10, 110.19, 110.20, 110.21, 110.25, 110.39, 110.40,
      110.49, 110.50, 110.51, 110.60, 110.70, 110.799, 110.80, 110.801, 110.90, 110.999, 111,
      1.1400, 1.14001, 1.1410, 1.14199, 1.1420, 1.14201, 1.1430, 1.14499, 1.14500, 1.14501, 1.1460, 1.1470, 1.14799,
      1.1480, 1.14801, 1.1490, 1.14999, 1.1500};
   double nextLevelUpTestResults[] = {111.00, 110.20, 110.20, 110.20, 110.20, 110.20, 110.50, 110.50, 110.50, 110.50, 110.50,
      110.50, 110.80, 110.80, 110.80, 110.80, 110.800, 111.00, 111.000, 111.00, 111.000,111.20,
      1.1420, 1.1420, 1.1420, 1.1420, 1.1450, 1.1450, 1.1450, 1.1450, 1.1480, 1.1480, 1.1480, 1.1480, 1.1480,
      1.1500, 1.1500, 1.1500, 1.1500, 1.1520}; 
   for(int ix=0;ix<ArraySize(nextLevelTestValues);ix++)
     {
         if (ProperlyDetectsNextLevelUp(nextLevelTestValues[ix], nextLevelUpTestResults[ix]))
            ++testsPassed;
         totalTests++;
           
     }
   

   Print("Completed tests. ", testsPassed, " of ", totalTests, " passed.");
   
 
}

//bool CanCalculateBrokerStartTime()
//{
//   Print("Starting CanCalculateBrokerStartTime()");
//   SetupBrokerTestTimes();
//   return (Assert(TimeToStr(brokerQTStart, TIME_MINUTES) == "15:00", "Wrong start time"));   
//}

bool CanCalculateStopsForDefault()
{
   int stop = CalculateStop("AUDCAD");
   return Assert(stop == 12, "Wrong default stop value calcualated.");
}

bool CanCalculateStopsForEURUSD()
{
   int stop = CalculateStop("EURUSD");
   return Assert(stop == 8, "Wrong stop calculated for EURUSD");
}

bool CanCalculateStopsForAUDUSD()
{
   int stop = CalculateStop("AUDUSD");
   return Assert(stop == 10, "Wrong stop calculated for AUDUSD");
}

bool CanDetectNewPendingOrder()
{
   FakeBroker *testBroker = broker;
   lastTradeId = 0;
   testBroker.OrdersToReturn[0].OrderType = OP_SELLLIMIT;
   globalLastTradeName = "NTI_EURUSDLastOrderId";
   GlobalVariableSet(globalLastTradeName, 12345);
   OnTick();
   if(!Assert(lastTradeId == 12345, "LastTradeId not set")) return false;
   return(Assert(lastTradePending, "LastTradePending is not set"));
}

bool ProperlyDetectsNextLevelUp(double currentPrice, double expected)
{
   double nextLevel = GetNextLevel(currentPrice, 1);
   return(Assert(NormalizeDouble(nextLevel,5) == expected, "NextLevel Up for " + DoubleToStr(currentPrice, 5) + " failed. Expeccted = " + DoubleToStr(expected, 8) + " actual = " + DoubleToStr(nextLevel, 8))) ;
}