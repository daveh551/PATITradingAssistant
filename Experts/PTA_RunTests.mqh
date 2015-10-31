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
   GVPrefix = NTIPrefix + broker.NormalizeSymbol(Symbol());
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
   if (CanDetectNoNewOrders())
      ++testsPassed;
   totalTests++;
   if (CanDetectANewActiveOrder())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if (CanDetectMultipleNewActiveOrders())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if(CanDetectNewPendingOrder())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if (CanDetectMultipleNewPendingTrades())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if (CanDetectMultipleNewMixedPendingAndActiveTrades())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if (CanHandlePendingTradeStillPending())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if (CanDetectPendingTradeGoneActive())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
   if (CanDetectPendingTradeNowDeleted())
      ++testsPassed;
   totalTests++;
   CleanUpTestTrades();
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
     // Scenarios:
      // 1. No trades previously, no trades now
      // 2. No trades previously, 1 active trade now
      // 3. No trades previously, multiple active trades now
      // 4. No trades previously, 1 pending trade now
      // 5. No trades previously, multiple pending trades now
      // 6. No trades previously, mixed pending and active trades now
      // 7. 1 pending trade previously, trade still pending
      // 8. 1 pending trade previously, trade now active
      // 9. 1 pending trade previously, trade now deleted
      // 10. Multiple pending trades previously, 1 trade now active
      // 11. Multiple pending trades previously, multiple trades now active
      // 12. 1 active trade previously, trade now closed
      // 13. multiple active trades previously, some trades now closed
      // 14. multiple active trades previously, all trades now closed


      // 1. No trades previously, no trades now
bool CanDetectNoNewOrders() //Scenario 1
{
   Print("Beginning CanDetectNoNewOrders");
   FakeBroker *testBroker = broker;
   SetNoTradesPreviously();
   ClearGlobalVariables();
   OnTick();
   if (Assert(totalActiveTrades == 0, "Number of Open Trades increased with no new Trades"))
      return true;
   return false;
}

// Scenario 2
      // 2. No trades previously, 1 active trade now
bool CanDetectANewActiveOrder()
{
   Print ("Beginning CanDetectANewActiveOrder");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, 12345.0);
   
   OnTick();
   if (!Assert(totalActiveTrades == 1, "Number of Open Trades not increased."))
      return false;
   return true;
}
//Scenario 3
      // 3. No trades previously, multiple active trades now
bool CanDetectMultipleNewActiveOrders()
{
   Print ("Beginning CanDetectMultipleNewActiveOrders");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, 12345.0);
   gvName = GVPrefix + "2LastOrderId";
   GlobalVariableSet(gvName, 98765.0);
   
   OnTick();
   if (Assert(totalActiveTrades == 2, "Number of Open Trades is not 2."))
      return true;
   return false;
}
//Scenario 4
      // 4. No trades previously, 1 pending trade now
bool CanDetectNewPendingOrder()
{
   Print ("Beginning CanDetectANewPendingOrder");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[0].TicketId);
   testBroker.OrdersToReturn[0].OrderType = OP_SELLLIMIT;

   OnTick();
   if(!Assert(totalActiveTrades == 1, "Number of Active Trades is not 1")) return false;
   return(Assert(lastTradePending, "LastTradePending is not set"));
}
//Scenario 5
      // 5. No trades previously, multiple pending trades now
bool CanDetectMultipleNewPendingTrades()
{
   Print("Beginning CanDetectMultipleNewPendingTrades");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[0].TicketId);
   testBroker.OrdersToReturn[0].OrderType = OP_SELLLIMIT;
   gvName = GVPrefix + "2LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[1].TicketId);
   testBroker.OrdersToReturn[1].OrderType = OP_BUYLIMIT;
   OnTick();
   if (!Assert(totalActiveTrades == 2, "Number of active trades is not 2")) return false;
   if (!Assert(activeTrades[0].IsPending, "IsPending for first trade is not true")) return false;
   return (Assert(activeTrades[1].IsPending, "IsPending for second trade is not true"));
   
}

//Scenario 6
      // 6. No trades previously, mixed pending and active trades now
bool CanDetectMultipleNewMixedPendingAndActiveTrades()
{
   Print("Beginning CanDetectMultipleNewMixedPendingAndActiveTrades");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[0].TicketId);
   testBroker.OrdersToReturn[0].OrderType = OP_BUY;
   gvName = GVPrefix + "2LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[1].TicketId);
   testBroker.OrdersToReturn[1].OrderType = OP_BUYLIMIT;
   
   OnTick();
   
   if (!Assert(totalActiveTrades == 2, "Number of active trades is not 2")) return false;
   if (!Assert(activeTrades[0].IsPending == false, "IsPending is set for first trade")) return false;
   return (Assert(activeTrades[1].IsPending, "IsPending for second trade is not true"));
}

//Scenario 7
      // 7. 1 pending trade previously, trade still pending
bool CanHandlePendingTradeStillPending()
{
   Print("Beginning CanHandlePendingTradeStillPending");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[0].TicketId);
   testBroker.OrdersToReturn[0].OrderType = OP_BUYLIMIT;
   
   OnTick();  //Now set up with one trade previously.
   //Now, no changes, next Tick - trade still pending
   OnTick();
   if (!Assert(totalActiveTrades == 1, "Number of active trades is not 1")) return false;
   return Assert(activeTrades[0].IsPending, "IsPending is no longer true");
}

//Scenario 8
      // 8. 1 pending trade previously, trade now active
bool CanDetectPendingTradeGoneActive()
{
   Print("Beginning CanDetectPendingTradeGoneActive");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[0].TicketId);
   testBroker.OrdersToReturn[0].OrderType = OP_BUYLIMIT;
   
   OnTick();  //Now set up with one trade previously.
   // Now set that trade to go active on next tick
   testBroker.OrdersToReturn[0].OrderType = OP_BUY;
   OnTick();
   if (!Assert(totalActiveTrades == 1, "Number of active trades is no longer 1")) return false;
   return Assert(activeTrades[0].IsPending == false, "IsPending is still true");
}

//Scenario 9
      // 9. 1 pending trade previously, trade now deleted

bool CanDetectPendingTradeNowDeleted()
{
   Print("Beginning CanDetectPendingTradeNowDeleted");
   FakeBroker *testBroker = broker;
   InitializeActiveTradeArray();
   ClearGlobalVariables();
   string gvName = GVPrefix + "1LastOrderId";
   GlobalVariableSet(gvName, (double) testBroker.OrdersToReturn[0].TicketId);
   testBroker.OrdersToReturn[0].OrderType = OP_BUYLIMIT;
   
   OnTick();  //Now set up with one trade previously.
   GlobalVariableSet(gvName, 0); // Delete pending order
   OnTick();
   if (!Assert(totalActiveTrades == 0, "Number of Active Orders is not 0")) return false;
   if (!Assert(ArraySize(activeTrades) == 1, "activeTrades array size is not 1")) return false;
   return Assert(activeTrades[0] == NULL, "Trade not deleted from array");
}

bool ProperlyDetectsNextLevelUp(double currentPrice, double expected)
{
   double nextLevel = GetNextLevel(currentPrice, 1);
   return(Assert(NormalizeDouble(nextLevel,5) == expected, "NextLevel Up for " + DoubleToStr(currentPrice, 5) + " failed. Expeccted = " + DoubleToStr(expected, 8) + " actual = " + DoubleToStr(nextLevel, 8))) ;
}

void SetNoTradesPreviously() // Set up the precondition that there are no trades outstanding that we know about
{
   InitializeActiveTradeArray();
}

void CleanUpTestTrades()
{
   for(int ix=0;ix < ArraySize(activeTrades);ix++)
     {
      if (CheckPointer(activeTrades[ix]) == POINTER_DYNAMIC) delete activeTrades[ix];
     }
   if (CheckPointer(activeTrade) == POINTER_DYNAMIC) delete activeTrade;
}

void ClearGlobalVariables() // Set up the test condition that there are no new orders
{
   int seqNo = 1;
   while (true)
   {
      string gvName = GVPrefix + IntegerToString(seqNo)+"LastOrderId";
      if (GlobalVariableCheck(gvName))
      {
         GlobalVariableDel(gvName);
         seqNo++;
      }
      else return;
   }
   
}