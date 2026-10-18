### NASD-100 Monthly 121 Data
### Sort by Yearly 12 Month Performance
### Moving 1 Month at a Time
### Buy Top 10
### 101 lines X 121 columns 
### Col-1 = Symbol  Row-1 Label#
###  List2CSV(aList)      --> cCSVString
###  CSV2List(cCSVString) --> aList


// load "stdlibcore.ring"
// load "csvlib.ring"
// load "guilib.ring"

# =========================================


//$RangeMth = 7        // Performance EndCol - StartCol
//$Top10    = 7        // Short-10.csv  Long = 10     // Buy if Rank <= 10
//csvFile   = "AAA-Spread.csv"   // NEEDED

$Algorithm = "Momentum (original)"    // Default Ranking Algorithm (overwritten by combo selection in YearlyReturns())

a2DTest  = ["",""]

tList    = [""]   // tList with Symbol in Col-1
aList    = [""]   // CSV List
pList    = [""]   // Performance
sList    = [""]   // Sort  Performance
nList    = [""]   // Sort  Name-Position after Sorted
rList    = [""]   // GenerateRank  Rank 1-10 ... 100
bList    = [""]   // Buy Price
gList    = [""]   // Gain %percent 
mList    = [""]   // Montly gain 
cList    = [""]   // Compoud Gain 
hList    = [""]   // History Ret 

aSumTotal = ["","","",""]   // Nbr 1-120,  QQQ, TOT, SPY 
$maxQQQ   = 0             // Final QQQ compounded value        -- set in ShowTop10()
$maxSPY   = 0             // Final SPY compounded value        -- set in ShowTop10()
$maxTOT   = 0             // Final Portfolio compounded value  -- set in ShowTop10()
$Ratio    = 0             // Outperform multiple (TOT vs QQQ)  -- set in ShowTop10()
$RatioSPY = 0             // Outperform multiple (TOT vs SPY)  -- set in ShowTop10()
$CAGR     = 0             // Portfolio Annual CAGR      -- set in ComputePortfolioStats()
$Sharpe   = 0             // Portfolio Sharpe Ratio     -- set in ComputePortfolioStats()
$MaxDD    = 0             // Portfolio Max Drawdown     -- set in ComputePortfolioStats()

aDateRead = []      // aTimpStamp to Human Readable 
aCsvDateRow = null  // fix 2026-Aug-23: the "Date" row read back from AAA-Spread.csv,
                    // used to rebuild lastDate / aDateRead when GetQuotes() did NOT
                    // run this session (offline run using a saved CSV) -- see
                    // SyncOfflineDateScaffold() and ShowTop10()

# --- Weekly Stop-Sell hook: current month's Top-10 buy basket ---------
# Populated at the end of ShowTop10() every run; consumed by
# SyncWeeklyTop10Buys() in Stock-WeeklyStopSell.ring
aTop10Symbols  = []      // Symbol for each of this month's Top-10 buys
aTop10BuyPrice = []      // Buy price (month-open) for each symbol, same order
aTop10BuyDate  = []      // "01/mm/yyyy" buy-month key, same order
aTop10NowPrice = []      // Latest ("Now") price for each symbol, same order
aTop10Shares   = []      // Nbr shares bought with $Dollars, same order

# ------------------------------------

DebugTlist = 0    //  temp Debug =1
DebugAlist = 0    //  array Data 
DebugPlist = 0    //  performance   
DebugSlist = 0    //  sort 
DebugNlist = 0    //  sort-name 
DebugRlist = 0    //  rank  
DebugBlist = 0    //  buy price 
DebugGlist = 0    //  gain  
DebugMlist = 0    //  montly performance 
DebugClist = 0    //  compound 


DebugSClist = 0    // Summary Stock compounded        Compount for Row-last  mList
DebugTClist = 0    // Summart Total compounded vs QQQ Compound Gain Percent  cList

DebugS10List = 1   // Show $Top10 Current
DebugGDList  = 0   // Printout Buys Sell Gain
DebugHRList  = 0   // History returm


// ================================================
// ================================================
// START HERE
  
Func YearlyReturns()


    StockCount    = 1   // Restore so Stk-Next starts at 1 again
	
    // --- TOGGLE Debug the Array Outputs - TOGGLE Settings 0-> 1 or 1->0 ---

    DebugValue = comboDebugSet.currentText()
	if DebugValue = "Array-Data"      if DebugAlist   = 1   DebugAlist   = 0  else  DebugAlist   = 1 ok  ok
	if DebugValue = "Performance"     if DebugPlist   = 1   DebugPlist   = 0  else  DebugPlist   = 1 ok  ok
	if DebugValue = "Sort"            if DebugSlist   = 1   DebugSlist   = 0  else  DebugSlist   = 1 ok  ok
	if DebugValue = "Sort-Name"       if DebugNlist   = 1   DebugNlist   = 0  else  DebugNlist   = 1 ok  ok
	if DebugValue = "Rank"            if DebugRlist   = 1   DebugRlist   = 0  else  DebugRlist   = 1 ok  ok
	if DebugValue = "Buy-Price"       if DebugBlist   = 1   DebugBlist   = 0  else  DebugBlist   = 1 ok  ok
	if DebugValue = "Gain"            if DebugGlist   = 1   DebugGlist   = 0  else  DebugGlist   = 1 ok  ok
	if DebugValue = "Monthly-Perf"    if DebugMlist   = 1   DebugMlist   = 0  else  DebugMlist   = 1 ok  ok
	if DebugValue = "Compound"        if DebugClist   = 1   DebugClist   = 0  else  DebugClist   = 1 ok  ok
	if DebugValue = "Summary-Stock"   if DebugSClist  = 1   DebugSClist  = 0  else  DebugSClist  = 1 ok  ok
	if DebugValue = "Summary-Total"   if DebugTClist  = 1   DebugTClist  = 0  else  DebugTClist  = 1 ok  ok
	if DebugValue = "Show-Top10"      if DebugS10List = 1   DebugS10List = 0  else  DebugS10List = 1 ok  ok
	if DebugValue = "Gain-Details"    if DebugGDList  = 1   DebugGDList  = 0  else  DebugGDList  = 1 ok  ok
	if DebugValue = "HistoryRet"      if DebugHRList  = 1   DebugHRList  = 0  else  DebugHRList  = 1 ok  ok
	
	// See nl+"<===== DEBUG SETTING =====> "+nl
	// See "Array-Data   "+  DebugAlist   +nl
	// See "Performance  "+  DebugPlist   +nl
	// See "Sort         "+  DebugSlist   +nl     
	// See "Sort-Name    "+  DebugNlist   +nl
	// See "Rank         "+  DebugRlist   +nl     
	// See "Buy-Price    "+  DebugBlist   +nl
	// See "Gain         "+  DebugGlist   +nl     
	// See "Monthly-Perf "+  DebugMlist   +nl
	// See "Compound     "+  DebugClist   +nl 
	// See "Summary-Stock"+  DebugSClist  +nl
	// See "Summary-Total"+  DebugTClist  +nl
	// See "Show-Top10   "+  DebugS10List +nl
	// See "Gain-Details "+  DebugGDList  +nl
    // See "HistoryRet   "+  DebugHRList  +nl
	// See "<===== End Debug Setting =====> "+nl+nl
	

    //--- Reapeat from GetHistory
    cInterval   = comboInterval.currentText()
    cRange      = comboRange.currentText()
	cTopTen     = comboTopTen.currentText()
    cFile       = txtTickerFile.text()
	cInFileName = txtTickerFile.text()  // Picked File QuotesXXX.ini    
	cRangeMth   = comboRangeMth.currentText()
	cAlgorithm  = comboAlgorithm.currentText()   // Ranking Algorithm Dropdown
    
		
    $Interval =    cInterval	// Curl GetQuotes
    $Range    =    cRange	    // Curl GetQuores
    $Top10    = 0+ cTopTen      // YearlyReturns
    $RangeMth = 0+ cRangeMth    // YearlyReturns  "$RangeMth" is Month Range | NOT $Range for Curl	
    $Algorithm=    cAlgorithm   // YearlyReturns  Which Ranking Algorithm to use in CalcPerformance()
	

    See "$RangeMth: "+ $RangeMth +" $Top10: "+ $Top10 +" Quotes: "+ cInFileName  +nl
    See "cInterval: "+ cInterval +" cRange: "+ cRange  +" cFile: "+ cFile +" $Algorithm: "+ $Algorithm +nl

    //--- NOW READY TO GO ---------------------------

    // for $RangeMth = 6 to 9
    //    for $Top10 =  6 to 10 

        ReadCSVFile()       // aList = csvfile
        SyncOfflineDateScaffold()  // fix: rebuild lastDate/date-labels from CSV when offline
        CreateLists()       // tList with Symbol
        CalcPerformance()   // pList
        SortPerformance()   // sList => nList Name
        GenerateRank()      // rList
        BuyRank()           // bList = Price in nCol if Rank <= $Top10 
        CalcGain()          // gList = Gain = Buy at nCol See at nCol +1 
        MonthlyGain()       // mList = Avg Gain for each nCol 
        Compounding()       // cList = Compoud gains by Periods 
        SummaryStock()      // Stock Compunded
        SummaryTotal()      // Total $Top10 Compounded vs QQQ
        ShowTop10()         // Show last $Top10 Symbols
		
		// aSumTotal: Row-1 =Nbr |  Row-2 =QQQ | Row-3 =Tot | Row-4 =SPY |

    //DebugArray(aSumTotal) ?" "		
		
		Del(aSumTotal[1], len(aSumTotal[1]) )    // Remove last price 0 ?
		Del(aSumTotal[1],1)                      // Remove 1st Numbers 1..60

		Del(aSumTotal[2], len(aSumTotal[2]) )    // Remove last price 0 ?
		Del(aSumTotal[2],1)                      // Remove Name:  QQQ 1..60

 		Del(aSumTotal[3], len(aSumTotal[3]) )    // Remove last price 0 ?
		Del(aSumTotal[3],1)		                 // Remove Name:  TOT or performance 1..60
		Del(aSumTotal[3], len(aSumTotal[3]) )    // Shift right 1 to align with QQQ  and TOTon Chart
		Insert(aSumTotal[3], $RangeMth+1, 1)

		Del(aSumTotal[4], len(aSumTotal[4]) )    // Remove last price 0 ?
		Del(aSumTotal[4],1)                      // Remove Name:  SPY 1..60
		
		oChartWidget.setData(aSumTotal)  // Use Azzeddine Chart

     //DebugArray(aSumTotal) ?" "
  
        // DrawChartQT(aSumTotal)        // Use QT Chart 
	
	//---------------------------------
	
       
    //     next
    //   See "<==========>"+nl
    // next
 

// =======================================================
// =======================================================
// Use aList for CSV read in  ( QQQ = DataLen from Main)

Func ReadCSVFile()

    cFile = Read(csvFile)
	
    aList = CSV2List( Read(csvfile) )     // Create 2D array
	
	DataLength = len(aList[1])            // Cols
	See "Read csvFile: DataLength: "+ DataLength +nl
	
	for i = 1 to len(alist)               // Rows
	    if len(aList[i]) < DataLength
		
		    HowMuch = DataLen - len(aList[i])   // DataLength
		    for h = 1 to HowMuch
		       Insert( aList[i], 2, aList[i][2] )   // Fill LEFT List Index Value ..Col		   
		       //See "Insert: "+ h +" "+ aList[i][1] +" "+ aList[i][2] +" "+  aList[i][3] +" "+  aList[i][5]  +nl
			next   
		
        else	
		    if len(aList[i]) > DataLength
		        SEE "ReadCSVFile: "+i +" Sym: "+ aList[i][1] +" DataLength: "+ len(aList[i]) +" QQQ-Datalen: "+ DataLen +nl
				DEL( aList[i], 2)
		   
		    ok
			
	    ok
	next
 
if DebugAList = 1 
    See nl+"<----- Debug CSV to aList 2D Display ----->"+nl
    DebugArray(aList)
ok  
    
    
Return

// =================================== 
// fix 2026-Aug-23
// When Get Quotes was run live this session, Stock-Analysis-BM.ring's
// GetQuotes() sets the globals `lastDate` and `aTimeStamp` from the fresh
// download, and ShowTop10() builds its date labels from `aTimeStamp`.
//
// When GetQuotes() could NOT run (no internet, falling back to a saved
// AAA-Spread.csv / AAA-Spread.csv.bkp), neither global gets updated:
// `lastDate` stays stuck at its hardcoded startup value ("01/02/2026") and
// `aTimeStamp` stays empty. ShowTop10() then tries to index an empty
// aDateRead array and crashes (Array Access - Index out of range).
//
// AAA-Spread.csv always carries its own "Date" row (written the last time
// GetQuotes() succeeded), so we can rebuild everything ShowTop10() needs
// from that row instead of requiring a live download.

Func SyncOfflineDateScaffold()

    aCsvDateRow = null
    for Row in aList
        if subStr( Row[1], "Date")
            aCsvDateRow = Row
        ok
    next

    if aCsvDateRow != null AND len(aTimeStamp) <= 10     // GetQuotes did NOT run live this session
        lastDate = aCsvDateRow[ len(aCsvDateRow) ]        // most recent saved date, "dd/mm/yyyy"
    ok

Return

// =================================== 
// Create Lists based on aList size
// Add Symbols to Col-1
// QQQ     103.86 

Func CreateLists()

    tList = List( len(aList), len(aList[1]) )
    for i = 1 to len(aList)
        tList[i][1] = aList[i][1]                 // Symbol 
    next

if DebugTList = 1   
    See nl+"<----- Debug tList ----->"+nl
    DebugArray(tList)
ok  
    
        
Return

// =================================== 
// =================================== 

Func DebugArray(arrayList)

    nRow = 0  
	nCol = 0  
    nRow = len(arrayList)  

    if ! islist(arraylist[1])                  // 2D has nCol
        See "1D: "+ nRow +"x"+ nCol +nl  
            for i = 1 to nRow                  // 1D has No Col
                See ""+ arrayList[i] +" "  
            next
        Return  
    ok
       
    nCol = len(arraylist[1])  
    See "2D: "+ nRow +"x"+ nCol +nl  
    for subList in arrayList
       for i = 1 to len(subList)
           See ""+ subList[i] +" "  
       next
       See nl
    next  
Return 

// =================================
// ================================================
// Global: $RangeMth = 12  Use pList
// MMC 207.13	211.16	null	null	null


Func CalcPerformance()

    pList = tList  // Performance

    // --- Fix zero / " null" start-column prices across the whole aList first ---
    // (Same safety-net the original Momentum calc used, now shared by all algorithms)
    k = 1
    for Row in aList
        if not subStr( Row[1], "Date" )
            for i = $RangeMth +2 to len(Row)
                if Row[i -$RangeMth] = 0
                   Row[i -$RangeMth] = 1
                   See "aList: k: "+ k +" i: "+ i +nl
                ok
            next
        ok
        k++
    next

See nl+"CalcPerformance: Algorithm: "+ $Algorithm +nl

    if $Algorithm = "Composite (blend)"
        CalcPerformance_Composite()
    else
        //--- All other single-formula algorithms share this loop ---
        k = 1
        for Row in aList                              // Row array data

###	    See "Row[1] "+ Row[1] +nl
	        if subStr( Row[1], "Date" )
	            See "CalcPerf Row[1]: " + Row[1] +nl

	        else

                for i = $RangeMth +2 to len(Row)

                    Perf = ScoreByAlgorithm($Algorithm, Row, i)
                    pList[k][i] = Perf

                next
            ok

            k++
        next
    ok

See nl

if DebugpList = 1
    See nl+"<----- Debug Performance pList: $RangeMth: "+ $RangeMth +" Algorithm: "+ $Algorithm +" ----->"+nl
    DebugArray(pList)
ok

Return

// ================================================
// Dispatch a single stock/column score based on the selected Algorithm.
// Row     = one stock's price row  (Row[1] = Symbol, Row[2..] = prices oldest->newest)
// i       = current column index (End column)
// Returns a numeric "score" — for Momentum-style algos this is a ratio (>1 = up),
// for the others (MACD, Sharpe, MA-Cross) it is a signed score where higher = better.
// Whichever score is returned, SortPerformance() ranks High-to-Low, so "higher = better"
// must hold for every algorithm.

Func ScoreByAlgorithm(cAlgo, Row, i)

    if      cAlgo = "All-Pairs Momentum"
        return ScoreAllPairs(Row, i)
    elseif  cAlgo = "Avg Momentum (all months)"
        return ScoreAvgMomentum(Row, i)
    elseif  cAlgo = "Moving Average Cross"
        return ScoreMA(Row, i)
    elseif  cAlgo = "MACD"
        return ScoreMACD(Row, i)
    elseif  cAlgo = "Sharpe Momentum"
        return ScoreSharpe(Row, i)
    elseif  cAlgo = "Pullback from High"
        return ScorePullback(Row, i)
    else   // "Momentum (original)" and fallback default
        return ScoreMomentum(Row, i)
    ok

Return 0

// ================================================
// Safe price lookup: treats missing columns, 0, and " null" (bad Yahoo data) as invalid (0)

Func PriceAt(Row, col)

    if col < 2  return 0  ok
    if col > len(Row)  return 0  ok

    v = Row[col]
    if v = " null"  return 0  ok
    if v = 0        return 0  ok

Return v

// ================================================
// 1. Momentum (original):  price[now] / price[RangeMth ago]

Func ScoreMomentum(Row, i)

    R      = $RangeMth
    pStart = PriceAt(Row, i - R)
    pEnd   = PriceAt(Row, i)

    if pStart = 0 or pEnd = 0  return 1  ok    // Same "Perf = 1" fallback as original

Return pEnd / pStart

// ================================================
// 1b. Pullback from High:  Momentum (original) ratio, penalized by how far
//     price[now] sits below its recent high over the same RangeMth window.
//     base   = (price[now] / price[RangeMth ago]) - 1        (excess momentum, 0 = flat)
//     penalty= 2 * [ (MaxHigh(last RangeMth) / price[now]) - 1 ]   (0 if at the high,
//              doubled so pullbacks drag the score down twice as hard)
//     score  = base - penalty
//     MaxHigh = highest price seen across the window i-R .. i (inclusive of "now").

Func ScorePullback(Row, i)

    R      = $RangeMth
    pStart = PriceAt(Row, i - R)
    pEnd   = PriceAt(Row, i)

    if pStart = 0 or pEnd = 0  return 1  ok    // Same "Perf = 1" fallback as original

    maxHigh = 0
    for k = 0 to R
        pRef = PriceAt(Row, i - k)
        if pRef > maxHigh
            maxHigh = pRef
        ok
    next

    if maxHigh = 0  return 1  ok

    base    = (pEnd / pStart) - 1
    penalty = 2 * ( (maxHigh / pEnd) - 1 )

Return base - penalty

// ================================================
// 2. Avg Momentum (all months):  mean( price[now] / price[each prior month in window] )

Func ScoreAvgMomentum(Row, i)

    R    = $RangeMth
    pEnd = PriceAt(Row, i)
    if pEnd = 0  return 0  ok

    total = 0
    cnt   = 0
    for k = 1 to R
        pRef = PriceAt(Row, i - k)
        if pRef != 0
            total += (pEnd / pRef)
            cnt++
        ok
    next

    if cnt = 0  return 0  ok

Return total / cnt

// ================================================
// 3. All-Pairs Momentum:  price[RangeMth ago] (baseline) vs every subsequent month, averaged

Func ScoreAllPairs(Row, i)

    R     = $RangeMth
    pBase = PriceAt(Row, i - R)
    if pBase = 0  return 0  ok

    total = 0
    cnt   = 0

    for k = R -1 to 1 step -1
        pRef = PriceAt(Row, i - k)
        if pRef != 0
            total += (pRef / pBase)
            cnt++
        ok
    next

    pEnd = PriceAt(Row, i)
    if pEnd != 0
        total += (pEnd / pBase)
        cnt++
    ok

    if cnt = 0  return 0  ok

Return total / cnt

// ================================================
// Helper: mean of a numeric list

Func ListMean(aVals)

    if len(aVals) = 0  return 0  ok
    total = 0
    for v in aVals  total += v  next

Return total / len(aVals)

// ================================================
// Helper: population std-dev of a numeric list, given its mean

Func ListStdDev(aVals, mu)

    n = len(aVals)
    if n < 2  return 0  ok

    sumSq = 0
    for v in aVals
        sumSq += pow(v - mu, 2)
    next

Return sqrt(sumSq / n)

// ================================================
// Helper: Exponential Moving Average of a price window (oldest first)

Func EMA(aVals, span)

    if len(aVals) = 0  return 0  ok

    alpha = 2.0 / (span + 1)
    ema   = aVals[1]

    for idx = 2 to len(aVals)
        ema = alpha * aVals[idx] + (1 - alpha) * ema
    next

Return ema

// ================================================
// Helper: build a clean (non-zero) price window [startCol..i] from a Row

Func PriceWindow(Row, startCol, i)

    aWin = []
    if startCol < 2  startCol = 2  ok

    for c = startCol to i
        v = PriceAt(Row, c)
        if v != 0  aWin + v  ok
    next

Return aWin

// ================================================
// 4. MACD-inspired score:  fast EMA (RangeMth/3, min 3) minus slow EMA (RangeMth),
//    normalised by the slow EMA so it reads as a relative % rather than $.

Func ScoreMACD(Row, i)

    R = $RangeMth
    fastSpan = R / 3
    if fastSpan < 3  fastSpan = 3  ok
    slowSpan = R

    aWin = PriceWindow(Row, i - (slowSpan *2), i)

    if len(aWin) < slowSpan
        return ScoreMomentum(Row, i)
    ok

    emaFast = EMA(aWin, fastSpan)
    emaSlow = EMA(aWin, slowSpan)

    if emaSlow = 0  return 0  ok

Return (emaFast - emaSlow) / emaSlow

// ================================================
// 5. Sharpe Momentum:  mean monthly return / std-dev of returns over the window
//    (risk-adjusted momentum — penalises volatile spikes)

Func ScoreSharpe(Row, i)

    R = $RangeMth
    aWin = PriceWindow(Row, i - R, i)

    if len(aWin) < 3
        return ScoreMomentum(Row, i)
    ok

    aRets = []
    for idx = 2 to len(aWin)
        if aWin[idx -1] != 0
            aRets + ( (aWin[idx] - aWin[idx -1]) / aWin[idx -1] )
        ok
    next

    if len(aRets) < 2
        return ScoreMomentum(Row, i)
    ok

    mu = ListMean(aRets)
    sd = ListStdDev(aRets, mu)

    if sd = 0  return 0  ok

Return mu / sd

// ================================================
// 6. Moving Average Cross:  how far (%) current price is above/below its own
//    rolling mean over the window

Func ScoreMA(Row, i)

    R = $RangeMth
    aWin = PriceWindow(Row, i - R, i)

    if len(aWin) = 0  return 0  ok

    ma   = ListMean(aWin)
    pNow = PriceAt(Row, i)

    if ma = 0 or pNow = 0  return 0  ok

Return (pNow - ma) / ma

// ================================================
// Helper: percentile-rank normalise a list of scores to [~0,1] (higher score -> higher rank)
// Ties are NOT averaged (simple stable ordering) — close enough for blend purposes.

Func RankNorm(aVals)

    n = len(aVals)
    aResult = list(n)
    if n = 0  return aResult  ok

    aIdx = []
    for idx = 1 to n  aIdx + idx  next

    // Simple selection sort of indices by value, ascending
    for a = 1 to n -1
        for b = a +1 to n
            if aVals[ aIdx[b] ] < aVals[ aIdx[a] ]
                temp     = aIdx[a]
                aIdx[a]  = aIdx[b]
                aIdx[b]  = temp
            ok
        next
    next

    for rankPos = 1 to n
        origIdx = aIdx[rankPos]
        aResult[origIdx] = rankPos / n
    next

Return aResult

// ================================================
// 7. Composite (blend):  equal-weight rank-average of Momentum + Sharpe + MACD +
//    Moving-Average-Cross + Avg-Momentum.  This one is cross-sectional (needs every
//    stock's score for a given column before it can rank them), so it loops
//    column-major instead of row-major like the other algorithms.

Func CalcPerformance_Composite()

    for i = $RangeMth +2 to len(aList[1])

        aMom    = []
        aAvgMom = []
        aMacd   = []
        aSharpe = []
        aMA     = []
        aRowOk  = []          // Track which rows are valid (not a "Date" row)

        for Row in aList
            if subStr( Row[1], "Date" )
                aRowOk  + 0
                aMom    + 0
                aAvgMom + 0
                aMacd   + 0
                aSharpe + 0
                aMA     + 0
            else
                aRowOk  + 1
                aMom    + ScoreMomentum(Row, i)
                aAvgMom + ScoreAvgMomentum(Row, i)
                aMacd   + ScoreMACD(Row, i)
                aSharpe + ScoreSharpe(Row, i)
                aMA     + ScoreMA(Row, i)
            ok
        next

        rMom    = RankNorm(aMom)
        rAvgMom = RankNorm(aAvgMom)
        rMacd   = RankNorm(aMacd)
        rSharpe = RankNorm(aSharpe)
        rMA     = RankNorm(aMA)

        k = 1
        for Row in aList
            if aRowOk[k] = 1
                pList[k][i] = ( rMom[k] + rSharpe[k] + rMacd[k] + rMA[k] + rAvgMom[k] ) / 5.0
            ok
            k++
        next

    next

Return

// ===============================================
// sList --- Sort(pList, nColumn, cAttribute)

Func SortPerformance()

    nList  = tList   // Name List sorted by Rank
    
    for nCol = $RangeMth +2 to len(pList[1])     // Performance List
        sList = Reverse( Sort(pList, nCol) )     // High to Low Sort List
        
        
            //--- Debug aList 2D Display ------
            //See "<=====> nCol: "+ nCol +nl

            k = 1                                // k nList Row 
            nList[k][1] = aList[k][1]
            
            for subList in sList
                //See ""+ subList[1] +tab+ subList[nCol] +"   "  
                nList[k][1]    = aList[k][1]                  // Name in Col-1
                nList[k][nCol] = subList[1]                   // Sorted Name in Rest of Cols
                
                //See "nList: k: "+ k +" nCol: "+ nCol +" "+ nList[k][nCol] +nl
                k++
            next
            
    next

if DebugnList = 1    
    See nl+"<----- Debug Name nList ----->"+nl
    DebugArray(nList)
ok

Return

// ================================================
// Fill in Rank 1..10.. .. 100 based on nList position of Symbol
// Find(List,ItemValue,nColumn,cAttribute) ---> Item Index

Func GenerateRank()

    rList  = tList  // Rank List
  
    k = 1
    for Row in rList
        for nCol = 2 to len(Row)

            itemName = rList[k][1]
            pos = Find( nList, itemName, nCol)
     
            rList[k][nCol] = pos       // Rank number
            
        next
        k++
    next
    
if DebugrList = 1   
    See nl+"<----- Debug Rank rList  ----->"+nl
    DebugArray(rList)
ok   
    
Return

// ================================================
// Buy stock in rList  if Rank  <= $Top10

Func BuyRank()

    bList = tList    // Buy List with Price
  
    Vert = len(bList)     // Row
    Horz = len(bList[1])  // Col
    
    //--- Do by Col in each Row -------
    for nCol = $RangeMth +2 to Horz
    
        //See nl+"<----- nCol "+ nCol +" ----->"+nl
        for nRow = 1 to Vert 
        

            Rank = rList[nRow][nCol] 
            if  Rank <= $Top10                  // <= 10
              
                BuyStock = rList[nRow][1]     // Col-1 = Name
                BuyPrice = aList[nRow][nCol]
                BuyWeek  = nCol
                
                bList[nRow][nCol] = BuyPrice
              
                //See "Buy: "+ BuyStock +tab+ BuyPrice +tab+ nCol +nl             
            ok
        
        next
    next


if DebugbList = 1   
    See nl+"<----- Debug BuyPrice bList  ----->"+nl
    DebugArray(bList)   
ok  

Return

// ================================================
// Gain = bList -- Buy at nCol See at nCol +1
 
Func CalcGain()

    gList = tList    // Gain List %gain

    Vert = len(gList)     // Row gList Gains
    Horz = len(gList[1])  // Col gList Gains
    
    //--- Do by Col in each Row -------
    for nCol = $RangeMth +2 to Horz -1         // Stop short Horz -1
    
        //See nl+"<----- nCol "+ nCol +" ----->"+nl
        for nRow = 1 to Vert 
        

            if  bList[nRow][nCol] > 0        // Has a Buy Price
       
               //See "Debug: Sym: "+ bList[nRow][1] +" nRow: "+ nRow +" nCol: "+ nCol +nl 
      
                stock     = bList[nRow][1]
                buyPrice  = bList[nRow][nCol]
                sellPrice = aList[nRow][nCol+1]
                Gain      = sellPrice / buyPrice
                
                gList[nRow][nCol] = gain
              
			    //--- Gain Details Printout --
				if DebugGDList  = 1
                    See "Gain: "+ Stock +tab+ nRow +tab+ nCol +tab+ buyPrice +tab+ sellPrice +tab+ Gain  +nl  
				ok	
            ok
        
        next
    next    

if DebugGList = 1   
    See nl+"<----- Debug Gain Percent gList  ----->"+nl
    DebugArray(gList)   
ok  
 
 
// ================================================ 
// Avg Gain for each nCol -- mList from gList
// mList 1 Row and 1 Col Bigger for Summation

Func MonthlyGain() 
 
    //--- Bigger by 1 Summation Add Symbol-----
    mList = List( len(aList) +1, len(aList[1] +1) )    
    
    k = 1
    for Row in aList
        mList[k][1] = aList[k][1]     // Copy Symbols
        k++
    next
        mList[k][1] = "TOT"           // ADD tp Last Row
    
    //--- Compound Calc same size as Monthly Gain ------
    
    cList = mList

    //==============================    

    Vert = len(gList)     // Row GAINS gList = 6
    Horz = len(gList[1])  // Col GAINS gList = 11
    
   //--- Do SUM Col in each Row -------
   for nCol = $RangeMth +2 to Horz          
   
       //See nl+"<----- nCol "+ nCol +" ----->"+nl
       sumCol = 0
       for nRow = 1 to Vert 
              sumCol += gList[nRow][nCol]  
       next
           
       mList[nRow][nCol] = sumCol / $Top10  
   next    
    

    //--- Do by SUM Row in each col -------
    for nRow = 1 to Vert          
    
        //See nl+"<----- nRow "+ nRow +" ----->"+nl
        sumRow = 1       // Mutiply 
        countEntry = 0
        
        for nCol = $RangeMth +2 to Horz 
            if gList[nRow][nCol] != 0           
                sumRow *= gList[nRow][nCol]  // MULTIPLY Compound on Row for this Stock
                countEntry++
                
            ok              
        next
            if countEntry = 0  countEntry = 1  ok
            if sumRow = 1      sumRow = 0      ok
            mList[nRow][nCol] = sumRow            
    next



    //-------------------------------------
    
    Vert = len(mList)     // Last Row 7
    Horz = len(mList[1])  // Last Col 12    

    nRow = Vert           
    nCol = Horz           
    
    //--------------------------------------
    
    //--- SUM Bottom Row -----
    RowTotal = 0
    for k = 2 to nCol                         // Skip $Symbol col-1
        RowTotal += mList[nRow][k] 
    next
    
    //--- SUM Last Col -----
    ColTotal = 0
    for k = 1 to nRow
        ColTotal += mList[k][nCol]  
    next

    //--------------------------------------    
    mList[nRow][nCol] = RowTotal   //  Total of Each Period
    
    //--------------------------------------

if DebugMList = 1   
    See nl+"<----- Debug Average Gain Percent COL, Compount for Row Stock  mList  ----->"+nl
    DebugArray(mList)
        
    See "Avg Stock: Row: "+ RowTotal +nl
    See "Sum Indiv: Col: "+ ColTotal +nl
ok  
    
    //--------------------------------------
       
Return

// ===============================================
// ================================================ 
// cList = Compoud gains by Periods by Col and Row
//         Col = Period All Stocks, Row = by One Stock

Func  Compounding()  

    // cList = mList from   MontlyGain()    
    //-----------------------------
    
    Vert = len(cList)     // Last Row 7
    Horz = len(cList[1])  // Last Col 12    

    nRow = Vert           
    nCol = Horz
    
    cList[nRow][1] ="TOT"
    
    //--------------------------------------
    
    //--- COMPOUND Bottom Row multiply -----
    CompoundRow = 1
    for k = $RangeMth +2 to nCol-1
    
        if mList[nRow][k] != 0
           CompoundRow   *= mList[nRow][k]   // MULTIPLy
           cList[nRow][k] = CompoundRow
        ok
    next
                
    
    //--- COMPOUND Last Col multiply -----
    CompoundCol = 1
    for k = 1 to nRow-1
    
        if mList[k][nCol] != 0
            CompoundCol    = mList[k][nCol]  // ADD PLUS stock already compounded
            cList[k][nCol] = CompoundCol
        ok          
    next    

    //---------------------------------
    
    cList[nRow][nCol] = CompoundRow          // TOT
        
    //--------------------------------------

if DebugCList = 1   
    See nl+"<----- Debug Compound Gain Percent cList  ----->"+nl
    DebugArray(cList)
ok  


    
    //--------------------------------------
    
    CompoundQQQ =   aList[1][nCol-2]  / aList[1][$RangeMth+2]
    
    See "RangeMth: "+ $RangeMth +" Top: "+ $Top10 +" QQQ " + CompoundQQQ +"  "+ CompoundRow +nl
            
    //--------------------------------------        
        
Return


// ================================================
// ================================================  
// Summary Stock compounded        Compount for Row-last  mList

Func SummaryStock()  

    //See "<===== Summary Stock Compounded =====>"+nl

    nRow = len(mList)         
    nCol = len(mList[1])   

    aSumStock = list(3, len(mList) )       // Col = nRow ex: 1 QQQ   6.29


    for k = 1 to nRow   
        //See ""+ k +" "+ mList[k][1] +tab+ mList[k][nCol] +nl

        aSumStock[1][k] = k                // Position
        aSumStock[2][k] = mList[k][1]      // Symbol
        aSumStock[3][k] = mList[k][nCol]   // Value-compound
        
    next

    if DebugSCList = 1   
        See nl+"<----- Debug Summary Stock - Compounded  ----->"+nl
        DebugArray(aSumStock)
    ok 

Return


// ================================================
// ================================================ 
// Show Last $Top10 for last 10 Periods nList
// SELL below -xx%  -12


Func ShowTop10() 

    nRow = len(nList)        // 62
    nCol = len(nList[1])     // 122
	
	// $Top10 = Rows = 10
	// $Top10 = Cols = 10
	// nCol-9 to nCol
	
	$TopColWidth = 13                         // Cols in $Top10 RxC = 10x10
	$TopColStart = nCol - $TopColWidth +1
    
       
	//--- 2 More Rows for QQQ and SPY reference -------
    //See "$Top10 rows: "+ $Top10 +nl
	
    aShowTop10 = List($Top10, $TopColWidth)   // Rows x Cols MAKE LIST SIZE Row=NbrStocks  Col=Cells
    
	//--- COPY Last 10 entried from Name nList -------------
	//--- LAST Entry is Today, 2nd Last is Start of Month
	
    k =1 m =1                                // Small Array Cells
    for v = 1 to $Top10                      // k= Rows in Small Array Rows
        for h = $TopColStart to nCol         // m= Cols in Small Array Rows 
		
            aShowTop10[k][m] = nList[v][h]   // 
		
            m++
        next
        k++
        m =1   // Reset
    next
	
//See "$Top10: k:"+k +" m:"+m +" v:"+v +" h:"+h +nl	
//DebugArray(aShowTop10)
	

	
	//---------------------------------------------------------------
	// Buy Prices for Top10 in 2nd Last nCol = Prev Month
	// NOTE: If Symbol was Not Bought Prev Month -- Use aList Prices shows 0
	//       USE aList to get price no matter what
	// Use 2nd LAST  sCols=last	|| Except 01/mm/yyyy aTimeStamp
	 
	sRows = len(aShowTop10)
	sCols = len(aShowTop10[1])
	bRows = len(bList)
	bCols = len(bList[1])

	cRows = len(aClosedPrices)
	cCols = len(aClosedPrices[1])	
	
	alastDate = split(lastDate,"/")     // 15/03/2026 global
	See "aLastDate: "+ alastDate[3] +"-"+ alastDate[2] +"-"+ alastDate[1] +"  "+ Time() +nl

	See "Sym:      PreMOp:   CurMOp:   NowCl:    $ChgNow:   Pct%  Shares" +nl

	// Build complete HTML table in one string, append once after loop  -15%  -12%
	cT  = "<table cellspacing='0' cellpadding='0'>"
	cT += "<tr>"
	cT += "<td width='50'><b>Sym</b></td>"
	cT += "<td width='80' align='right'><b>CurMOp</b></td>"
	cT += "<td width='70' align='right'><b>NowCl</b></td>"
	cT += "<td width='75' align='right'><b>ChgNow</b></td>"
	cT += "<td width='60' align='right'><b>Pct%</b></td>"
	cT += "<td width='60' align='right'><b>Drop%</b></td>"
	cT += "</tr>"

	AvgSum     = 1
	TotalValue = 0  // Shares * CurPrice
	AvgValue   = 1  // Avg Stock Value

	// --- Weekly Stop-Sell hook: rebuild this month's Top-10 buy basket ---
	aTop10Symbols  = []
	aTop10BuyPrice = []
	aTop10BuyDate  = []
	aTop10NowPrice = []
	aTop10Shares   = []
	cBuyMonthKey   = "01/" + alastDate[2] + "/" + alastDate[3]   // e.g. "01/07/2026"

	for s = 1 to sRows                          // Each Symbol
	
	    itemName =  aShowTop10[s][sCols-1]      // Use 2nd LAST  sCols=last	|| Except 01/mm/yyyy aTimeStamp
		
		if alastDate[1] = "01"
		   itemName =  aShowTop10[s][sCols-1]
		ok
		  
		
        posA     =  FIND( aList, itemName, 1)           // aList         Search Col-1
		posC     =  FIND( aClosedPrices, itemName, 1)   // aClosedPrices Search (live-download only, see below)
		
		// fix 2026-Aug-23: aClosedPrices is only populated during a LIVE
		// GetQuotes() download and is never actually read for its values
		// below (NowPrice/CurMonthPr both come from aList) -- it was only
		// used as an existence check. Requiring posC != 0 made every Top10
		// row disappear when running offline from a saved CSV, since
		// aClosedPrices is empty in that case. Only aList (posA) is needed.
		if posA = 0
		   See "FIND(): "+ itemName +" NOT Found: PosA= "+ posA +" PosC= "+ posC  +nl
		   
		else
		    //---Chg since start of 01-Month -----------------------
            // <<<=== FIX===>>> on 10 year reange -Use Current aList Prices ----------

		    ChgPr1    = aList[posA][bCols]  - aList[posA][bCols-1]    
		    ChgPct1   = aList[posA][bCols]  / aList[posA][bCols-1] * 100 -100
		    NowPrice  = aList[posA][bCols] 			
			
			CurMonthPr = aList[posA][bCols-1]
		    NbrShares  = ceil( $Dollars / CurMonthPr )   // SHARES on $10,000 investment
		   
		   	TotalValue += NbrShares * NowPrice 
            AvgValue    = TotalValue / sRows			
		    AvgSum     += ChgPct1 

			// --- Weekly Stop-Sell hook: record this symbol's monthly buy ---
			Add(aTop10Symbols,  itemName)
			Add(aTop10BuyPrice, CurMonthPr)
			Add(aTop10BuyDate,  cBuyMonthKey)
			Add(aTop10NowPrice, NowPrice)
			Add(aTop10Shares,   NbrShares)
		   
            See ""+ PadR( 5, itemName)             +" "    // itemName in bList BuyList
		    See ""+ PadL( 9, aList[posA][bCols-2]) +" "    // PrevMonth
			See ""+ PadL( 9, aList[posA][bCols-1]) +" "    // CurMonth
			See ""+ PadL( 9, NowPrice)             +" "    // Now Price				   				   
			See ""+ PadL( 9, ChgPr1)               +" "    // Change Price
			See ""+ PadL( 9, ChgPct1)              +" "    // Pct%		
			See " ("+ NbrShares +")"                       // Nbr Shares
			if ChgPct1 <= sellBelow                        // -12% SELL
			   See " SELL"
			ok
			See nl

			// Accumulate each row into HTML table string
			// Color negative values red
			cChgColor = ""
			cPctColor = ""
			if ChgPr1  < 0   cChgColor = " style='color:red;'"   ok
			if ChgPct1 < 0   cPctColor = " style='color:red;'"   ok

			cT += "<tr>"
			cT += "<td width='50'>" + itemName + "</td>"
			cT += "<td width='80' align='right'>" + NumFmt(aList[posA][bCols-1]) + "</td>"
			cT += "<td width='70' align='right'>" + NumFmt(NowPrice)  + "</td>"
			cT += "<td width='75' align='right'"+ cChgColor +">" + NumFmt(ChgPr1)  + "</td>"
			cT += "<td width='60' align='right'"+ cPctColor +">" + NumFmt(ChgPct1) + "</td>"
			if ChgPct1 <= sellBelow  
			   cT += "<td width='60' align='right'"+ cPctColor +">" + "SELL" + "</td>"
			ok
			cT += "</tr>"
					
	    ok
	next

	cT += "</table>"
	txtLog.append(" ")
	txtLog.append(cT)
	txtLog.append(" ")
	
	See nl+"TotalValue: "+ TotalValue +" AvgValue: "+ AvgValue +" AvgPct: "+ (AvgSum / sRows) +nl
	
	AvgValue = AvgSum / sRows
	See nl+"Average Result: NbrStock: "+ sRows +" AvgValue:  "+ AvgValue +nl
	
	txtLog.append("AVG Pct:" +tab+ AvgValue)
	
	// -----------------------------------------
	// -----------------------------------------
	    itemName = "QQQ"
        pos      =  FIND( aList, itemName, 1)   // aList Search Col-1, Pos = Row Nbr 
		
		if pos = 0 
		   See "FIND(): "+ itemName +" NOT Found: "+ " Pos= "+ pos +nl
		   
		else
		   ChgPr1  = aList[pos][bCols] - aList[pos][bCols-1]        // Chg since start of 01-Month
		   ChgPct1 = aList[pos][bCols] / aList[pos][bCols-1] * 100 -100		   
		   
           See ""+ itemName +tab+ 
		           aList[pos][bCols-2] +tab+    // bList
				   aList[pos][bCols-1] +tab+ 
				   aList[pos][bCols]   +tab+ 
				   ChgPr1  +tab+ 
				   ChgPct1 +nl
				   
				   txtLog.append("QQQ Pct:" +tab+ ChgPct1)
	    ok

	// -----------------------------------------
	// -----------------------------------------
	
	    itemName = "SPY"
        pos      =  FIND( aList, itemName, 1)   // aList Search Col-1, Pos = Row Nbr 
		
		if pos = 0 
		   See "FIND(): "+ itemName +" NOT Found: "+ " Pos= "+ pos +nl
		   
		else
		   ChgPr1  = aList[pos][bCols] - aList[pos][bCols-1]        // Chg since start of 01-Month
		   ChgPct1 = aList[pos][bCols] / aList[pos][bCols-1] * 100 -100		   
		   
           See ""+ itemName +tab+ 
		           aList[pos][bCols-2] +tab+    // bList
				   aList[pos][bCols-1] +tab+ 
				   aList[pos][bCols]   +tab+ 
				   ChgPr1  +tab+ 
				   ChgPct1 +nl
				   
				   txtLog.append("SPY Pct:" +tab+ ChgPct1)
	    ok		

	//--------------------------------------
	
	
cellNbr  = len(aSumTotal[3]) -1         //  FIX -1
$maxQQQ  =     aSumTotal[2][cellNbr]
$maxTOT  =     aSumTotal[3][cellNbr]
if len(aSumTotal) >= 4
    $maxSPY  = aSumTotal[4][cellNbr]
ok
$Ratio    = ($maxTot -1) / ($MaxQQQ -1)   // Multi-Bagger to Percent Ratio  (vs QQQ)
$RatioSPY = ($maxTot -1) / ($MaxSPY -1)   // Multi-Bagger to Percent Ratio  (vs SPY)

ComputePortfolioStats(cellNbr)    // Sets $CAGR, $Sharpe, $MaxDD  from aSumTotal[3] (TOT series)

	    // ---------------------------------
	    // EpochSecs  = aTimeStamp[len(aTimeStamp)]
	    // DateHuman  = EpochToDate(EpochSecs)
	    // aDateRead  = [""]

        //---------------------------------
		// Add Dates for Cols | 
		
		aDateRead = []
		
		if len(aTimeStamp) > 10
		
		    R = len(aTimeStamp)
		    for S = 1 to  sCols                               // 10 nbr col in aShowTop10	
		        EpochTime  = aTimeStamp[ R -sCols +S ]        // -10 +S ]      // 160 159 158 ...
		    	DateHuman  = EpochToDate(EpochTime)      // 19/07/2025
		    	
				dateDDMM   =  subStr(DateHuman, 1, 6)    // str,pos,count
				
                Add (aDateRead , dateDDMM)               // DateHuman)
		    next
		else
		    //------------------------------------------
		    // fix 2026-Aug-23: GetQuotes was NOT run this session (offline run
		    // using a saved AAA-Spread.csv) so there is no live aTimeStamp.
		    // Rebuild the same date labels from the CSV's own "Date" row
		    // (aCsvDateRow, set in SyncOfflineDateScaffold()) instead of
		    // leaving aDateRead empty -- an empty aDateRead crashes further
		    // below with an Array Access (Index out of range) error.

		    if aCsvDateRow != null
		        nDateCols = len(aCsvDateRow)
		        for S = nDateCols - sCols +2 to nDateCols        // last (sCols-1) saved dates
		            DateHuman = aCsvDateRow[S]                   // "dd/mm/yyyy"
		            dateDDMM  = subStr(DateHuman, 1, 6)          // "dd/mm/"
		            Add (aDateRead , dateDDMM)
		        next
		    ok
		ok	

        //---------------


    if DebugS10List = 1   
        See nl+"<----- Show $Top10 Vertical: Old to New  ----->"+nl
		
	
	    //--- Dates 01/MM ----------------
		for d = 1 to len(aDateRead) - 1          
		    See ""+aDateRead[d] +"  "
		next
		See Date() +" Pct" +nl
		
	
	    //--- Nbrs 12 11 .. 2 1 ------------
		for d = len(aDateRead) - 1 to 1 step -1  
		    See ""+d +tab
		next
		See "Today" +" Pct" +nl		
		
		
		//-----------------------------------------
        // --- SYMBOLS -- DebugArray(aShowTop10) 
		
        for subList in aShowTop10          // Vert
            for i = 1 to len(subList)      // Horz
               See "" + subList[i] +tab    // DO NOT Call DebugArray(), Insert TAB
            next
            See nl
        next	
		
    ok
	
	//---------------------------
	// Months 01/MM Append
	
	txtLog.append(" " )
	txtLog.append("<===== TopTen >>> OLD >>> NEW Periods =====>" )
	
	    monthInfo = ""
		for d = (len(aDateRead) - 4) to (len(aDateRead) - 1)          // Dates 01/MM
		    monthInfo += aDateRead[d] +tab
		next
		    monthInfo += Date() 
	    txtLog.append(monthInfo)


    //------------------------------
	// Symbols matrix Append

    for v = 1 to $Top10 
	
        symInfo = ""
		for d = (len(aShowTop10[1]) - 4) to (len(aShowTop10[1]) - 0)         
		    symInfo += aShowTop10[v][d] +tab
		next
	    txtLog.append(symInfo)	

	next
	
	//-------------------------------

	txtLog.append(" " )	
	txtLog.append( "QQQ: "+ $maxQQQ +" TOT: "+ $maxTOT +" Ratio: "+ $Ratio )
	txtLog.append( "SPY: "+ $maxSPY +" TOT: "+ $maxTOT +" Ratio: "+ $RatioSPY )
	txtLog.append( "CAGR: "+ NumFmt($CAGR *100) +"%  Sharpe: "+ NumFmt($Sharpe) +"  MaxDrawdown: -"+ NumFmt($MaxDD *100) +"%" )
	txtLog.append(">===== TopTen =====<" )	

	
	//=================================
	// Debug HISTORY MONTHLY RESULTS
	
    if DebugHRList  = 1	
		CalcMonthlyRet(aShowTop10)
	ok
	
	//---------------------------------

Return

//=================================================
// COMPUTE PORTFOLIO STATS -- CAGR / Sharpe / Max Drawdown
//
// Mirrors the Python app's backtest() stats block:
//   cagr   = port_compound ** (12 / n_months) - 1
//   sharpe = mean(monthly_ret -1) / std(monthly_ret -1) * sqrt(12)
//   max_dd = biggest peak-to-trough drop of the compounded portfolio curve
//
// Uses aSumTotal[3] (TOT = portfolio compounded value per month), which is
// only valid from index ($RangeMth +2) .. cellNbr  (same window $maxQQQ/$maxTOT use)
// Sets Globals: $CAGR, $Sharpe, $MaxDD   (all as fractions, eg 0.25 = 25%)

Func ComputePortfolioStats(cellNbr)

    $CAGR   = 0
    $Sharpe = 0
    $MaxDD  = 0

    startIdx = $RangeMth + 2
    endIdx   = cellNbr

    if endIdx < startIdx  return  ok

    //--- Collect the valid TOT compounded values -------------------
    aTotVals = []
    for idx = startIdx to endIdx
        Add(aTotVals, aSumTotal[3][idx])
    next

    if len(aTotVals) < 2  return  ok

    //--- Monthly returns:  ratio_i = TOT[i] / TOT[i-1] --------------
    aMoRet = []
    for idx = 2 to len(aTotVals)
        prev = aTotVals[idx -1]
        cur  = aTotVals[idx]
        if prev != 0
            Add(aMoRet, cur / prev)
        ok
    next

    nMonths = len(aMoRet)

    //--- CAGR:  compound ** (12/nMonths) -1 --------------------------
    if nMonths > 0 and $maxTOT > 0
        $CAGR = pow($maxTOT, 12 / nMonths) -1
    ok

    //--- Sharpe:  mean(monthlyRet -1) / stddev(monthlyRet -1) * sqrt(12)
    aExcess = []
    for r in aMoRet
        Add(aExcess, r -1)
    next

    muExcess = ListMean(aExcess)
    sdExcess = ListStdDev(aExcess, muExcess)

    if sdExcess > 0
        $Sharpe = (muExcess / sdExcess) * sqrt(12)
    ok

    //--- Max Drawdown:  biggest peak-to-trough drop of the TOT curve --
    peak = aTotVals[1]
    for v in aTotVals
        if v > peak  peak = v  ok
        if peak > 0
            dd = (peak - v) / peak
            if dd > $MaxDD  $MaxDD = dd  ok
        ok
    next

Return

//=================================================
// CALC RETURNS PER MONTH 
//
// TOP TEN - HORZ and VERT Tickers
// if DebugGDList  = 1   ===>>>      // History Buy Sell Percent Average


Func CalcMonthlyRet(aShowTop10)

    //See nl+nl+"History Tickers Buy Sell Profit:"+nl+nl

	
	nRow  = len(aShowTop10)                    // 10                   
	nCol  = len(aShowTop10[1])                 // 10		
	month = len(aList[1]) - nCol               // 64 -10 = 54  <<<===
     
	aPercent   = list(nRow,nCol)                    // Nbr of Cols
	sumPercent = 0
	
        for Horz = 1 to nCol -1 
		    See nl+"<----- Month " + month +" ----->"+nl
			
			SumPercent = 0.01           // all stocks this month, to find average
			DrawUp     = 0.01
			DrawDown   = 0.01
			
            for Vert = 1 to nRow  
			
		        Ticker =  aShowTop10[Vert][Horz]
						   
		        # ---------------------------------------------------
		        # Last 10 Months -- Get Prices for Start End Month - Gain and Percent
		   			       
		   		posRow   =  FIND( aList, Ticker, 1)        // Search Ticker -- Find Row with data prices
			  
			  
			    if posRow > 0            // Must be a Ticket and not a "0" for 7 out of 12 montds
		            PriceS   =  PadL(8, aList[posRow][month ] 	)   
		            PriceE   =  PadL(8, aList[posRow][month +1] )
				    Diff     =  PadL(8, PriceE - PriceS                 )
				    Percent  =  PadL(8, PriceE / PriceS * 100 -100      )
				    
                    SumPercent += Percent
				    if Percent > DrawUp    DrawUp   = Percent  ok
				    if Percent < DrawDown  Drawdown = Percent  ok
				    
				    //if DebugHList = 1			   
		                See ""+ Horz +"-"+ Vert +" "+ PadR(6,Ticker) +" "+ PriceS +" "+ PriceE +" " +" "+ Diff + Percent  +nl
				    //ok 
				     
				    aPercent[Vert][Horz] = Percent
				ok	
				
		    # --------------------------------
            next
			
			AvgPercent = SumPercent / nRow
			See "Month: "+ month +" AvgPct: "+ AvgPercent +" DrawUp: "+ DrawUp +" DrawDown: "+ DrawDown +nl
							
		    month++
            
        next

        See nl
        DebugArray(aPercent)     // 2D Matrix of Percent for Month for TopTen Stocks
		
		//-------------------------------------------
		// Multiple Months Return 2D: 10x13
		
		aSum    = List(nCol)        // <== Create Horz list for AvgPct for each Month
		aDrawUp = List(nCol)
		aDrawDn = List(nCol)
		
		for Horz = 1 to nCol
		    Sum    = 0.01
			DrawUp = 0.01
			DrawDn = 0.01
			
            for Vert = 1 to nRow
				Sum += aPercent[Vert][Horz]
				  if aPercent[Vert][Horz] > DrawUp  DrawUp = aPercent[Vert][Horz]  ok
				  if aPercent[Vert][Horz] < DrawDn  DrawDn = aPercent[Vert][Horz]  ok
            next
			
			AvgSum     = Sum / nRow
			
			aSum[Horz]    = AvgSum   // Horz list of Sum per Month
			aDrawUp[Horz] = DrawUp    
			aDrawDn[Horz] = DrawDn
		next
		
		See nl		
        //DebugArray(aSum)          // 1D of Avg Perecent by Month
		//DebugArray(aDrawUp)
		//DebugArray(aDrawDown)
		
		//------------------
		See "AvgPct: "
		for i = 1 to nCol
		   See PadR(9,aSum[i]) 
		next
		   See nl
		
		
		// See "DrawUp: "
		// for i = 1 to nCol
		//    See PadR(9,aDrawUp[i]) 
		// next
		//    See nl
		// 
		// See "DrawDn: "
		// for i = 1 to nCol
		//    See PadR(9,aDrawDn[i]) 
		// next		
		//    See nl
		//---------------
		
		TotalSum = 0.01
		for i = 1 to len(aSum)
		    TotalSum += aSum[i]		
		next
		See nl+"Total Sum.: "+ TotalSum +nl
		
		//--------------------------------		
		DrawUpMth = Max(aSum)
		DrawDnMth = Min(aSum)
		
		See "DrawUpMth.: "+ DrawUpMth +nl 
		See "DrawDnMth.: "+ DrawDnMth +nl
		
		//--------------------------------

		Compound = 1
		for i = 1 to nCol -1                      // Last Col = 0		
		    nbr = (aSum[i] + 100 ) / 100          // 10.79 => 110.79 => 1.1079						
		    Compound *= nbr	                     			
		next		
		Compound = (Compound -1 ) *100
		See "Final Cmp.: "+ Compound +nl
		
		//--------------------------------------
	    // Find SPY Results for same Time period	

        itemName = "SPY"
        pos      =  FIND( aList, itemName, 1)   // aList Search Col-1, Pos = Row Nbr 
		
        if pos = 0
            See "SPY pos Not Found"+ nl
        Ok
		
		
		lenSPY = len( aList[pos] )
		oldSPY = aList[pos][ lenSPY - nCol +1]       // 9 ]  nCols ago
		newSPY = aList[pos][ lenSPY ]
		chgSPY = newSpy - OldSPY
		perSPY = newSpy / OldSpy * 100 - 100
		

		See "..SPY Pct.: "+ perSpy  +nl //  +" Old: "+ oldSpy +" New: "+ newSPY +" Chg: "+ chgSPY  +nl
		
		
	    

Return

// ================================================
// ================================================  

// ================================================
// ================================================  
// Summary Total compounded vs QQQ Compound Gain Percent  cList

Func SummaryTotal   
  
    //See "<===== Summary Total Compounded =====>"+nl

    nRow = len(cList)                            // cList = Compound
    nCol = len(cList[1])    
    
    aSumTotal       = list(4, len(cList[1]) )    // CREATE List 4 x NbrStocks -- Nbr::QQQ::TOT::SPY each period
    aSumTotal[1][1] = "NBR"                           
    aSumTotal[2][1] = "QQQ"
    aSumTotal[3][1] = "TOT"
    aSumTotal[4][1] = "SPY"
        

    //--- TOT Compounded from cList[nRow][k] -----

    TCmp  = 1
    QInit = aList[1][$RangeMth +2]                   // QQQ  row 1
    SInit = aList[2][$RangeMth +2]                   // SPY  row 2
	
    //See "QInit: "+ QInit +nl

    for k = $RangeMth + 2 to nCol -1    // FIX  -1 
        QChg = aList[1][k] / QInit               // QQQ  row 1      
        SChg = aList[2][k] / SInit               // SPY  row 2
        TCmp = cList[nRow][k]                    // TOT  row last
                
        //See ""+ k +" TOT: "+ TCmp  +"  QQQ: "+ QChg +"  SPY: "+ SChg +nl

        aSumTotal[1][k] = k  -1               // Position
        aSumTotal[2][k] = QChg             // QQQ   cmp
        aSumTotal[3][k] = TCmp             // Total cmp
        aSumTotal[4][k] = SChg             // SPY   cmp
    
    next
        aSumTotal[3][nCol-1] = aSumTotal[3][nCol-2] // Force last entry to match QQQ
        aSumTotal[4][nCol-1] = aSumTotal[4][nCol-2] // Force last entry to match SPY

    if DebugTCList = 1   
        See nl+"<----- Debug Total - Compounded  ----->"+nl
        DebugArray(aSumTotal)
    ok 

Return


// ================================================
// NumFmt() = Always format number to exactly 2 decimal places
// 536 => "536.00"   -14.4 => "-14.40"   32.46 => "32.46"

Func NumFmt( n )
    n       = 0+ n              // ensure numeric
    cSign   = ""
    if n < 0   cSign = "-"   n = -n   ok
    nInt    = floor(n)
    nFrac   = n - nInt
    nCents  = floor(nFrac * 100 + 0.5)   // round
    if nCents >= 100   nInt++   nCents = 0   ok
    cCents  = string(nCents)
    if len(cCents) = 1   cCents = "0" + cCents   ok
    return cSign + string(nInt) + "." + cCents

// ================================================
// PADL() = Pad Left -- Add spaces on Left Side

Func PadL( padn, item )         

    padn     = 0+  Padn        // to number
    item     = ""+ item        // to string   
    lenItem  = len(item)          
    fillNbr  = padn - lenItem       
    if fillNbr <= 0 
       See nl+"Err: PadL Nbr <=0: "+ fillnbr +nl
	   return item
    ok
  
    newItem  = Space(fillNbr) + item

Return newItem


// ================================================
// PADR() = Pad Right -- Add spaces on Right Side

Func PadR( padn, item )         

    padn     = 0+  Padn         // to number
    item     = ""+ item         // to string   
    lenItem  = len(item)          
    fillNbr  = padn - lenItem    
	
    if fillNbr <= 0 
       See nl+"Err PadR Nbr <=0: "+ fillnbr +nl
	   return item
    ok
  
    newItem  = item + Space(fillNbr) 

Return newItem

// ================================================


// ================================================
// ================================================
// ================================================
//
// DrawChartQT()
//    aSumTotal[1][1] = "NBR"                           
//    aSumTotal[2][1] = "QQQ"
//    aSumTotal[3][1] = "TOT"
//
# 2. Generate QML file content dynamically
# -------------------------------------------------
		
Func DrawChartQT(aSumTotal)		

cellNbr  = len(aSumTotal[3]) -1
$maxQQQ  =     aSumTotal[2][cellNbr]
$maxTOT  =    (aSumTotal[3][cellNbr]) * 1.50  // Vertical Bigger by 10%
$realTot = ($maxTOT * 10 / 15.0 )
$nameTot = "TOT:"+ $realTot 

$Ratio   = ($realTot -1)  / ($MaxQQQ -1)   // Multi-Bagger to Percent Ratio

See nl+"QQQ: "+ $maxQQQ +"  TOT: "+ $realTot +" Ratio: "+ $Ratio +nl		
		
cQMLContent = '
    import QtQuick 2.0
    import QtCharts 2.0

ChartView {
    id: chart
    width:               900
    height:              700
    theme:               ChartView.ChartThemeLight
    antialiasing:        true
    backgroundColor:    "white"
    title:              "Performance Comparison: Index (QQQ) vs Portfolio (TOT)"
    titleFont.pixelSize: 22
    titleFont.bold:      true
    legend.alignment:    Qt.AlignBottom
    
        // X-axis (Days) ------------------			
        ValueAxis {
        id:                   axisX
        min:                  0
        max:                  ' + (len(aSumTotal[2]) - 1) + ' 
        titleText:           "Periods"
        titleFont.pixelSize:  14
        labelsFont.pixelSize: 12
        gridVisible:          true
        minorGridVisible:     true
        color:               "#333333"
        }

        // Y-axis (Cumulative Return %) ----------------
        ValueAxis {
        id:                   axisY
        min:                  0                     
        max:                  ' + $maxTOT + '      
        titleText:           "Cumulative Return (%)"
        titleFont.pixelSize:  14
        labelsFont.pixelSize: 12
        gridVisible:          true
        minorGridVisible:     true
        color:               "#333333"
        }

        // First series: QQQ (Blue) ---------------
        LineSeries {
        name:  "QQQ"
        axisX:  axisX
        axisY:  axisY
        width:  3
        color: "#4A90E2"
'
        # Add QQQ points dynamically  aSumTotal[2][1] = "QQQ"
        # Start from 2 because element 1 is the name "QQQ"
		
        for i=2 to len(aSumTotal[2]) -2          
            xVal         = i-2
            yVal         = aSumTotal[2][i]    
            cQMLContent += ' XYPoint { x: ' + xVal + '; y: ' + yVal + ' }' + nl
        next

        cQMLContent += '    
		}

        // Second series: TOT (Orange) --------------
        LineSeries {
        name:  "$TOT"
        axisX:  axisX
        axisY:  axisY
        width:  3
        color: "#FF6B35"
'

        # Add TOT points dynamically aSumTotal[3][1] = "TOT"
        for i=2 to  len(aSumTotal[3]) -2          // len(aLineTOT)
            xVal         = i-2
            yVal         = aSumTotal[3][i]        // aLineTOT[i]
            cQMLContent += ' XYPoint { x: ' + xVal + '; y: ' + yVal + ' }' + nl
        next

        cQMLContent += '    
		}
		
       // Third series:(Black Base Line) ---------------
        LineSeries {
        name:  "Base=1"
        axisX:  axisX
        axisY:  axisY
        width:  1
        color: "#0000FF"
'
        # Add Base=1 points dynamically  aSumTotal[2][1] = "QQQ"
        # Start from 2 because element 1 is the name "QQQ"
		
        for i=2 to len(aSumTotal[2]) -2          
            xVal         = i-2
            yVal         = 1        // FIXed Value:  aSumTotal[2][i]    
            cQMLContent += ' XYPoint { x: ' + xVal + '; y: ' + yVal + ' }' + nl
        next

        cQMLContent += '    
		}		
		
		
}
'

# 3. Save generated QML file
# -----------------------------------------------------

        write("stock_chart.qml", cQMLContent)


# 4. Run the application and display the chart
# -----------------------------------------------------

new qApp {
    w = new qWidget() {
        setWindowTitle("Stock Analysis Result") 
        resize(800, 600) 
          move(100, 100)
        
        oQuick = new qQuickWidget(w) {
            engine().AddImportPath(exefolder()+"qml")
			
            # Set the source to the file we just generated
            setSource(AppURL("stock_chart.qml"))
            setResizeMode(1) # QQuickWidget::SizeRootObjectToView
        }
        
        oLayout = new qVBoxlayout() {
            AddWidget(oQuick)
        }
        
        setlayout(oLayout)
        show()
    }
    exec()
}

        
// ================================================  
// ================================================  
/*
<=====> 
MONTHLY SHORT-List-6

<----- Debug CSV to aList 2D Display ----->
QQQ     103.86  96.98   95.46   101.7   98.75   103.06  100.45  107.92  109.05  111.19
ASML    80.28   83.06   82.32   90.79   87.36   90.42   90.79   100.32  97.51   100.28
ADBE    93.94   89.13   85.15   93.8    94.22   99.47   95.79   97.86   102.31  108.54
AMD     2.87    2.2     2.14    2.85    3.55    4.57    5.14    6.86    7.4     6.91
GOOGL   38.63   37.81   35.62   37.88   35.15   37.19   34.94   39.3    39.22   39.93
AMZN    33.79   29.35   27.63   29.68   32.98   36.14   35.78   37.94   38.46   41.87

<----- Debug Performance List: $RangeMth: 5 ----->
QQQ     0       0       0       0       0       0.99    1.04    1.13    1.07    1.13
ASML    0       0       0       0       0       1.13    1.09    1.22    1.07    1.15
ADBE    0       0       0       0       0       1.06    1.07    1.15    1.09    1.15
AMD     0       0       0       0       0       1.59    2.34    3.21    2.60    1.95
GOOGL   0       0       0       0       0       0.96    0.92    1.10    1.04    1.14
AMZN    0       0       0       0       0       1.07    1.22    1.37    1.30    1.27

<----- Debug Name List ----->
QQQ     0       0       0       0       0       AMD     AMD     AMD     AMD     AMD
ASML    0       0       0       0       0       ASML    AMZN    AMZN    AMZN    AMZN
ADBE    0       0       0       0       0       AMZN    ASML    ASML    ADBE    ADBE
AMD     0       0       0       0       0       ADBE    ADBE    ADBE    ASML    ASML
GOOGL   0       0       0       0       0       QQQ     QQQ     QQQ     QQQ     GOOGL
AMZN    0       0       0       0       0       GOOGL   GOOGL   GOOGL   GOOGL   QQQ

<----- Debug Rank List  ----->
QQQ     0       0       0       0       0       5       5       5       5       6
ASML    0       0       0       0       0       2       3       3       4       4
ADBE    0       0       0       0       0       4       4       4       3       3
AMD     0       0       0       0       0       1       1       1       1       1
GOOGL   0       0       0       0       0       6       6       6       6       5
AMZN    0       0       0       0       0       3       2       2       2       2
3
$Top10 <= 3
<----- nCol 7 ----->
Buy: ASML       90.42   7
Buy: AMD        4.57    7
Buy: AMZN       36.14   7

<----- nCol 8 ----->
Buy: ASML       90.79   8
Buy: AMD        5.14    8
Buy: AMZN       35.78   8

*/
