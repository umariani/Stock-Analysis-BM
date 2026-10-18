// ==================================================================
// Stock-WeeklyStopSell.ring
// Bert Mariani 2026 -- Weekly Yahoo data + $StopSell mid-month exit
//
// PURPOSE
// -------
// The rest of the app buys a new Top-10 basket once a MONTH (see
// ShowTop10() in Stock-YearlyReturns.ring). This module adds a
// WEEKLY check on top of that:
//
//   1. SyncWeeklyTop10Buys()   -- After every Run Analysis, look at the
//                                  Top-10 basket ShowTop10() just built
//                                  (aTop10Symbols / aTop10BuyPrice /
//                                  aTop10BuyDate). If it's a NEW
//                                  buy-month, start fresh weekly
//                                  tracking for those 10 stocks.
//
//   2. GetWeeklyQuotes()       -- Downloads interval=1wk Yahoo data
//                                  (range=2mo, ~8-9 weekly bars) for
//                                  ONLY the stocks currently being
//                                  tracked (not the whole universe).
//
//   3. CheckWeeklyStopSell()   -- Walks each week since the buy date;
//                                  the FIRST weekly close that is
//                                  <= -$StopSell% from the buy price
//                                  marks that stock SOLD (stopped
//                                  out) for the rest of the month.
//
//   4. WeeklyStopSellCheck()   -- Button handler: does #2 + #3 and
//                                  prints an HTML table to txtLog.
//
//   5. MonthlyResultsIfNewMonth() -- Called from RunAnalysis(). If
//                                  today is the 1st of the month,
//                                  prints a Held-vs-Stopped-Out
//                                  summary for the month that just
//                                  ended, then RefreshMonthlyResultsTab()
//                                  shows the normal monthly results.
//
// $StopSell (declared in Stock-Analysis-BM.ring, default 12) is the
// ONLY place the stop-loss percent is set -- change it there.
// ==================================================================

# --- Weekly Stop-Sell state (persists across Run Analysis clicks) ---
aWeeklyBuys      = []     // [Symbol, BuyPrice, BuyDate, Status, SellPrice, SellDate, LossPct]
aWeeklyClose     = []     // [ [Symbol, close1, close2, ... closeN], ... ]  1 row per tracked symbol
aWeeklyDates     = []     // [ [epoch1, epoch2, ... epochN], ... ]         parallel to aWeeklyClose
$LastBuyMonthKey = ""     // "01/mm/yyyy" of the buy-month currently being tracked

$wInterval       = "1wk"  // Weekly Yahoo interval
$wRange          = "2mo"  // ~8-9 weekly bars -- covers current month + buffer

# --- Full Weekly Backtest state (whole symbol universe, whole selected Range) ---
aWeeklyAllClose  = []     // [ [Symbol, close1, close2, ... closeN], ... ] every symbol in aSymbols, PLUS a final ["Date", d1, d2, ... dN] row
aWeeklyAllDates  = []     // [ "dd/mm/yyyy", "dd/mm/yyyy", ... ]           single shared weekly calendar, taken from QQQ

# --- Re-entrancy guards -------------------------------------------------
# Both button handlers below call App.processEvents() dozens/hundreds of
# times (once per downloaded symbol) to keep the UI responsive. Each call
# briefly hands control back to Qt's event loop -- if the button gets
# clicked again in that window, a SECOND, fully independent run starts
# while the first is still using the same global aList/bList/gList/mList,
# corrupting them. These flags make a second click a no-op instead.
$WeeklyCheckBusy    = false
$WeeklyBacktestBusy = false

# ==================================================================
# 1. SYNC -- pick up this month's Top-10 basket from ShowTop10()
# ==================================================================

Func SyncWeeklyTop10Buys()

    if len(aTop10Symbols) = 0
        return       // Run Analysis hasn't produced a Top-10 basket yet
    ok

    cBuyMonthKey = aTop10BuyDate[1]     // Same key on every row this run

    if cBuyMonthKey != $LastBuyMonthKey

        // --- New monthly rebalance detected -- start fresh weekly tracking ---
        aWeeklyBuys  = []
        aWeeklyClose = []
        aWeeklyDates = []

        for i = 1 to len(aTop10Symbols)
            Add(aWeeklyBuys, [ aTop10Symbols[i], aTop10BuyPrice[i], aTop10BuyDate[i],
                                "HOLD", 0, "", 0 ])
        next

        $LastBuyMonthKey = cBuyMonthKey

        txtLog.append(" ")
        txtLog.append("<===== NEW MONTHLY BUY: " + cBuyMonthKey +
                       " -- Weekly Stop-Sell tracking reset for " + len(aWeeklyBuys) +
                       " stocks (Stop = " + $StopSell + "%) =====>")
        App.processEvents()
    ok

Return

# ==================================================================
# 2. DOWNLOAD -- Weekly Yahoo data for the tracked (still HOLD) symbols
# ==================================================================

Func GetWeeklyQuotes()

    if len(aWeeklyBuys) = 0
        txtLog.append("Weekly Stop-Sell: No active Top-10 monthly buy list -- click Run Analysis first.")
        return
    ok

    curlW = curl_easy_init()
    curl_easy_setopt(curlW, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U;")

    aWeeklyClose = []
    aWeeklyDates = []

    for wRow in aWeeklyBuys

        wSymbol = wRow[1]
        wStatus = wRow[4]

###       if wStatus = "SOLD"
###           continue        // Already stopped out -- no need to re-download
###       ok

        wURL = "https://query1.finance.yahoo.com/v8/finance/chart/" + wSymbol +
               "?metrics=high?&interval=" + $wInterval + "&range=" + $wRange

        curl_easy_setopt(curlW, CURLOPT_URL, wURL)
        wStr = curl_easy_perform_silent(curlW)

        if len(wStr) = 0
            txtLog.append("Weekly Stop-Sell: NO INTERNET CONNECTION for " + wSymbol)
            App.processEvents()
            continue
        ok

        if subStr(wStr, '<title>Yahoo! - Error report</title>')
            txtLog.append("Weekly Stop-Sell: Yahoo! error report for " + wSymbol)
            App.processEvents()
            continue
        ok

        if subStr(wStr, 'No data found')
            txtLog.append("Weekly Stop-Sell: No data found for " + wSymbol)
            App.processEvents()
            continue
        ok

        wJSON  = JSON2List(wStr)
        wClose = wJSON[:chart][:result][1][:indicators][:quote][1][:close]
        wTime  = wJSON[:chart][:result][1][:timestamp]

        if len(wTime) = 0
            txtLog.append("Weekly Stop-Sell: Empty weekly series for " + wSymbol)
            App.processEvents()
            continue
        ok

        // --- Fill NULL weekly closes with the previous week's close ---
        for k = 2 to len(wClose)
            if wClose[k] = "null" OR wClose[k] = " null" OR wClose[k] = NULL
                wClose[k] = wClose[k-1]
            ok
        next

        wRowClose = [wSymbol]
        for k = 1 to len(wClose)
            Add(wRowClose, wClose[k])
        next

        Add(aWeeklyClose, wRowClose)
        Add(aWeeklyDates, wTime)

###        txtLog.append("Weekly Stop-Sell: " + wSymbol + " -- " + len(wClose) + " weekly bars downloaded")
           txtLog.append("Weekly: " + wSymbol )
        App.processEvents()
		
### sizelen = len(aWeeklyClose)
### for k = 1 to sizelen
###     See	"k: "+k  +" Close: "+ aWeeklyClose[k] +" Date: "+ aWeeklyDates[k] +nl
### next		

    next
	



Return

# ==================================================================
# 3. CHECK -- first weekly close <= -$StopSell% from buy price = SOLD
# ==================================================================

Func CheckWeeklyStopSell()

    if len(aWeeklyBuys) = 0
        txtLog.append("Weekly Stop-Sell: No active Top-10 monthly buy list -- click Run Analysis first.")
        return
    ok

    cReport  = "<table cellspacing='0' cellpadding='0'>"
    cReport += "<tr><td width='55'><b>Sym</b></td><td width='75' align='right'><b>BuyPx</b></td>"
    cReport += "<td width='75' align='right'><b>WkClose</b></td><td width='65' align='right'><b>Pct%</b></td>"
    cReport += "<td width='110'><b>Status</b></td></tr>"

    for i = 1 to len(aWeeklyBuys)

        wSymbol   = aWeeklyBuys[i][1]
        wBuyPrice = aWeeklyBuys[i][2]
        wBuyDate  = aWeeklyBuys[i][3]      // "01/mm/yyyy" -- ignore weeks before this
        wStatus   = aWeeklyBuys[i][4]

        // --- Already stopped out earlier in the month ---
        if wStatus = "SOLD"
            cReport += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
            cReport += "<td align='right'>" + NumFmt(aWeeklyBuys[i][5]) + "</td>"
            cReport += "<td align='right' style='color:red;'>" + NumFmt(aWeeklyBuys[i][7]) + "</td>"
            cReport += "<td style='color:red;'><b>SOLD " + aWeeklyBuys[i][6] + "</b></td></tr>"
            continue
        ok

        // --- Find this symbol's downloaded weekly closes ---
        posW = 0
        for w = 1 to len(aWeeklyClose)
            if aWeeklyClose[w][1] = wSymbol
                posW = w
            ok
        next

        if posW = 0
            cReport += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
            cReport += "<td colspan='3'>No weekly data</td></tr>"
            continue
        ok

        wCloses = aWeeklyClose[posW]     // [Symbol, close1, close2, ...]
        wDates  = aWeeklyDates[posW]     // [epoch1, epoch2, ...]  (no Symbol col)

        lastClose = wCloses[ len(wCloses) ]
        PctChg    = (lastClose - wBuyPrice) / wBuyPrice * 100

        buyDateNum = DateToNum(wBuyDate)  // e.g. "01/07/2026" -> 20260701

        // --- Walk every downloaded week ON/AFTER the buy date, stop at the FIRST breach ---
        Stopped   = false
        StopPrice = 0
        StopDate  = ""
        StopPct   = 0

        for k = 2 to len(wCloses)              // wCloses[1] = Symbol name
            wClosePx = wCloses[k]
            wEpoch   = wDates[k-1]              // wDates has no Symbol col -- offset by 1
            wDateNum = DateToNum( EpochToDate(wEpoch) )

            if wDateNum < buyDateNum
                continue        // Week is from before the buy date -- part of the download buffer only, ignore
            ok

            wPct = (wClosePx - wBuyPrice) / wBuyPrice * 100

            if wPct <= (0 - $StopSell) and not Stopped
                Stopped   = true
                StopPrice = wClosePx
                StopDate  = EpochToDate(wEpoch)
                StopPct   = wPct
            ok
        next

        if Stopped
            aWeeklyBuys[i][4] = "SOLD"
            aWeeklyBuys[i][5] = StopPrice
            aWeeklyBuys[i][6] = StopDate
            aWeeklyBuys[i][7] = StopPct

            cReport += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
            cReport += "<td align='right'>" + NumFmt(StopPrice) + "</td>"
            cReport += "<td align='right' style='color:red;'>" + NumFmt(StopPct) + "</td>"
            cReport += "<td style='color:red;'><b>SOLD " + StopDate + "</b></td></tr>"

            See "STOP-SELL: " + wSymbol + " Buy: " + wBuyPrice + " Week: " + StopDate +
                " Close: " + StopPrice + " Pct: " + StopPct + "%" + nl
        else
            cColor = ""
            if PctChg < 0   cColor = " style='color:red;'"   ok

            cReport += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
            cReport += "<td align='right'>" + NumFmt(lastClose) + "</td>"
            cReport += "<td align='right'" + cColor + ">" + NumFmt(PctChg) + "</td>"
            cReport += "<td>HOLD</td></tr>"
        ok

    next

    cReport += "</table>"

    txtLog.append(" ")
    txtLog.append("<===== Weekly Stop-Sell Check (Stop = " + $StopSell + "%) -- " + Date() + " =====>")
    txtLog.append(cReport)
    App.processEvents()

Return

// Converts a "dd/mm/yyyy" string into an orderable integer yyyymmdd,
// so weeks can be compared against the buy date without string quirks.
Func DateToNum(cDate)

    aParts = split(cDate, "/")
    dd     = 0 + aParts[1]
    mm     = 0 + aParts[2]
    yyyy   = 0 + aParts[3]

Return (yyyy * 10000) + (mm * 100) + dd

# ==================================================================
# 4. BUTTON HANDLER -- Download weekly data, then check for stop-outs
# ==================================================================

Func WeeklyStopSellCheck()

    if $WeeklyCheckBusy
        txtLog.append("Weekly Stop-Sell: Already running -- please wait for it to finish.")
        return
    ok
    $WeeklyCheckBusy = true
    if btnWeeklyStop != null   btnWeeklyStop.setEnabled(false)   ok

    try
        GetWeeklyQuotes()
        CheckWeeklyStopSell()
        ComputeWeeklyAdjustedTotal()
    catch
        txtLog.append("Weekly Stop-Sell FAILED: " + cCatchError)
        App.processEvents()
    done

    $WeeklyCheckBusy = false
    if btnWeeklyStop != null   btnWeeklyStop.setEnabled(true)   ok

Return

# ==================================================================
# 4b. TOTAL -- Portfolio value/return using StopPrice for SOLD stocks
#     and NowPrice for stocks still HELD -- answers "what's my total
#     result WITH the weekly stop-sell applied?"
# ==================================================================

Func ComputeWeeklyAdjustedTotal()

    if len(aWeeklyBuys) = 0
        return
    ok

    InvestedTotal = 0
    AdjustedTotal = 0
    AdjustedSum   = 0        // for a simple (unweighted) average %, mirrors AvgPct in ShowTop10()

    cRep  = "<table cellspacing='0' cellpadding='0'>"
    cRep += "<tr><td width='55'><b>Sym</b></td><td width='75' align='right'><b>BuyPx</b></td>"
    cRep += "<td width='75' align='right'><b>ExitPx</b></td><td width='60' align='right'><b>Pct%</b></td>"
    cRep += "<td width='110'><b>State</b></td><td width='90' align='right'><b>Value $</b></td></tr>"

    for wRow in aWeeklyBuys

        wSymbol   = wRow[1]
        wBuyPrice = wRow[2]
        wStatus   = wRow[4]

        // --- Match this symbol back to this run's Shares / NowPrice snapshot ---
        posT = 0
        for t = 1 to len(aTop10Symbols)
            if aTop10Symbols[t] = wSymbol
                posT = t
            ok
        next

        if posT = 0
            continue          // Symbol not in this run's ranked universe -- can't value it, skip
        ok

        wShares   = aTop10Shares[posT]
        wNowPrice = aTop10NowPrice[posT]

        if wStatus = "SOLD"
            ExitPrice = wRow[5]
            ExitPct   = wRow[7]
            cState    = "STOPPED " + wRow[6]
        else
            ExitPrice = wNowPrice
            ExitPct   = (wNowPrice - wBuyPrice) / wBuyPrice * 100
            cState    = "HELD"
        ok

        InvestedVal = wShares * wBuyPrice
        AdjustedVal = wShares * ExitPrice

        InvestedTotal += InvestedVal
        AdjustedTotal += AdjustedVal
        AdjustedSum   += ExitPct

        cColor = ""
        if ExitPct < 0   cColor = " style='color:red;'"   ok

        cRep += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
        cRep += "<td align='right'>" + NumFmt(ExitPrice) + "</td>"
        cRep += "<td align='right'" + cColor + ">" + NumFmt(ExitPct) + "</td>"
        cRep += "<td" + cColor + ">" + cState + "</td>"
        cRep += "<td align='right'>" + NumFmt(AdjustedVal) + "</td></tr>"

    next

    cRep += "</table>"

    nStocks = len(aWeeklyBuys)
    if nStocks = 0   nStocks = 1   ok

    WeightedPct = 0
    if InvestedTotal > 0
        WeightedPct = (AdjustedTotal - InvestedTotal) / InvestedTotal * 100
    ok

    SimpleAvgPct = AdjustedSum / nStocks

    txtLog.append(" ")
    txtLog.append("<===== Weekly-Adjusted Portfolio Total (Stop = " + $StopSell + "%) -- " + Date() + " =====>")
    txtLog.append(cRep)
    txtLog.append("Invested: $" + NumFmt(InvestedTotal) + "   Weekly-Adjusted Value: $" + NumFmt(AdjustedTotal))
    txtLog.append("Weekly-Adjusted Total Return: " + NumFmt(WeightedPct) + "%   (Simple Avg Pct: " + NumFmt(SimpleAvgPct) + "%)")
    App.processEvents()

    See nl + "Weekly-Adjusted Total Return: " + WeightedPct + "%  Invested: " + InvestedTotal +
        "  Value: " + AdjustedTotal + nl

Return

# ==================================================================
# 5. MONTH-START -- print Held vs Stopped-Out results for the month
#    that just ended, then let the normal Monthly Results tab refresh
# ==================================================================

Func MonthlyResultsIfNewMonth()

    aTodayParts = split(Date(), "/")

    if aTodayParts[1] = "01"
        txtLog.append(" ")
        txtLog.append("<===== FIRST OF MONTH: " + Date() + " -- Monthly Results =====>")
        ShowWeeklyStopSellSummary()
        ComputeWeeklyAdjustedTotal()
        App.processEvents()
    ok

Return

// Held-vs-Stopped-Out summary table for the Top-10 basket being replaced
Func ShowWeeklyStopSellSummary()

    if len(aWeeklyBuys) = 0
        return
    ok

    cSum  = "<table cellspacing='0' cellpadding='0'>"
    cSum += "<tr><td width='55'><b>Sym</b></td><td width='75' align='right'><b>BuyPx</b></td>"
    cSum += "<td width='130'><b>Result</b></td><td width='75' align='right'><b>Pct%</b></td></tr>"

    for wRow in aWeeklyBuys

        wSymbol   = wRow[1]
        wBuyPrice = wRow[2]
        wStatus   = wRow[4]

        if wStatus = "SOLD"
            cSum += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
            cSum += "<td style='color:red;'><b>STOPPED OUT " + wRow[6] + "</b></td>"
            cSum += "<td align='right' style='color:red;'>" + NumFmt(wRow[7]) + "</td></tr>"
        else
            cSum += "<tr><td>" + wSymbol + "</td><td align='right'>" + NumFmt(wBuyPrice) + "</td>"
            cSum += "<td>HELD Full Month</td><td align='right'>--</td></tr>"
        ok
    next

    cSum += "</table>"

    txtLog.append(cSum)

Return

# ==================================================================
# 6. FULL WEEKLY BACKTEST -- whole symbol universe, whole selected
#    Range (e.g. 2y), every month re-run with mid-month $StopSell
#    exits, Overview chart + stat cards redrawn with the result.
#
#    Requires "Get Quotes" + "Run Analysis" to have been run first
#    (needs aSymbols, aList, bList, gList, aTDate already built).
# ==================================================================

Func GetAllWeeklyQuotes()

    if len(aSymbols) = 0
        txtLog.append("Weekly Backtest: No symbol list -- click 'Get Quotes' first.")
        return
    ok

    cWRange = comboRange.currentText()      // Reuse whatever Range is selected (e.g. "2y")

    curlA = curl_easy_init()
    curl_easy_setopt(curlA, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U;")

    aWeeklyAllClose = []
    aWeeklyAllDates = []

    nDone = 0

    for $Symbol in aSymbols

        wURL = "https://query1.finance.yahoo.com/v8/finance/chart/" + $Symbol +
               "?metrics=high?&interval=" + $wInterval + "&range=" + cWRange

        curl_easy_setopt(curlA, CURLOPT_URL, wURL)
        wStr = curl_easy_perform_silent(curlA)

        if len(wStr) = 0
            txtLog.append("Weekly (Full): NO INTERNET for " + $Symbol)
            App.processEvents()
            continue
        ok

        if subStr(wStr, '<title>Yahoo! - Error report</title>')
            txtLog.append("Weekly (Full): Yahoo! error for " + $Symbol)
            App.processEvents()
            continue
        ok

        if subStr(wStr, 'No data found')
            txtLog.append("Weekly (Full): No data for " + $Symbol)
            App.processEvents()
            continue
        ok

        wJSON  = JSON2List(wStr)
        wClose = wJSON[:chart][:result][1][:indicators][:quote][1][:close]
        wTime  = wJSON[:chart][:result][1][:timestamp]

        if len(wTime) = 0
            txtLog.append("Weekly (Full): Empty weekly series for " + $Symbol)
            App.processEvents()
            continue
        ok

        // --- Fill NULL weekly closes with the previous week's close ---
        for k = 2 to len(wClose)
            if wClose[k] = "null" OR wClose[k] = " null" OR wClose[k] = NULL
               wClose[k] = wClose[k-1]
            ok
        next

        wRowClose = [$Symbol]
        for k = 1 to len(wClose)
            Add(wRowClose, wClose[k])
        next
		
### See "===== wRowClose: ====== "+ $Symbol +" "+ len(wClose) +nl	
### See ""+ wRowClose[1] +" "+ wRowClose[2] +" "+ wRowClose[3] +" "+ wRowClose[4]	 +nl

        Add(aWeeklyAllClose, wRowClose)

        // --- Only need ONE set of dates (all symbols share the same weekly calendar) ---
        // --- Take it from QQQ and convert epoch -> "dd/mm/yyyy" ---
        if $Symbol = "QQQ"
            aWeeklyAllDates = []
            for k = 1 to len(wTime)
                Add(aWeeklyAllDates, EpochToDate(wTime[k]))
            next
        ok
		
		
 See "aWeeklyAllClose: "+ nDone +" "+ $Symbol  +nl
		

        nDone++
		
###        txtLog.append("Weekly (Full): " + nDone +" "+ $Symbol +
###                       " -- " + len(wClose) + " weekly bars")
###					   
###      txtLog.append("Weekly All: " + nDone +"  "+ $Symbol )					   					   
###      App.processEvents()

    next

    // --- Append the dd/mm/yyyy dates as the last line of aWeeklyAllClose ---
    if len(aWeeklyAllDates) > 0
        wRowDate = ["Date"]
        for k = 1 to len(aWeeklyAllDates)
            Add(wRowDate, aWeeklyAllDates[k])
        next
        Add(aWeeklyAllClose, wRowDate)
    ok
	
See "Len aWeeklyAllClose "+ len(aWeeklyAllClose) +nl	
See "Len aWeeklyAllDates "+ len(aWeeklyAllDates) +nl	
	
	
 
# DebugArray(aWeeklyAllClose)
# DebugArray(aWeeklyAllDates)
 
 
### sizelen = len(aWeeklyAllClose)
### See "aWeeklyAllClose: "+ sizelen +nl
###  for k = 1 to sizelen
###      See "k: "+k  +" "+ aWeeklyAllClose[k][1] +" "+  len(aWeeklyAllClose[k]) +nl
###  next
 
 

###    txtLog.append("Weekly (Full): Download complete -- " + len(aWeeklyAllClose) + " / " +
###                   len(aSymbols) + " symbols with weekly history.")
###    App.processEvents()
	



	

Return



// Overwrites gList in place: for every monthly Buy (bList[nRow][nCol] > 0),
// if a weekly close between the buy-month and the next month breaches
// -$StopSell%, that week's close replaces next-month's price as the Gain
// basis. Months/stocks with no breach keep CalcGain()'s normal Gain.
Func ApplyWeeklyStopSellToGains()

    if not isList(gList[1])
        txtLog.append("Weekly Backtest: Click 'Run Analysis' first so the Buy/Gain lists exist.")
        return
    ok

    Vert = len(gList)
    Horz = len(gList[1])

    nStopped = 0
    nTotal   = 0

    for nCol = $RangeMth + 2 to Horz - 1

        buyDateNum  = DateToNum( aTDate[nCol-1] )   // Month this column's Buy happened
        sellDateNum = DateToNum( aTDate[nCol]   )   // Start of the FOLLOWING month (exclusive bound)

        for nRow = 1 to Vert

            if bList[nRow][nCol] > 0     // Has a Buy Price this month

                stock    = bList[nRow][1]
                buyPrice = bList[nRow][nCol]

                posW = FIND(aWeeklyAllClose, stock, 1)

                if posW > 0

                    wCloses = aWeeklyAllClose[posW]
                    wDates  = aWeeklyAllDates    // shared "dd/mm/yyyy" list -- same weekly calendar for every symbol

                    Stopped   = false
                    ExitPrice = 0

                    for k = 2 to len(wCloses)             // wCloses[1] = Symbol name
                        wDateNum = DateToNum( wDates[k-1] )  // already "dd/mm/yyyy" -- wDates has no Symbol col, offset by 1

                        if wDateNum >= buyDateNum and wDateNum < sellDateNum and not Stopped
                            wPct = (wCloses[k] - buyPrice) / buyPrice * 100
                            if wPct <= (0 - $StopSell)
                                Stopped   = true
                                ExitPrice = wCloses[k]
                            ok
                        ok
                    next

                    nTotal++

                    if Stopped
                        gList[nRow][nCol] = ExitPrice / buyPrice
                        nStopped++
                    ok

                ok

            ok
        next
    next

    txtLog.append("Weekly Backtest: " + nStopped + " / " + nTotal +
                   " monthly Buy positions stopped out mid-month (Stop = " + $StopSell + "%)")
    App.processEvents()

Return

// Helper: always call this before returning from WeeklyStopSellBacktest(),
// on every exit path (success, early-abort, or caught error), so a stuck
// busy flag / disabled button can never survive past one call.
Func ResetWeeklyBacktestButton()

    $WeeklyBacktestBusy = false
    if btnWeeklyBacktest != null
        btnWeeklyBacktest.setEnabled(true)
        btnWeeklyBacktest.setText("Weekly Backtest (Full)")
    ok
    App.processEvents()

Return

// Button handler: download weekly history for the WHOLE universe over the
// selected Range, re-derive Gain with mid-month stop-sells applied, then
// rebuild mList/cList/aSumTotal and redraw the Overview chart + stat cards.
Func WeeklyStopSellBacktest()

    if $WeeklyBacktestBusy
        txtLog.append("Weekly Backtest: Already running -- please wait for it to finish (this can take a minute for a large ticker file).")
        return
    ok

    if len(aSymbols) = 0
        txtLog.append("Weekly Backtest: Click 'Get Quotes' first so a price history exists.")
        return
    ok

    $WeeklyBacktestBusy = true
    if btnWeeklyBacktest != null
        btnWeeklyBacktest.setEnabled(false)
        btnWeeklyBacktest.setText("Running...")
    ok
    App.processEvents()

    txtLog.append(" ")
    txtLog.append("<===== FULL WEEKLY BACKTEST -- rebuilding Buy/Gain lists for RangeMth=" +
                   $RangeMth + " Top" + $Top10 + ", downloading weekly history for " +
                   len(aSymbols) + " symbols (Range=" + comboRange.currentText() +
                   ", Stop=" + $StopSell + "%) =====>")
    App.processEvents()

    // --- Rebuild the Buy/Gain lists fresh, from the CURRENT RangeMth/Top10 ---
    // Run Analysis also runs the Algorithm Grid search, which tries MANY
    // RangeMth/Top10 combinations internally and can leave bList/gList/aList
    // sized to whichever combo it tested LAST -- not necessarily the "best"
    // one it reports. Rather than trust that leftover state, rebuild it here
    // exactly the way YearlyReturns() does, so it's guaranteed to match
    // whatever RangeMth/Top10 is currently set.
    try

        ReadCSVFile()
        CreateLists()
        CalcPerformance()
        SortPerformance()
        GenerateRank()
        BuyRank()
        CalcGain()

        // --- Pre-flight sanity check before the fragile MonthlyGain() step ---
        nDiagRows = len(aList)
        nDiagCols = len(aList[1])

        txtLog.append("Weekly Backtest diag: aList=" + nDiagRows + "x" + nDiagCols +
                       "  gList=" + len(gList) + "x" + len(gList[1]) +
                       "  bList=" + len(bList) + "x" + len(bList[1]) +
                       "  RangeMth=" + $RangeMth + "  Top10=" + $Top10 +
                       "  StartCol=" + ($RangeMth+2))
        App.processEvents()

        if nDiagRows = 0 or nDiagCols = 0
            txtLog.append("Weekly Backtest: aList is empty after ReadCSVFile() -- aborting. Check the ticker file / CSV on disk.")
            ResetWeeklyBacktestButton()
            return
        ok

        if $RangeMth + 2 > nDiagCols
            txtLog.append("Weekly Backtest: RangeMth=" + $RangeMth + " needs at least " + ($RangeMth+2) +
                           " columns of monthly data, but only " + nDiagCols +
                           " exist -- aborting. Try a smaller RangeMth or a longer Range.")
            ResetWeeklyBacktestButton()
            return
        ok

        if $Top10 <= 0
            txtLog.append("Weekly Backtest: Top10=" + $Top10 + " is not valid -- aborting.")
            ResetWeeklyBacktestButton()
            return
        ok

        // --- Safety net: aList has been observed to get unexpectedly resized ---
        // --- somewhere during the weekly-quotes download/apply steps below.   ---
        // --- Snapshot it now and restore it if either step leaves it altered. ---
        aListBackup = aList

        GetAllWeeklyQuotes()

        nowRows = len(aList)
        nowCols = 0
        if nowRows > 0  nowCols = len(aList[1])  ok
        if nowRows != nDiagRows or nowCols != nDiagCols
            txtLog.append("Weekly Backtest: aList was altered during GetAllWeeklyQuotes() (now " +
                           nowRows + "x" + nowCols + ", expected " + nDiagRows + "x" + nDiagCols +
                           ") -- restoring from backup.")
            aList = aListBackup
        ok

        ApplyWeeklyStopSellToGains()

        nowRows = len(aList)
        nowCols = 0
        if nowRows > 0  nowCols = len(aList[1])  ok
        if nowRows != nDiagRows or nowCols != nDiagCols
            txtLog.append("Weekly Backtest: aList was altered during ApplyWeeklyStopSellToGains() (now " +
                           nowRows + "x" + nowCols + ", expected " + nDiagRows + "x" + nDiagCols +
                           ") -- restoring from backup.")
            aList = aListBackup
        ok

        MonthlyGain()      // gList (now Stop-Sell-adjusted) -> mList
        Compounding()      // mList -> cList
        SummaryStock()     // mList -> aSumStock (kept for parity with the normal flow)
        SummaryTotal()     // cList -> aSumTotal

    catch

        txtLog.append(" ")
        txtLog.append("<===== Weekly Backtest FAILED: " + cCatchError + " =====>")
        txtLog.append("Diag at failure: aList=" + len(aList) + "x" + len(aList[1]) +
                       "  gList=" + len(gList) + "x" + len(gList[1]) +
                       "  bList=" + len(bList) + "x" + len(bList[1]) +
                       "  mList=" + len(mList) +
                       "  RangeMth=" + $RangeMth + "  Top10=" + $Top10)
        App.processEvents()
        ResetWeeklyBacktestButton()
        return

    done

    // --- Same aSumTotal shaping YearlyReturns() does before charting ---
    Del(aSumTotal[1], len(aSumTotal[1]))
    Del(aSumTotal[1], 1)

    Del(aSumTotal[2], len(aSumTotal[2]))
    Del(aSumTotal[2], 1)

    Del(aSumTotal[3], len(aSumTotal[3]))
    Del(aSumTotal[3], 1)
    Del(aSumTotal[3], len(aSumTotal[3]))
    Insert(aSumTotal[3], $RangeMth + 1, 1)

    if len(aSumTotal) >= 4
        Del(aSumTotal[4], len(aSumTotal[4]))
        Del(aSumTotal[4], 1)
    ok

    oChartWidget.setData(aSumTotal)     // <<< Redraw Overview Chart with the Stop-Sell curve

    // --- Refresh CAGR / Sharpe / MaxDD / stat cards for the new curve ---
    cellNbr = len(aSumTotal[3]) - 1
    $maxQQQ = aSumTotal[2][cellNbr]
    $maxTOT = aSumTotal[3][cellNbr]
    if len(aSumTotal) >= 4
        $maxSPY = aSumTotal[4][cellNbr]
    ok
    $Ratio  = ($maxTOT - 1) / ($maxQQQ - 1)
    if len(aSumTotal) >= 4
        $RatioSPY = ($maxTOT - 1) / ($maxSPY - 1)
    ok

    ComputePortfolioStats(cellNbr)
    UpdateStatCards()

    txtLog.append("Weekly Backtest: Done.  Total Return: " + NumFmt(($maxTOT-1)*100) +
                   "%   QQQ: " + NumFmt(($maxQQQ-1)*100) +
                   "%   CAGR: " + NumFmt($CAGR*100) +
                   "%   MaxDD: -" + NumFmt($MaxDD*100) + "%")

    ResetWeeklyBacktestButton()

Return

