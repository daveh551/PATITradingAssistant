//+------------------------------------------------------------------+
//|                                                     RunTests.mq4 |
//|                                                       Dave Hanna |
//|                                http://nohypeforexrobotreview.com |
//+------------------------------------------------------------------+
#property copyright "Dave Hanna"
#property link      "http://nohypeforexrobotreview.com"

#include <FakeBroker.mqh>
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
//+------------------------------------------------------------------+
void RunTests()
{

   int totalTests = 0;
   int testsPassed = 0;
   
   Print("Beginning Unit Tests");
   // Run the individual tests

      broker = new FakeBroker();
   if (CanSetupGlobalVariables())
      testsPassed++;
   totalTests++;
   if (CanGetTotalOrders())
      testsPassed++;
   totalTests++;
   if (CanDetectNewOrders())
      testsPassed++;
   totalTests++;
   if (TimerCallsGetNumberOfOrders())
      testsPassed++;
   totalTests++;
   if (DetectingNewOrderShouldGetOrder())
      testsPassed++;
   totalTests++;
   if (DetectingNewOrderShouldAddOrderToOrderArray())
      testsPassed++;
   totalTests++;
   if (DetectingNewOrderShouldSetGlobalVariable())
      testsPassed++;
   totalTests++;
   if (CanDetectClosedOrders())
      testsPassed++;
   totalTests++;
//   if (CanCalculateBrokerEndTime())
//      testsPassed++;
//   totalTests++;  
   
   Print("Completed tests. ", testsPassed, " of ", totalTests, " passed.");
   if (CheckPointer(broker) == POINTER_DYNAMIC)
      delete (broker);
 
}

//bool CanCalculateBrokerStartTime()
//{
//   Print("Starting CanCalculateBrokerStartTime()");
//   SetupBrokerTestTimes();
//   return (Assert(TimeToStr(brokerQTStart, TIME_MINUTES) == "15:00", "Wrong start time"));   
//}

bool CanSetupGlobalVariables()
{
   FakeBroker *testBroker = broker;
   testBroker.TotalOrdersToReturn = 1;
   SetupGlobalVariables();
   return (Assert(GlobalVariableCheck(Prefix + "NumberOfOpenOrders"), "NumberOfOpenOrders GlobalVariable doesn't exist")); 
}

bool CanGetTotalOrders()
{
   FakeBroker *testBroker = broker;
   testBroker.TotalOrdersToReturn = 1;
   SetupGlobalVariables();
   return (Assert((GlobalVariableGet(Prefix + "NumberOfOpenOrders") == 1), "Number of Open Orders does not equal 1"));
}

bool CanDetectNewOrders()
{
   FakeBroker *testBroker = broker;
   Initialize();
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
   return (Assert((numbOpenOrders == 1), "Number Of Orders did not advance"));
}

bool TimerCallsGetNumberOfOrders()
{
   FakeBroker *testBroker = broker;
   
   testBroker.ResetVerifications();
   OnTimer();
   return (Assert(testBroker.VerifyGetNumberOfOrdersCalled(), "GetNumberOfOrders() did not get called."));
}

bool DetectingNewOrderShouldGetOrder()
{
   FakeBroker *testBroker = broker;
   testBroker.ResetVerifications();
   Initialize();
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
   return (Assert(testBroker.VerifyGetPositionCalled(), "GetPosition was not called."));
}

bool DetectingNewOrderShouldAddOrderToOrderArray()
{
   FakeBroker *testBroker = broker;
   numbOpenOrders = 0;
   ClearTrades();
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
   
   return (Assert(ArraySize(trades) ==1, "Position was not added to List of Trades"));
}

void ClearTrades()
{
   for (int i=ArraySize(trades)-1; i > 0; i--)
   {
      if (CheckPointer(trades[i])==POINTER_DYNAMIC)
         delete trades[i];
   }
   ArrayResize(trades,0,20);
}

bool DetectingNewOrderShouldSetGlobalVariable()
{
   FakeBroker *testBroker = broker;
   numbOpenOrders = 0;
   ClearTrades();
   ClearGlobalVariables();
   testBroker.TotalOrdersToReturn =1;
   Position * order = testBroker.OrdersToReturn[0];
   string GVname = MakeGVname(order.Symbol);
   
   OnTimer();
   if (Assert(GlobalVariableCheck(GVname), "GlobalVariable " + GVname + " was not created."))
   {
      return (Assert(GlobalVariableGet(GVname) == (double) order.TicketId, "GlobalVariable " + GVname + " had value " + DoubleToString(GlobalVariableGet(GVname))));
   }  
   return (false);
}

void ClearGlobalVariables()
{
   string symbol = "EURUSD";
   string GVname = MakeGVname(symbol);
   if (GlobalVariableCheck(GVname))
      GlobalVariableDel(GVname);
}



bool CanDetectClosedOrders()
{

   FakeBroker *testBroker = broker;
   numbOpenOrders = 1;
   ClearTrades();
   Position *existingOrder = testBroker.OrdersToReturn[0];
   string GVname = MakeGVname(existingOrder.Symbol);
   GlobalVariableSet(GVname, (double) existingOrder.TicketId);
   testBroker.TotalOrdersToReturn = 0;
   OnTimer();
   return(Assert(GlobalVariableGet(GVname) == 0, "Existing order ID was not deleted.")); 
   
}


