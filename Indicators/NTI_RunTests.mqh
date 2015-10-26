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
   if (DetectingTwoNewOrdersShouldSetGlobalVariable())
      testsPassed++;
   totalTests++;
   if (CanDetectClosedOrders())
      testsPassed++;
   totalTests++;
   if (CanPlaceTwoOrders())
      testsPassed++;
   totalTests++;
   if (CanPlaceTwoOrdersAndCloseOne())
      testsPassed++;
   totalTests++;
   if (CanPlaceAndDeleteOrders())
      testsPassed++;
   totalTests++;
   
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
   string GVname = MakeGVname(order.Symbol, 1);
   
   if (!Assert(GVname == Prefix + order.Symbol + "1" + "LastOrderId", "MakeGVname " + GVname + " is not correct")) return false;
   OnTimer();
   if (Assert(GlobalVariableCheck(GVname), "GlobalVariable " + GVname + " was not created."))
   {
      return (Assert(GlobalVariableGet(GVname) == (double) order.TicketId, "GlobalVariable " + GVname + " had value " + DoubleToString(GlobalVariableGet(GVname))));
   }  
   return (false);
}

bool DetectingTwoNewOrdersShouldSetGlobalVariable()
{
   FakeBroker *testBroker = broker;
   numbOpenOrders = 0;
   ClearTrades();
   ClearGlobalVariables();
   testBroker.TotalOrdersToReturn =2;
   Position * order = testBroker.OrdersToReturn[0];
   string GVname = MakeGVname(order.Symbol, 1);
   
   if (!Assert(GVname == Prefix + order.Symbol + "1" + "LastOrderId", "MakeGVname " + GVname + " is not correct")) return false;
   OnTimer();
   if (Assert(GlobalVariableCheck(GVname), "GlobalVariable " + GVname + " was not created."))
   {
      if (!Assert(GlobalVariableGet(GVname) == (double) order.TicketId, "GlobalVariable " + GVname + " had value " + DoubleToString(GlobalVariableGet(GVname))))
         return false;
   }  
   GVname = MakeGVname(order.Symbol, 2);
   if (Assert(GlobalVariableCheck(GVname), "GlobalVariable " + GVname + " was not created."))
   {
      return (Assert(GlobalVariableGet(GVname) == (double) testBroker.OrdersToReturn[1].TicketId, "GlobalVariable " + GVname + " had value " + DoubleToStr(GlobalVariableGet(GVname))));
   }
   return (false);
}

void ClearGlobalVariables()
{
   int gvCount = GlobalVariablesTotal();
   for (int ix = gvCount-1; ix >= 0; ix--)
   {
      string gvName = GlobalVariableName(ix);
      if (StringFind(gvName, "LastOrderId")!= -1)
           GlobalVariableDel(gvName);
   }
}



bool CanDetectClosedOrders()
{

   FakeBroker *testBroker = broker;
   Initialize(); // Clear out open trades
   testBroker.TotalOrdersToReturn = 1; 
   OnTimer(); // Reinstitute the first order
   Position *existingOrder = testBroker.OrdersToReturn[0];
   string GVname = FindGVname(existingOrder.Symbol, existingOrder.TicketId);
   if (!Assert(StringFind(GVname, "LastOrderId") != -1, "name returned by FindGVname does not contain LastOrderId"))
      return false;
   testBroker.TotalOrdersToReturn = 0;
   OnTimer();
   return(Assert(GlobalVariableGet(GVname) == 0, "Existing order ID was not deleted.")); 
   
}

bool CanPlaceTwoOrders()
{
   FakeBroker *testBroker = broker;
   Initialize();
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
   testBroker.TotalOrdersToReturn = 2;
   OnTimer();
   double numbOpenOrders;
   GlobalVariableGet(GVNumbOpenOrders, numbOpenOrders);
   return Assert(numbOpenOrders == 2, "Number of Open Orders not equal 2");
}

bool CanPlaceTwoOrdersAndCloseOne()
{
   FakeBroker *testBroker = broker;
   Initialize();
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
   testBroker.TotalOrdersToReturn = 2;
   OnTimer();
   double numbOpenOrders;
   GlobalVariableGet(GVNumbOpenOrders, numbOpenOrders);
   testBroker.OrderIndex[0] = 1;
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
  
   GlobalVariableGet(GVNumbOpenOrders, numbOpenOrders);
   return Assert(numbOpenOrders == 1, "Number of Open Orders not equal 1");
}

bool CanPlaceAndDeleteOrders()
{
   //Sequence that causes the problem seems to be:
   // 1. Place 2 orders
   // 2. Close 1 of them
   // 3. Place 2 more orders
   // 4. Close 2 orders
   FakeBroker *testBroker = broker;
   Initialize();
   ReInitializeOrderIndex(testBroker);
   testBroker.TotalOrdersToReturn =1;
   OnTimer();
   testBroker.TotalOrdersToReturn=2;
   OnTimer();
   testBroker.OrderIndex[0] = 1;
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();   //Close first order;
   testBroker.OrderIndex[1]=2;
   testBroker.OrderIndex[2]=3;
   testBroker.TotalOrdersToReturn = 2;
   OnTimer(); //Open another order;
   testBroker.TotalOrdersToReturn = 3;
   OnTimer();  //Now we've got 3 open;
   testBroker.OrderIndex[1] = 3;
   testBroker.TotalOrdersToReturn = 2;
   OnTimer();
   testBroker.TotalOrdersToReturn = 1;
   OnTimer();
   double numbOpenOrders;
   GlobalVariableGet(GVNumbOpenOrders, numbOpenOrders);
   return Assert(numbOpenOrders == 1, "Number of Open Orders not equal 1");
}

void ReInitializeOrderIndex(FakeBroker *fake)
{
   for(int i=0;i<ArraySize(fake.OrderIndex);i++)
     {
      fake.OrderIndex[i] = i;
     }
}