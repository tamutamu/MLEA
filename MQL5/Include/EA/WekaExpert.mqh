//+------------------------------------------------------------------+
//|                                                   WekaExpert.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Trade\SymbolInfo.mqh>
#include <Files\FileTxt.mqh>
#include <Utils\Utils.mqh>

#import "MT5EA.dll"
   void HelloDllTest(string say);
   void HelloServiceTest(long hHandle, string say);
   long CreateEAService(string symbol);
   void DestroyEAService(long hHandle);
   void Train(long hService, long nowTime, int numInst, int numAttr, double& p[], int numHp, int& r[], int numInst2, double& p2[], int& r2[]);
   int  Test(long hService, long nowTime, int numAttr, double& p[]);
   void Now(long hService, long nowTime, double nowPrice);
#import

#define PREV_TIME_CNT 1
#define PERIOD_CNT 1
#define SYMBOL_CNT 1
#define IND_CNT 0
#define IND2_CNT 4

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CWekaExpert
{
private:
    long m_ea;
    int inds[SYMBOL_CNT][PERIOD_CNT][30];
    CSymbolInfo m_symbolInfo;
    ENUM_TIMEFRAMES m_periods[4];
    string m_symbols[6];
    
    int AMA_9_2_30, ADX_14, ADXWilder_14, Bands_20_2, DEMA_14, FrAMA_14, MA_10, SAR_002_02, StdDev_20, TEMA_14, VIDyA_9_12;
    int ATR_14, BearsPower_13, BullsPower_13, CCI_14, DeMarker_14, MACD_12_26_9, RSI_14, RVI_10, Stochastic_5_3_3, TriX_14, WPR_14;
    datetime m_lastTime;
    int m_currentHour;
    
public:
                     CWekaExpert(string symbol);
                    ~CWekaExpert();
    void GetData(datetime startTime, datetime endTime, double& p[], datetime& ptime[]);
    void BuildModel();
    int PredictByModel();
    void Now();
    int Simulate(int tp, int sl, int dealType, datetime openDate, datetime& closeDate);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CWekaExpert::CWekaExpert(string symbol)
{
    HelloDllTest("HelloDllTest");
    
    m_ea = CreateEAService(symbol);
    if (m_ea == NULL)
    {
        //Alert("WekaExpert Init failed!");
        //return;
    }
    else
    {
        //HelloServiceTest(m_ea, "HelloServiceTest is OK.");
    }
    
    m_symbolInfo.Name(symbol);
    m_periods[0] = PERIOD_M5;
    if (PERIOD_CNT > 1) m_periods[1] = PERIOD_M15;
    if (PERIOD_CNT > 2) m_periods[2] = PERIOD_H1;
    if (PERIOD_CNT > 3) m_periods[3] = PERIOD_H4;
    
    m_symbols[0] = "EURUSD";
    if (SYMBOL_CNT > 1) m_symbols[1] = "GBPUSD";
    if (SYMBOL_CNT > 2) m_symbols[2] = "USDCHF";
    if (SYMBOL_CNT > 3) m_symbols[3] = "USDCAD";
    if (SYMBOL_CNT > 4) m_symbols[4] = "USDJPY";
    if (SYMBOL_CNT > 5) m_symbols[5] = "AUDUSD";
    
    AMA_9_2_30 = ADX_14 = ADXWilder_14 = Bands_20_2 = DEMA_14 = FrAMA_14 = MA_10 = SAR_002_02 = StdDev_20 = TEMA_14 = VIDyA_9_12 = -1;
    ATR_14 = BearsPower_13 = BullsPower_13 = CCI_14 = DeMarker_14 = MACD_12_26_9 = RSI_14 = RVI_10 = Stochastic_5_3_3 = TriX_14 = WPR_14 = -1;
    
    /*for(int s=0; s<SYMBOL_CNT; ++s)
    {
        for(int i=0; i<PERIOD_CNT; ++i)
        {
            int n = 0;
            inds[s][i][n] = iADXWilder(m_symbols[s], m_periods[i], 14);          ADXWilder_14 = n; n++;
            inds[s][i][n] = iADX(m_symbols[s], m_periods[i], 14);                ADX_14 = n; n++;
            inds[s][i][n] = iAMA(m_symbols[s], m_periods[i], 9, 2, 30, 0, PRICE_CLOSE);   AMA_9_2_30 = n; n++;
            inds[s][i][n] = iATR(m_symbols[s], m_periods[i], 14);                          ATR_14 = n; n++;
            inds[s][i][n] = iBands(m_symbols[s], m_periods[i], 20, 0, 2, PRICE_CLOSE);     Bands_20_2 = n; n++;
            inds[s][i][n] = iBearsPower(m_symbols[s], m_periods[i], 13);                   BearsPower_13 = n; n++;
            inds[s][i][n] = iBullsPower(m_symbols[s], m_periods[i], 13);                   BullsPower_13 = n; n++;
            inds[s][i][n] = iCCI(m_symbols[s], m_periods[i], 14, PRICE_TYPICAL);           CCI_14 = n; n++;
            inds[s][i][n] = iDeMarker(m_symbols[s], m_periods[i], 14);                     DeMarker_14 = n; n++;
            inds[s][i][n] = iDEMA(m_symbols[s], m_periods[i], 14, 0, PRICE_CLOSE);         DEMA_14 = n; n++;
            inds[s][i][n] = iFrAMA(m_symbols[s], m_periods[i], 14, 0, PRICE_CLOSE);        FrAMA_14 = n; n++;
            inds[s][i][n] = iMACD(m_symbols[s], m_periods[i], 12, 26, 9, PRICE_CLOSE);     MACD_12_26_9= n; n++;                       
            inds[s][i][n] = iMA(m_symbols[s], m_periods[i], 10, 0, MODE_SMA, PRICE_CLOSE); MA_10 = n; n++;
            inds[s][i][n] = iRSI(m_symbols[s], m_periods[i], 14, PRICE_CLOSE);             RSI_14 = n; n++;
            inds[s][i][n] = iRVI(m_symbols[s], m_periods[i], 10);                          RVI_10 = n; n++;
            inds[s][i][n] = iStochastic(m_symbols[s], m_periods[i], 5, 3, 3, MODE_SMA, STO_LOWHIGH);       Stochastic_5_3_3 = n; n++;
            inds[s][i][n] = iTEMA(m_symbols[s], m_periods[i], 14, 0, PRICE_CLOSE);         TEMA_14 = n; n++;
            inds[s][i][n] = iTriX(m_symbols[s], m_periods[i], 14, PRICE_CLOSE);            TriX_14 = n; n++;
            inds[s][i][n] = iVIDyA(m_symbols[s], m_periods[i], 9, 12, 0, PRICE_CLOSE);     VIDyA_9_12 = n; n++;
            inds[s][i][n] = iWPR(m_symbols[s], m_periods[i], 14);                          WPR_14 = n; n++;
        }
    }*/
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CWekaExpert::~CWekaExpert()
{
    for(int s=0; s<SYMBOL_CNT; ++s)
    {
        for(int i=0; i<PERIOD_CNT; ++i)
        {
            for(int j=0; j<30; ++j)
            {
                if (inds[s][i][j] != NULL)
                {
                    IndicatorRelease(inds[s][i][j]);
                }
            }
         }
    }
    if (m_ea != NULL)
    {
        DestroyEAService(m_ea);
    }
}
//+------------------------------------------------------------------+
void CWekaExpert::Now()
{
    m_symbolInfo.RefreshRates();
    Now(m_ea, TimeCurrent(), m_symbolInfo.Bid());
}

void CWekaExpert::BuildModel()
{
    datetime prevTime = TimeCurrent() / PeriodSeconds(PERIOD_H1) * PeriodSeconds(PERIOD_H1);
    
    if (prevTime == m_lastTime)
        return;
        
    m_lastTime = prevTime;
    
    int batchTrainMinutes = 2 * 4 * 7 * 24 * 12 * 5;
    int batchTestMinutes = 1 * 1 * 12 * 5;
    int dealInfoLastMinutes = 2 * 4 * 7 * 24 * 12 * 5;
    
    
    int tps[1], sls[1];
    for(int i=0; i<1; ++i)
    {
        tps[i] = 100 * i + 100;
        sls[i] = 100 * i + 100;
    }
        
    datetime nowTime = prevTime - batchTrainMinutes * 60;
    while(nowTime < prevTime)
    {
        MqlDateTime nowDate;
        TimeToStruct(nowTime, nowDate);
        m_currentHour = nowDate.hour;
        
        datetime trainStartTime = nowTime - batchTrainMinutes * 60;
        datetime testEndTime = nowTime + batchTestMinutes * 60;
        
        double pTrain[];
        datetime pTimeTrain[];
        GetData(trainStartTime, nowTime, pTrain, pTimeTrain);
        double pTest[];
        datetime pTimeTest[];
        GetData(nowTime, testEndTime, pTest, pTimeTest);
        
        int rTrain[];
        ArrayResize(rTrain, ArraySize(pTimeTrain) * ArraySize(tps) * ArraySize(sls) * 2);
        int n1 = 0, n2 = 0;
        int rTest[];
        ArrayResize(rTest, ArraySize(pTimeTest) * ArraySize(tps) * ArraySize(sls) * 2);
        
        for(int i=0; i<ArraySize(tps); ++i)
        {
            for(int j=0; j<ArraySize(sls); ++j)
            {
                for(int k=0; k<2; ++k)
                {
                    Debug("Get Simulate of " + IntegerToString(tps[i]) + ", " + IntegerToString(sls[j]) + ", " + IntegerToString(k) + ", " + IntegerToString(ArraySize(pTimeTrain)));
                    for(int t=0; t < ArraySize(pTimeTrain); ++t)
                    {
                        datetime closeTime;
                        rTrain[n1] = Simulate(tps[i], sls[j], k, pTimeTrain[t], closeTime);
                        //Debug(TimeToString(pTimeTrain[t]) + " simulate get " + IntegerToString(rTrain[n1]) + " close at " + TimeToString(closeTime));
                        ++n1;
                    }
                    for(int t=0; t < ArraySize(pTimeTest); ++t)
                    {
                        datetime closeTime;
                        rTest[n2] = Simulate(tps[i], sls[j], k, pTimeTest[t], closeTime);
                        //Debug(TimeToString(pTimeTest[t]) + " simulate get " + IntegerToString(rTest[n2]) + " close at " + TimeToString(closeTime));
                        ++n2;
                    }
                }
            }
        }
    
    /*int pn = 0;
    double pp[];
    int pr[];
    ArrayResize(pp, ArraySize(p));
    ArrayResize(pr, ArraySize(r));
    for(int i=0; i<ArraySize(ptime); ++i)
    {
        if (r[i] != INT_MIN)
        {
            for(int j=0; j<numAttr; ++j)
            {
                pp[pn * numAttr + j] = p[i * numAttr + j];
            }
            pr[pn] = r[i];
            
            pn++;
            
            Debug(TimeToString(ptime[i]) + " simulate get " + IntegerToString(r[i]));
        }
    }
    ArrayResize(pp, pn * numAttr);
    ArrayResize(pr, pn);*/
    
        int numInst = ArraySize(pTimeTrain);
        int numInst2 = ArraySize(pTimeTest);
        int numHp = ArraySize(tps) * ArraySize(sls) * 2;
        int numAttr = (IND_CNT + IND2_CNT) * PERIOD_CNT * SYMBOL_CNT * PREV_TIME_CNT + 6;
        Train(m_ea, nowTime, numInst, numAttr, pTrain, numHp, rTrain, numInst2, pTest, rTest);
        
        nowTime += batchTestMinutes * 60;
        
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        CopyRates(m_symbols[0], PERIOD_M1, nowTime - batchTestMinutes * 60, nowTime, rates);
        for(int i=ArraySize(rates) - 1; i>=0; --i)
        {
            Now(m_ea, rates[i].time, rates[i].open);
            Now(m_ea, rates[i].time + 20, rates[i].low);
            Now(m_ea, rates[i].time + 40, rates[i].high);
            Now(m_ea, rates[i].time + 60, rates[i].close);
        }
    }
    //Alert(TimeToString(ptime[0]) + ", " + TimeToString(ptime[ArraySize(ptime) - 1]));
    
    Info("Build model from " + TimeToString(nowTime) + " to " + TimeToString(prevTime));
}

int CWekaExpert::PredictByModel()
{
    int numAttr = (IND_CNT + IND2_CNT) * PERIOD_CNT * SYMBOL_CNT * PREV_TIME_CNT + 6;
    
    datetime now = TimeCurrent();
    datetime lastnow = now / PeriodSeconds(m_periods[0]) * PeriodSeconds(m_periods[0]);
    
    double p[];
    datetime ptime[];
    GetData(lastnow, lastnow - 1, p, ptime);
    
    int r = Test(m_ea, lastnow, numAttr, p);
    return r;
}

int CWekaExpert::Simulate(int tp, int sl, int dealType, datetime openDate, datetime& closeDate)
{
    datetime nowTime = TimeCurrent();
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    CopyRates(m_symbols[0], PERIOD_M1, openDate - PeriodSeconds(PERIOD_M1), nowTime, rates);
    
    double m_tp = tp * 0.0001;
    double m_sl = sl * 0.0001;
    
    if (dealType == 0)
    {
        datetime buyCloseDate = D'1970.1.1';
        int buyRet = 1;
        // try buy
        double buyOpen = rates[ArraySize(rates) - 1].close;
        double buyTp = buyOpen + m_tp;
        double buySl = buyOpen - m_sl;
        
        for (int j = ArraySize(rates) - 1; j >= 0; --j)
        {
            if (rates[j].low <= buySl)
            {
                buyRet = 0;
                buyCloseDate = rates[j].time;
                break;
            }
            else if (rates[j].high >= buyTp)
            {
                buyRet = 2;
                buyCloseDate = rates[j].time;
                break;
            }
        }
        if (buyRet != 1)
        {
            closeDate = buyCloseDate;
            closeDate += PeriodSeconds(PERIOD_M1);
        }
        return buyRet;
    }
    else if (dealType == 1)
    {
        datetime sellCloseDate = D'1970.1.1';
        int sellRet = 1;
        // try sell
        double sellOpen = rates[ArraySize(rates) - 1].close;
        double sellTp = sellOpen - m_tp;
        double sellSl = sellOpen + m_sl;
        for (int j = ArraySize(rates) - 1; j >= 0; --j)
        {
            if (rates[j].high >= sellSl)
            {
                sellRet = 0;
                sellCloseDate = rates[j].time;
                break;
            }
            else if (rates[j].low <= sellTp)
            {
                sellRet = 2;
                sellCloseDate = rates[j].time;
                break;
            }
        }
        if (sellRet != 1)
        {
            closeDate = sellCloseDate;
            closeDate += PeriodSeconds(PERIOD_M1);
        }
        return sellRet;
    }
    else
    {
        return 1;
    }
}

void CWekaExpert::GetData(datetime startTime, datetime endTime, double& dp[], datetime& ptime[]) 
{
    Debug("GetData from " + TimeToString(startTime) + " to " + TimeToString(endTime));
    
    datetime times[];
    ArraySetAsSeries(times, true);
    CopyTime(m_symbols[0], m_periods[0], startTime - PeriodSeconds(m_periods[0]), endTime, times);

    int numInst = 0;
    MqlDateTime date;
    for(int t=0; t<ArraySize(times); ++t)
    {
        datetime time = times[ArraySize(times) - 1 - t] + PeriodSeconds(m_periods[0]);
        TimeToStruct(time, date);
        if (date.hour == m_currentHour)
            numInst++;
    }
    int numAttr = (IND_CNT + IND2_CNT) * PERIOD_CNT * SYMBOL_CNT * PREV_TIME_CNT + 6;

    //double p[];
    ArrayResize(dp, numAttr * numInst);
    ArrayResize(ptime, numInst);
    
    int pos = 0;
    for(int t=0; t<ArraySize(times); ++t)
    {
        datetime time = times[ArraySize(times) - 1 - t] + PeriodSeconds(m_periods[0]);
        TimeToStruct(time, date);
        if (date.hour != m_currentHour)
            continue;
            
        ptime[pos] = time;
        
        dp[pos * numAttr + 0] = (double)time;
        dp[pos * numAttr + 1] = 0;    // closeTime
        dp[pos * numAttr + 2] = date.hour / 24.0;
        dp[pos * numAttr + 3] = date.day_of_week / 5.0;
        dp[pos * numAttr + 4] = 0;    // vol
        dp[pos * numAttr + 5] = 0.00; // mainClose
        
        int start = pos * numAttr + 6;
        
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        double indBuf[];
        ArraySetAsSeries(indBuf, true);
        
        for(int s=0; s<SYMBOL_CNT; ++s)
        {
            double mainClose = 0;
            for(int i=0; i<PERIOD_CNT; ++i)
            {
                datetime newTime = time - PeriodSeconds(m_periods[i]);
                CopyRates(m_symbols[s], m_periods[i], newTime, 2 * PREV_TIME_CNT, rates);
                if (i == 0)
                {
                    mainClose = dp[pos * numAttr + 5] = rates[0].close;
                }
                for(int p=0; p<PREV_TIME_CNT; ++p)
                {
                    dp[start] = rates[p].close;  start++;
                    dp[start] = rates[p].open;   start++;
                    dp[start] = rates[p].high;   start++;
                    dp[start] = rates[p].low;    start++;
                    
                    /*if (ADXWilder_14 != -1)
                    {
                        CopyBuffer(inds[s][i][ADXWilder_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][ADXWilder_14], 1, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][ADXWilder_14], 2, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start += 3;
                    }
                    
                    if (ADX_14 != -1)
                    {
                        CopyBuffer(inds[s][i][ADX_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][ADX_14], 1, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][ADX_14], 2, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start += 3;
                    }
                    
                    if (AMA_9_2_30 != -1)
                    {
                        CopyBuffer(inds[s][i][AMA_9_2_30], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (ATR_14 != -1)
                    {
                        CopyBuffer(inds[s][i][ATR_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (Bands_20_2 != -1)
                    {
                        CopyBuffer(inds[s][i][Bands_20_2], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (BearsPower_13 != -1)
                    {
                        CopyBuffer(inds[s][i][BearsPower_13], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (BullsPower_13 != -1)
                    {
                        CopyBuffer(inds[s][i][BullsPower_13], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (CCI_14 != -1)
                    {   
                        CopyBuffer(inds[s][i][CCI_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (DeMarker_14 != -1)
                    {
                        CopyBuffer(inds[s][i][DeMarker_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (DEMA_14 != -1)
                    {
                        CopyBuffer(inds[s][i][DEMA_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (FrAMA_14 != -1)
                    {
                        CopyBuffer(inds[s][i][FrAMA_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (MACD_12_26_9 != -1)
                    {    
                        CopyBuffer(inds[s][i][MACD_12_26_9], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][MACD_12_26_9], 1, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start += 2;
                    }
                    
                    if (MA_10 != -1)
                    {    
                        CopyBuffer(inds[s][i][MA_10], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (RSI_14 != -1)
                    {
                        CopyBuffer(inds[s][i][RSI_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (RVI_10 != -1)
                    {
                        CopyBuffer(inds[s][i][RVI_10], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][RVI_10], 1, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }    
                    else
                    {
                        start += 2;
                    }
                     
                    if (Stochastic_5_3_3 != -1)
                    {
                        CopyBuffer(inds[s][i][Stochastic_5_3_3], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                        CopyBuffer(inds[s][i][Stochastic_5_3_3], 1, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start += 2;
                    }
                    
                    if (TEMA_14 != -1)
                    {
                        CopyBuffer(inds[s][i][TEMA_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (TriX_14 != -1)
                    {
                        CopyBuffer(inds[s][i][TriX_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (VIDyA_9_12 != -1)
                    {
                        CopyBuffer(inds[s][i][VIDyA_9_12], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }
                    
                    if (WPR_14 != -1)
                    {
                        CopyBuffer(inds[s][i][WPR_14], 0, newTime, 2 * PREV_TIME_CNT, indBuf);
                        dp[start] = indBuf[p];   start++;
                    }
                    else
                    {
                        start ++;
                    }*/
                }
            }
        }
        pos++;
    }
    
    /*CFileTxt file;
    file.Open("p.txt", FILE_WRITE);
    file.Seek(0, SEEK_END);
    for(int i=0; i<ArraySize(rates); ++i)
    {
        for(int j=0; j<numAttr; ++j)
        {
            file.WriteString(DoubleToString(dp[i * numAttr + j], 5));
            file.WriteString(", ");
         }
         file.WriteString("\r\n");
    }
    file.Close();*/
    Debug("GetDate End");
    
    return;
}
