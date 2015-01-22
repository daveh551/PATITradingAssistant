//+------------------------------------------------------------------+
//|                                              CandleSizeAlert.mq4 |
//|                         Copyright © 2008, Robert Hill            |
//|                                                                  |
//| Will send alert when a candle meets the size criteria entered   |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Robert Hill"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 LawnGreen
#property indicator_color2 Red
#property indicator_width1  2
#property indicator_width2  2

extern bool SoundOn = true;
extern string SoundFile = "alert.wav";
extern bool AlertON=false;
extern int CandleSize = 50;
extern bool IncludeWicks = true;
extern bool ShowMidPoint = true;
extern color MidpointColor = Blue;

double Bull[];
double Bear[];
int flagval1 = 0;
int flagval2 = 0;
double   myPoint;
datetime barStart = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
//   IndicatorBuffers(5);
   SetIndexStyle(0, DRAW_ARROW, EMPTY);
   SetIndexArrow(0, 233);
   SetIndexBuffer(0, Bull);
   SetIndexStyle(1, DRAW_ARROW, EMPTY);
   SetIndexArrow(1, 234);
   SetIndexBuffer(1, Bear);

     myPoint = SetPoint(Symbol());

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 

//----
   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {
   double myOpen, myClose, myHi, myLo, myDif;
   int limit, i, counter;
   double tmp=0;
   double Range, AvgRange;
   datetime tc;
   
   
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;

   limit=Bars-counted_bars;
   
   for(i = 0; i <= limit; i++) {
   
      counter=i;
      Range=0;
      AvgRange=0;
      for (counter=i ;counter<=i+9;counter++)
      {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
       
      myOpen = iOpen(NULL, 0, i);
      myClose = iClose(NULL, 0, i);
      myHi = iHigh(NULL, 0, i);
      myLo = iLow(NULL, 0, i);
      if (IncludeWicks)
         myDif = NormalizeDouble((myHi - myLo) / myPoint, 4);
      else
         myDif = NormalizeDouble(MathAbs(myOpen-myClose)/myPoint, 4);
       
      Bull[i] = 0;
      Bear[i] = 0;
      if (myDif > CandleSize)
      {
        if (myOpen > myClose)
        {
         if (i == 0 && flagval1==0)
         {
           flagval1=1;
           flagval2=0;
           tc = TimeCurrent();
           if (SoundOn) PlaySound(SoundFile);
           if (AlertON) Alert("Large BEAR candle","\n Time=",TimeToStr(tc,TIME_DATE)," ",TimeHour(tc),":",TimeMinute(tc),"\n Symbol=",Symbol()," Period=",Period());
         }
         Bear[i] = High[i] + Range*0.75;
        }
        else if (myOpen < myClose)
        {
         if (i == 0 && flagval2==0)
         {
          flagval2=1;
          flagval1=0;
          tc = TimeCurrent();
          if (SoundOn) PlaySound(SoundFile);
          if (AlertON) Alert("Large Bull candle","\n Date=",TimeToStr(tc,TIME_DATE)," ",TimeHour(tc),":",TimeMinute(tc),"\n Symbol=",Symbol()," Period=",Period());
         }
         Bull[i] = Low[i] - Range*0.75;
        }
      }
      
      if (ShowMidPoint && i==0 && NewBar())
      {
         if (Bull[1] != 0 || Bear[1] != 0)
         {
            string midpointArrowName = "CSA_" + "MP_" + TimeToStr(Time[1],TIME_DATE | TIME_MINUTES);
            double midPoint = High[1] - (High[1]-Low[1])/2;
            ObjectCreate(midpointArrowName,OBJ_ARROW_RIGHT_PRICE,0,Time[1], midPoint);
            ObjectSet(midpointArrowName, OBJPROP_COLOR, MidpointColor);
            
         }
      }
         
   }

   return(0);
}

double SetPoint(string mySymbol)
{
   double mPoint, myDigits;
   
   myDigits = MarketInfo (mySymbol, MODE_DIGITS);
   if (myDigits < 4)
      mPoint = 0.01;
   else
      mPoint = 0.0001;
   
   return(mPoint);
}

bool NewBar()
{
   if (barStart == 0)
      barStart = Time[0]; // Keep from returning true just because we're initializing
   if (Time[0] > barStart)
   {
      barStart = Time[0];
      return (true);
   }
   return (false);
}