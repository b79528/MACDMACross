//+------------------------------------------------------------------+
//|                                             DevMACDMACrossv4.mq4 |
//| This robot enters a trade when MACD and MA Crossover with a 10pt |
//| buffer and 11 min expiration and exits                           |
//| the trade when the low of current bar breaks the fastMA.  there  |
//| is no stop loss                                                  |
//| and no take profit                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Toro Rosso Trading Company LLC"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "CheckAnyTrend.mq4";


//--- input parameters
input int            FASTEMA=13;
input int            SLOWMA=89;

input double         LotSize=0.01;
input int            Slippage=3;
int MagicNumber=09221964;

//--- indicator inputs
sinput string        indi="";                // ------ Indicators -----

//--- global variables
double MyPoint;
int    MySlippage;

//--- indicators
double MACD[2],fast_MA[3],slow_MA[3];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MyPoint=MyPoint();
   MySlippage=MySlippage();

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
    // Update Indicators on every tick
      InitIndicators();

    if(TotalOpenOrders()==0 && IsNewBar())
     {
      // Check Buy Entry
      if(BuySignal()) OpenBuy();

      // Check Sell Entry
      else if(SellSignal()) OpenSell();
     }
    
    //check for crossed pair on every tick
    CheckCrossedPair();
 
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void InitIndicators()
  {
   for(int i=0;i<2;i++)
     {
      // MACD (0-MODE_MAIN, 1-MODE_SIGNAL)
      MACD[i]=iMACD(_Symbol,PERIOD_CURRENT,12,26,9,PRICE_CLOSE,i,0);

      // Fast MA
      fast_MA[i+1]=iMA(_Symbol,PERIOD_CURRENT,FASTEMA,0,MODE_LWMA,PRICE_CLOSE,1+i);

      // Slow MA
      slow_MA[i+1]=iMA(_Symbol,PERIOD_CURRENT,SLOWMA,0,MODE_LWMA,PRICE_CLOSE,1+i);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BuySignal()
  {
// MACD zero line filter
//   if(!(MACD[0] > 0 && MACD[1] > 0))return(false);

// MACD trend filter
//   if(!(MACD[0] > MACD[1]))return(false);

// Check Signal
   if(fast_MA[1] > slow_MA[1] && fast_MA[2] < slow_MA[2])return(true);

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SellSignal()
  {
// MACD zero line filter
//   if(!(MACD[0] < 0 && MACD[1] < 0))return(false);

// MACD trend filter
//   if(!(MACD[0] < MACD[1]))return(false);

// Check Signal
   if(fast_MA[1] < slow_MA[1] && fast_MA[2] > slow_MA[2])return(true);

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenBuy()
  {
// Open Buy Order
   MagicNumber = MagicNumber + rand();
   int DevExpire = TimeCurrent()+11*60; //Order expires in 11 minutes
   double takeprofit = NormalizeDouble(Ask+(144*Point),Digits);
   
   int ticket=OrderSend(_Symbol,OP_BUYSTOP,LotSize,(Ask+(20*Point)),MySlippage,0,takeprofit,"Buy Stop",MagicNumber,DevExpire,clrCadetBlue);

   if(ticket<0) Print("Buy Order Send failed with error #",GetLastError());
   else Print("Buy Order placed successfully");

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenSell()
  {
//Open Sell Order
   MagicNumber = MagicNumber - rand();
   int DevExpire = TimeCurrent()+11*60; //Order expires in 11 minutes
   double takeprofit = NormalizeDouble(Ask+(144*Point),Digits);
   
   int ticket=OrderSend(_Symbol,OP_SELLSTOP,LotSize,(Bid-(20*Point)),MySlippage,0,takeprofit,"Sell Stop",MagicNumber,DevExpire,clrCadetBlue);

   if(ticket<0) Print("Sell Order Send failed with error #",GetLastError());
   else Print("Sell Order placed successfully");

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MyPoint()
  {
   double CalcPoint=0;

   if(_Digits==2 || _Digits==3) CalcPoint=0.01;
   else if(_Digits==4 || _Digits==5) CalcPoint=0.0001;

   return(CalcPoint);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MySlippage()
  {
   int CalcSlippage=0;

   if(_Digits==2 || _Digits==4) CalcSlippage=Slippage;
   else if(_Digits==3 || _Digits==5) CalcSlippage=Slippage*10;

   return(CalcSlippage);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime RegBarTime=0;
   datetime ThisBarTime=Time[0];

   if(ThisBarTime==RegBarTime)
     {
      return(false);
     }
   else
     {
      RegBarTime=ThisBarTime;
      return(true);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TotalOpenOrders()
// Returns the number of total open orders for this Symbol and MagicNumber
  {
   int total_orders=0;

   for(int order=0; order<OrdersTotal(); order++)
     {
      if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()==MagicNumber && OrderSymbol()==_Symbol)total_orders++;
     }

   return(total_orders);
  }
//+------------------------------------------------------------------+
void CheckCrossedPair()
{
   // count all orders
   for (int i=OrdersTotal(); i>=0;i--)
   {
      // now select one open order with same pair as chart 
      if (OrderSelect(i,SELECT_BY_POS)==true)
      {
         //check profitability of currency pair that we are trading
         if (OrderSymbol() == _Symbol)
         {
            // now get the order type
            if(OrderType() == OP_BUY)
            {        
               // for v4, we are closing the trade when low of current break breaks through slow moving average
               if (Low[0] < slow_MA[1])
               {
                  bool result = OrderClose(OrderTicket(),OrderLots(),Ask,5,Red); 
               }
            }   
            else if(OrderType() == OP_SELL)
            {
               if(High[0] > slow_MA[1])
               {
                  bool result = OrderClose(OrderTicket(),OrderLots(),Ask,5,Red); 
               }
            }   
         } //end processing for current symbol

      } // end order select loop
    } // end for loop  
} // end file
