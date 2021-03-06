//+------------------------------------------------------------------+
//|                                                   TestExpert.mq5 |
//|                                  2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <EA\OrderTxtSignal.mqh>

COrderTxtSignal m_orderTxtSignal;

//+------------------------------------------------------------------+
//| 襄疱麒耠屙?                                                     |
//+------------------------------------------------------------------+
enum lot_type
  {
   fixed,    
   percent
  };

//+------------------------------------------------------------------+
//| 迈钿睇?镟疣戾蝠?                                               |
//+------------------------------------------------------------------+
input string     General        = "=== abc===";
input ushort     PERIOD         =     250; 

input ushort     STOP_LOSS      =      80; 
input ushort     TAKE_PROFIT    =     150; 

input ushort     INSIDE_LEVEL   =      40; 
input ushort     TRAILING_STOP  =      20; 

input ushort     TRAILING_STEP  =      10; 

input ushort     ORDER_STEP     =      10; 
input ushort     SLIPPAGE       =       2; 

input double     LOT            =       0.1; 
input lot_type   LOT_TYPE       =   fixed; 
input bool       LOT_CORRECTION =    false; 
input bool       WRITE_LOG_FILE =   false; 

input ushort     MAGIC_NUMBER   =     867; 


ulong stop_loss;          
ulong take_profit;        
ulong inside_level;       
ulong trailing_level;      

ulong trailing_step;      

ulong order_step;         
ulong slippage;           

double glot;               

bool buy_open    = false; 

bool sell_open   = false; 

double CalcHigh  = 0;     
double CalcLow   = 0;     

double High[], Low[];     

MqlTick tick;             

MqlTick first_tick;       
MqlTradeRequest request;  

MqlTradeResult result;    

double order_open_price;  
double spread;            
ulong stop_level;         

ulong order_type;        
ulong order_ticket;       


int hReportFile;          
int hLogFile;             


double SummaryProfit;    

double GrossProfit;       

double GrossLoss;         
double ProfitFactor;      
double RelEquityDrawdownPercent; 

double MaxEquityDrawdown; 

//+------------------------------------------------------------------+
int OnInit()
//+------------------------------------------------------------------+
 {
   if((LOT_TYPE == percent)&&(LOT > 100))
    {
      Print("0 - 100 %");
      return(-1);
    }

    CSymbolInfo* symbolInfo = new CSymbolInfo();
    symbolInfo.Name(Symbol());
    m_orderTxtSignal.Init(symbolInfo, Period(), 10);
    
   m_orderTxtSignal.InitParameters();
   
   //---
   stop_loss      = STOP_LOSS;
   take_profit    = TAKE_PROFIT;
   inside_level   = INSIDE_LEVEL;
   trailing_level = TRAILING_STOP;
   trailing_step  = TRAILING_STEP;
   slippage       = SLIPPAGE;
   order_step     = ORDER_STEP;

   if((_Digits==3)||(_Digits==5))
     {
      stop_loss      = stop_loss     * 10;
      take_profit    = take_profit   * 10;
      inside_level   = inside_level  * 10;
      trailing_level = trailing_level * 10;
      trailing_step  = trailing_step  * 10;
      slippage       = slippage      * 10;
      order_step     = order_step    * 10;
     }

   
   if(WRITE_LOG_FILE)
    {
      if(!OpenLogFile("log.txt"))
       {   
         Print("湾忸珈铈眍 耦玟囹?羿殡 log.txt");
         return(-1);
       }
    }
   return(0);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
//+------------------------------------------------------------------+
  {
      if(WRITE_LOG_FILE) CloseLogFile();
  }

//+------------------------------------------------------------------+
void OnTick()
//+------------------------------------------------------------------+
  {

   if(SymbolInfoTick(_Symbol, tick)) 
     {
      CalcHigh = 0;
      CalcLow  = 0;

      if(Bars(_Symbol, PERIOD_M5) < PERIOD)
        {
         printf("湾漕耱囹铟眍 桉蝾痂麇耜桴 溧眄 潆 蝾疸钼腓");
         return;
        }

      else
	  
      if((CopyHigh(_Symbol, PERIOD_M5, 0, PERIOD, High) == PERIOD)&&(CopyLow(_Symbol, PERIOD_M5, 0, PERIOD, Low) == PERIOD))
       {
         CalcHigh = High[0];
         CalcLow  = Low[0];


         for(int j=1; j < PERIOD; j++)
          {
            if(CalcHigh < High[j]) CalcHigh = High[j];
            if(CalcLow  >  Low[j]) CalcLow  = Low[j];
          }
       }


      if(CalcHigh < 0.01 || CalcLow < 0.01) return;

      stop_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      spread = tick.ask - tick.bid;
      if(order_step < stop_level) order_step = stop_level;
      if(trailing_level < stop_level) trailing_level = stop_level;
      
      if(tick.bid <= (CalcHigh - inside_level * _Point)) buy_open  = true;
      if(tick.bid >= (CalcLow  + inside_level * _Point)) sell_open = true;

        /*{
            double price, tp, sl;
            datetime expiration;
            buy_open = m_orderTxtSignal.CheckOpenLong(price, sl, tp, expiration);
            sell_open = m_orderTxtSignal.CheckOpenShort(price, sl, tp, expiration);
        }*/
      
            

      WorkWithPositions();

      WorkWithPendidngOrders();


      if(buy_open) OpenOrderBuyStop();


      if(sell_open) OpenOrderSellStop();

     }
   else Print("硒栳赅 镱塍麇龛 溧眄 SymbolInfoTick(), 铠栳赅 眍戾?", GetLastError());

  }

//--- 朽犷蜞 ?镱玷鲨扈
//+------------------------------------------------------------------+
void WorkWithPositions(void)
//+------------------------------------------------------------------+
  {
   for(int pos = 0; pos < PositionsTotal(); pos++)
     {
      if(PositionSelect(PositionGetSymbol(pos)))
        {
         
         if((PositionGetInteger(POSITION_MAGIC) != MAGIC_NUMBER)||(PositionGetString(POSITION_SYMBOL) != _Symbol)) continue;

         order_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         order_type       = PositionGetInteger(POSITION_TYPE);
         request.order    = PositionGetInteger(POSITION_IDENTIFIER);

         if(order_type == POSITION_TYPE_BUY)
           {
            buy_open = false;
            
          
       
            if((stop_loss == 0)||(trailing_level == 0))continue; 
            
            
            double sl = PositionGetDouble(POSITION_SL);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            if ((profit > 0)&&(tick.bid > sl + (trailing_level + trailing_step)*_Point))
            //if(tick.bid > sl + (trailing_level + trailing_step) * _Point)
              {
               request.action = TRADE_ACTION_SLTP;
               request.symbol = _Symbol;
               request.sl     = sl + trailing_step * _Point;
               request.tp     = PositionGetDouble(POSITION_TP);
               request.deviation = slippage;

               OrderSend(request, result);
               if((result.retcode == 10009)||(result.retcode == 10008)) //玎镳铖 恹镱腠屙
                  WriteLogFile("襄疱眍?耱铒 腩耨?铕溴疣 Buy #" + IntegerToString(request.order));
               else
                  WriteLogFile("呜攘世 镥疱眍襦 耱铒 腩耨?铕溴疣 Buy #" + IntegerToString(request.order));
              
              }
            continue;
           }// end POSITION_TYPE_BUY    

         else if(order_type == POSITION_TYPE_SELL)
           {
            sell_open = false;

           if((stop_loss == 0)||(trailing_level == 0)) continue;

            double sl = PositionGetDouble(POSITION_SL);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            if ( (profit > 0) && (tick.ask < sl - (trailing_level + trailing_step) * _Point) )
            {
               request.action = TRADE_ACTION_SLTP;
               request.symbol = _Symbol;
               request.sl     = sl - trailing_step * _Point;
               request.tp     = PositionGetDouble(POSITION_TP);
               request.deviation = slippage;

               OrderSend(request, result);
               if((result.retcode == 10009)||(result.retcode == 10008)) 
                  WriteLogFile("襄疱眍?耱铒 腩耨?Sell #"+IntegerToString(request.order));
               else
                  WriteLogFile("呜攘世 镥疱眍襦 耱铒 腩耨?铕溴疣 Sell #"+IntegerToString(request.order));
            }

           }// end POSITION_TYPE_SELL

        }// end if select                

     }// end for
  }
  
//+------------------------------------------------------------------+
void WorkWithPendidngOrders(void)
//+------------------------------------------------------------------+
  {

   for(int pos=0; pos < OrdersTotal(); pos++)
     {
      order_ticket = OrderGetTicket(pos);

      if(OrderSelect(order_ticket))
        {

         if((OrderGetInteger(ORDER_MAGIC) != MAGIC_NUMBER)||(OrderGetString(ORDER_SYMBOL) != _Symbol)) continue;

         order_type = OrderGetInteger(ORDER_TYPE);
         order_open_price = OrderGetDouble(ORDER_PRICE_OPEN);

         if(order_type == ORDER_TYPE_BUY_STOP)
           {
            buy_open = false;
           
            if(( NormalizeDouble(CalcHigh - order_step * _Point + spread, _Digits) < NormalizeDouble(order_open_price - order_step * _Point + spread, _Digits)) && 
               ( NormalizeDouble(CalcHigh - order_step * _Point + spread, _Digits) > tick.ask + stop_level * _Point))
              {

               request.price = NormalizeDouble(CalcHigh - order_step * _Point + spread, _Digits);

               if(stop_loss == 0) request.sl = 0;
               else request.sl = NormalizeDouble(CalcHigh - order_step * _Point - MathMax(stop_loss, stop_level) * _Point, _Digits);

               if(take_profit == 0) request.tp = 0;
               else request.tp = NormalizeDouble(CalcHigh - order_step * _Point + MathMax(take_profit, stop_level) * _Point, _Digits);

               request.action     = TRADE_ACTION_MODIFY;
               request.order      = order_ticket;
               request.type_time  = ORDER_TIME_GTC;
               request.expiration = 0;

               OrderSend(request, result);
               if((result.retcode == 10009)||(result.retcode == 10008))

                  WriteLogFile("填滂翳鲨痤忄?铕溴?BuyStop #" + IntegerToString(result.order) +
                               StringFormat(" CalcLow=%1.5f order_step=%1.5f order_open_price=%1.5f bid=%1.5f stop_level=%1.5f",
                               CalcLow, order_step * _Point, order_open_price, tick.bid, stop_level * _Point));

               else
                  WriteLogFile("呜攘世 祛滂翳赅鲨?铕溴疣 BuyStop #" + IntegerToString(result.order) +
                               StringFormat(" CalcLow=%1.5f order_step=%1.5f order_open_price=%1.5f bid=%1.5f stop_level=%1.5f err=%d",
                               CalcLow, order_step * _Point, order_open_price, tick.bid, stop_level * _Point, result.retcode));

              }
           }//end ORDER_TYPE_BUY_STOP  

         else if(order_type == ORDER_TYPE_SELL_STOP)
           {
            sell_open = false;
            
            if(( NormalizeDouble(CalcLow + order_step * _Point, _Digits) > order_open_price + order_step * _Point)&& 
               ( NormalizeDouble(CalcLow + order_step * _Point, _Digits) < tick.bid - stop_level * _Point))
              {
               request.price = NormalizeDouble(CalcLow + order_step * _Point, _Digits);

               if(stop_loss == 0) request.sl = 0;
               else request.sl = NormalizeDouble(request.price + MathMax(stop_loss * _Point, stop_level * _Point) + spread, _Digits);

               if(take_profit == 0) request.tp = 0;
               else request.tp = NormalizeDouble(request.price - MathMax(take_profit * _Point, stop_level * _Point) + spread, _Digits);

               request.action    = TRADE_ACTION_MODIFY;
               request.order     = order_ticket;
               request.type_time = ORDER_TIME_GTC;

               OrderSend(request, result);

               if((result.retcode == 10009)||(result.retcode == 10008))

                  WriteLogFile("填滂翳鲨痤忄?铕溴?SellStop #"+IntegerToString(result.order) +
                               StringFormat(" CalcLow=%1.5f order_step=%1.5f order_open_price=%1.5f bid=%1.5f stop_level=%1.5f",
                               CalcLow, order_step * _Point, order_open_price, tick.bid, stop_level * _Point));
               else

                  WriteLogFile("呜攘世 祛滂翳赅鲨?铕溴疣 SellStop #" + IntegerToString(result.order) +
                               StringFormat(" CalcLow=%1.5f order_step=%1.5f order_open_price=%1.5f bid=%1.5f stop_level=%1.5f",
                               CalcLow, order_step * _Point, order_open_price, tick.bid, stop_level * _Point));
              }

           }//end ORDER_TYPE_SELL_STOP   

        }// end order_ticket

     }// end for
  }
    

//+------------------------------------------------------------------+
void OpenOrderBuyStop(void)
//+------------------------------------------------------------------+
  {
   glot = Calculate_Lot(LOT, LOT_TYPE, ORDER_TYPE_BUY); 
   
   request.price = NormalizeDouble(CalcHigh - order_step * _Point + spread, _Digits);

   if(tick.ask + stop_level * _Point > request.price) request.price = tick.ask + stop_level * _Point;
  

   if(stop_loss == 0) request.sl = 0;
   else request.sl = NormalizeDouble(request.price - MathMax(stop_loss, stop_level) * _Point - spread, _Digits);

   if(take_profit == 0) request.tp = 0;
   else request.tp = NormalizeDouble(request.price + MathMax(take_profit, stop_level) * _Point - spread, _Digits);

   request.action       = TRADE_ACTION_PENDING;
   request.symbol       = _Symbol;
   request.volume       = glot;
   request.deviation    = slippage;
   request.type         = ORDER_TYPE_BUY_STOP;
   request.type_filling = ORDER_FILLING_FOK;
   request.type_time    = ORDER_TIME_GTC;
   request.comment      = IntegerToString(MAGIC_NUMBER);
   request.magic        = MAGIC_NUMBER;

   OrderSend(request, result);
   if((result.retcode == 10009)||(result.retcode == 10008))
     {
      buy_open = false;
      WriteLogFile("悟牮 铕溴?BuyStop #" + IntegerToString(result.order));
     }
   else
     {
      printf("青镳铖 磬 篑蜞眍怅?铕溴疣 BuyStop 礤 恹镱腠屙. 暑?铠栳觇: %d", result.retcode);
      WriteLogFile("呜攘世 悟牮? 铕溴疣 BuyStop, 觐?铠栳觇:" + IntegerToString(result.retcode));
     }
     
     Print(CalcHigh, ",", request.price, ",", request.sl, ",", request.tp);
  }
  

//+------------------------------------------------------------------+
void OpenOrderSellStop(void)
//+------------------------------------------------------------------+
  {
   glot = Calculate_Lot(LOT,LOT_TYPE, ORDER_TYPE_SELL); 

   request.price = NormalizeDouble(CalcLow + order_step * _Point, _Digits);

   if(tick.bid - stop_level * _Point < request.price) request.price = tick.bid - stop_level * _Point;
   

   if(stop_loss == 0) request.sl = 0;
   else request.sl = NormalizeDouble(request.price + MathMax(stop_loss * _Point, stop_level * _Point) + spread, _Digits);
   

   if(take_profit == 0) request.tp = 0;
   else request.tp = NormalizeDouble(request.price - MathMax(take_profit * _Point, stop_level * _Point) + spread, _Digits);

   request.action       = TRADE_ACTION_PENDING;
   request.symbol       = _Symbol;
   request.volume       = glot;
   request.deviation    = slippage;
   request.type         = ORDER_TYPE_SELL_STOP;
   request.type_filling = ORDER_FILLING_FOK;
   request.type_time    = ORDER_TIME_GTC;
   request.comment      = IntegerToString(MAGIC_NUMBER);
   request.magic        = MAGIC_NUMBER;

   OrderSend(request, result);

   if((result.retcode == 10009)||(result.retcode == 10008)) 
     {
      sell_open = false;
      WriteLogFile("悟牮 铕溴?SellStop #" + IntegerToString(result.order));
     }
   else
     {
      printf("青镳铖 磬 篑蜞眍怅?铕溴疣 Sell 礤 恹镱腠屙, 觐?铠栳觇:", GetLastError());
      WriteLogFile("呜攘世 悟牮? 铕溴疣 SellStop #" + IntegerToString(result.order));
     }
  }



//+------------------------------------------------------------------+
double Calculate_Lot(double lot,int type,ENUM_ORDER_TYPE direction)
//+------------------------------------------------------------------+
  {
   double acc_free_margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   double calc_margin;
   double price;

   if(direction == ORDER_TYPE_BUY)  price = tick.ask;
   if(direction == ORDER_TYPE_SELL) price = tick.bid;

   switch(type)
     {
      case fixed:
        {
         if(LOT_CORRECTION)
           {
            OrderCalcMargin(direction, _Symbol, lot, price, calc_margin);

            if(acc_free_margin < calc_margin)
              {
               lot = lot * acc_free_margin * 0.9 / calc_margin;
               printf("殃铕疱牝桊钼囗?珥圜屙桢 腩蜞 %f",lot);
              }
           }
         break;
        }

      case percent:
        {

         OrderCalcMargin(direction, _Symbol, 1, price,calc_margin);
         lot = acc_free_margin * 0.01 * LOT / calc_margin;
         break;
        }
     }// end switch

   return(NormalizeLot(lot));
  }

//--- 皖痨嚯桤圉? 忮腓麒睇 腩蜞
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
//+------------------------------------------------------------------+
  {
   double lot_min  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lot_max  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int norm;

   if( lot <= lot_min ) lot = lot_min;               
   else if( lot >= lot_max ) lot = lot_max;          
   else(lot = MathFloor(lot / lot_step) * lot_step); 

   norm = (int)NormalizeDouble(MathCeil(MathLog10( 1 / lot_step)), 0);
   return (NormalizeDouble(lot, norm));              
  }

//+------------------------------------------------------------------+
bool OpenLogFile(string file_name)
//+------------------------------------------------------------------+
  {
   ResetLastError();
   hLogFile = FileOpen(file_name, FILE_WRITE|FILE_TXT|FILE_ANSI);
   return(hLogFile != INVALID_HANDLE);
  }


//+------------------------------------------------------------------+
void WriteLogFile(string text)
//+------------------------------------------------------------------+
  {
   if(WRITE_LOG_FILE) FileWrite(hLogFile, TimeToString(tick.time, TIME_DATE|TIME_SECONDS), " - ", text);
  }


//+------------------------------------------------------------------+
void CloseLogFile()
//+------------------------------------------------------------------+
  {
   FileClose(hLogFile);
  }

