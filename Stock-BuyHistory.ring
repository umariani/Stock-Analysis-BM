// ============================================================
// Stock-BuyHistory.ring
// Bert Mariani  2025
//
// "Buy History" Tab  -- single panel, Buy History table only.
// Monthly panels moved to Stock-MonthlyResults.ring
// ============================================================

// Globals for this tab
oBuyHistTab    = null
oBuyHistTable  = null
oMthPerfTable  = null
brushBlack2    = null

// ============================================================
// BuildBuyHistTab(tabWidget)
// ============================================================

Func BuildBuyHistTab(tabWidget)

    oBuyHistTab = new QWidget()
    vLay = new QVBoxLayout()

    // Brushes
    colorBH2    = new qcolor()
    colorBH2.setrgb(0, 0, 0, 255)
    brushBlack2 = new qbrush()
    brushBlack2.setstyle(1)
    brushBlack2.setcolor(colorBH2)

    // Title
    lblBH = new QLabel(win)
    lblBH.setText("Top-10 Buy History  -  When Each Stock Last Became a Buy")
    lblBH.setStyleSheet("color: #007acc; font-weight: bold; font-size: 14px;")
    lblBH.setMaximumHeight(30)
    vLay.addWidget(lblBH)

    // Sub-title
    lblBH2 = new QLabel(win)
    lblBH2.setText("Working backwards from the last 01/mm date to find each stock's current holding streak.")
    lblBH2.setStyleSheet("color: #aaaaaa; font-size: 13px;")
    lblBH2.setMaximumHeight(22)
    vLay.addWidget(lblBH2)

    // Horizontal layout for the two tables
    hLay = new QHBoxLayout()

    // --- Left: Buy History table ---
    oBuyHistTable = new QTableWidget(win)
    oBuyHistTable.setColumnCount(7)
    oBuyHistTable.setRowCount(0)
    oBuyHistTable.setEditTriggers(0)
    oBuyHistTable.setStyleSheet(
        "QTableWidget { color:#000000; font-weight:normal; font-size:14px; " +
        "background-color:#ffffff; alternate-background-color:#f0f4f8; gridline-color:#cccccc; }" +
        "QHeaderView::section { background-color:#2b2b2b; color:#ffffff; " +
        "font-weight:bold; font-size:14px; padding:4px; border:1px solid #555; }" )

    oHeaders = new QStringList()
    oHeaders.append("Rank")
    oHeaders.append("Symbol")
    oHeaders.append("First Buy Date")
    oHeaders.append("Buy Price")
    oHeaders.append("Cur Price")
    oHeaders.append("Gain %")
    oHeaders.append("Mths/Wks Held")   // Updated by RefreshBuyHistTab
    oBuyHistTable.setHorizontalHeaderLabels(oHeaders)
    oBuyHistTable.horizontalHeader().setStretchLastSection(false)
    oBuyHistTable.setAlternatingRowColors(true)
    oBuyHistTable.setColumnWidth(0,  55)
    oBuyHistTable.setColumnWidth(1,  80)
    oBuyHistTable.setColumnWidth(2, 120)
    oBuyHistTable.setColumnWidth(3,  95)
    oBuyHistTable.setColumnWidth(4,  95)
    oBuyHistTable.setColumnWidth(5,  95)
    oBuyHistTable.setColumnWidth(6,  95)
    oBuyHistTable.setMaximumWidth(700)

    hLay.addWidget(oBuyHistTable)

    // --- Right: Month-by-month performance table ---
    oMthPerfTable = new QTableWidget(win)
    oMthPerfTable.setRowCount(0)
    oMthPerfTable.setColumnCount(0)
    oMthPerfTable.setEditTriggers(0)
    oMthPerfTable.setStyleSheet(
        "QTableWidget { color:#000000; font-weight:normal; font-size:13px; " +
        "background-color:#ffffff; alternate-background-color:#f0f4f8; gridline-color:#cccccc; }" +
        "QHeaderView::section { background-color:#2b2b2b; color:#ffffff; " +
        "font-weight:bold; font-size:13px; padding:4px; border:1px solid #555; }" )
    oMthPerfTable.setAlternatingRowColors(true)

    hLay.addWidget(oMthPerfTable)

    vLay.addLayout(hLay)
    oBuyHistTab.setLayout(vLay)
    tabWidget.addTab(oBuyHistTab, "Buy History")

Return oBuyHistTab


// ============================================================
// FindLastMonthCol()
// ============================================================

Func FindLastMonthCol()

    nTD = len(aTDate)

    // Weekly mode: every column is a period; return last column
    if isstring(cInterval) AND cInterval = "1wk"
        return nTD + 1   // last data column
    ok

    // Monthly mode: find last 01/ date
    for k = nTD to 1 step -1
        d = aTDate[k]
        if len(d) >= 3
            if subStr(d, 1, 3) = "01/"
                return k + 1
            ok
        ok
    next
    return len(aList[1]) - 1


// ============================================================
// RefreshBuyHistTab()
// ============================================================

Func RefreshBuyHistTab()

    if oBuyHistTable = null   return   ok
    if len(rList) < 2         return   ok

    // Update "Months/Weeks Held" column header dynamically
    cHeldHdr = "Months Held"
    if isstring(cInterval) AND cInterval = "1wk"   cHeldHdr = "Weeks Held"   ok
    oHdrDyn = new QStringList()
    oHdrDyn.append("Rank")   oHdrDyn.append("Symbol")   oHdrDyn.append("First Buy Date")
    oHdrDyn.append("Buy Price")   oHdrDyn.append("Cur Price")   oHdrDyn.append("Gain %")
    oHdrDyn.append(cHeldHdr)
    oBuyHistTable.setHorizontalHeaderLabels(oHdrDyn)
    if ! islist(rList[1])     return   ok

    nRow         = len(rList)
    lastMonthCol = FindLastMonthCol()
    nACol        = len(aList[1])

    // Step 1: Find current Top-K
    aTop10Rows = []
    for r = 1 to nRow
        if islist(rList[r])
            if len(rList[r]) >= lastMonthCol
                rnk = 0 + rList[r][lastMonthCol]
                if rnk >= 1 AND rnk <= $Top10
                    Add(aTop10Rows, [rnk, r])
                ok
            ok
        ok
    next

    nT = len(aTop10Rows)
    for i = 1 to nT - 1
        for j = 1 to nT - i
            if aTop10Rows[j][1] > aTop10Rows[j+1][1]
                tmp = aTop10Rows[j]
                aTop10Rows[j] = aTop10Rows[j+1]
                aTop10Rows[j+1] = tmp
            ok
        next
    next

    // Step 2: Walk backwards to find start of each stock's streak
    aBuyHistory = []
    warmupCol   = $RangeMth + 2

    for ti = 1 to len(aTop10Rows)
        rnk  = aTop10Rows[ti][1]
        rRow = aTop10Rows[ti][2]
        sym  = rList[rRow][1]

        buyCol = lastMonthCol
        for c = lastMonthCol - 1 to warmupCol step -1
            if len(rList[rRow]) >= c
                rnkPrev = 0 + rList[rRow][c]
                if rnkPrev >= 1 AND rnkPrev <= $Top10
                    buyCol = c
                else
                    exit
                ok
            else
                exit
            ok
        next

        posA     = FIND(aList, sym, 1)
        buyPrice = 0
        if posA > 0 AND buyCol <= len(aList[posA])
            buyPrice = 0 + aList[posA][buyCol]
        ok

        posC     = FIND(aClosedPrices, sym, 1)
        curPrice = 0
        if posC > 0
            curPrice = 0 + aClosedPrices[posC][ len(aClosedPrices[posC]) ]
        ok
        if curPrice < 0.01 AND posA > 0
            curPrice = 0 + aList[posA][nACol]
        ok

        gainPct = 0
        if buyPrice > 0.01
            gainPct = (curPrice / buyPrice - 1) * 100
        ok

        monthsHeld = lastMonthCol - buyCol

        buyDate = ""
        tIdx    = buyCol - 1
        if tIdx >= 1 AND tIdx <= len(aTDate)
            buyDate = aTDate[tIdx]
        ok
        if buyDate = ""   buyDate = "col " + buyCol   ok

        Add(aBuyHistory, [rnk, sym, buyDate, buyPrice, curPrice, gainPct, monthsHeld, buyCol])
    next

    // Step 3: Populate table
    oBuyHistTable.setRowCount(len(aBuyHistory))

    for i = 1 to len(aBuyHistory)
        rec       = aBuyHistory[i]
        iRnk      = rec[1]
        iSym      = rec[2]
        iBuyDate  = rec[3]
        iBuyPrice = rec[4]
        iCurPrice = rec[5]
        iGainPct  = rec[6]
        iMonths   = rec[7]

        wRnk  = new QTableWidgetItem("zx")
        wSym  = new QTableWidgetItem("zx")
        wDate = new QTableWidgetItem("zx")
        wBuy  = new QTableWidgetItem("zx")
        wCur  = new QTableWidgetItem("zx")
        wGain = new QTableWidgetItem("zx")
        wMth  = new QTableWidgetItem("zx")

        wRnk.setText("" + iRnk)
        wSym.setText("" + iSym)
        wDate.setText("" + iBuyDate)
        wBuy.setText(Fmt2(iBuyPrice))
        wBuy.setTextAlignment(0x0082)
        wCur.setText(Fmt2(iCurPrice))
        wCur.setTextAlignment(0x0082)
        wGain.setText(Fmt2(iGainPct) + "%")
        wGain.setTextAlignment(0x0082)
        wMth.setText("" + iMonths)
        wMth.setTextAlignment(0x0082)

        wRnk.setForeground(brushBlack2)
        wSym.setForeground(brushBlue)
        wDate.setForeground(brushBlack2)
        wBuy.setForeground(brushBlack2)
        wCur.setForeground(brushBlack2)
        wGain.setForeground(brushBlack2)
        wMth.setForeground(brushBlack2)

        if iGainPct > 0
            wGain.setForeground(brushBlue)
        elseif iGainPct < 0
            wGain.setForeground(brushRed)
        ok

        if iMonths >= 3
            wMth.setForeground(brushBlue)
        ok

        oBuyHistTable.setItem(i-1, 0, wRnk)
        oBuyHistTable.setItem(i-1, 1, wSym)
        oBuyHistTable.setItem(i-1, 2, wDate)
        oBuyHistTable.setItem(i-1, 3, wBuy)
        oBuyHistTable.setItem(i-1, 4, wCur)
        oBuyHistTable.setItem(i-1, 5, wGain)
        oBuyHistTable.setItem(i-1, 6, wMth)
    next

    App.processEvents()

    // -------------------------------------------------------
    // Step 4: Populate month-by-month performance table
    // Columns: Symbol | Mth0 | Mth1 | Mth2 ... MthN
    // Each cell shows the price at that month relative to buy
    // -------------------------------------------------------
    if oMthPerfTable = null   return   ok

    // --- Find max months held across all stocks
    nMaxMth = 0
    for i = 1 to len(aBuyHistory)
        if aBuyHistory[i][7] > nMaxMth   nMaxMth = aBuyHistory[i][7]   ok
    next
    nMaxMth = nMaxMth + 1   // +1 to always show one column beyond max months held (pre-buy month)

    nMthCols  = nMaxMth + 1 // Month 0 to nMaxMth 
    nMthRows  = len(aBuyHistory)

    oMthPerfTable.setRowCount(nMthRows)
    oMthPerfTable.setColumnCount(nMthCols + 1)   // +1 for Symbol column

    // --- Set headers: Symbol | Mth 0 | Mth 1 | ...
    oMthHdrs = new QStringList()
    oMthHdrs.append("Sym")
    cPfx = "M"
    if isstring(cInterval) AND cInterval = "1wk"   cPfx = "W"   ok
    for m = 0 to nMaxMth
        oMthHdrs.append(cPfx + m)
    next
	
    oMthPerfTable.setHorizontalHeaderLabels(oMthHdrs)
    oMthPerfTable.setColumnWidth(0, 55)
    for m = 0 to nMaxMth
        oMthPerfTable.setColumnWidth(m + 1, 65)
    next

    // --- Set vertical headers to rank numbers
    // ---(setVerticalHeaderLabels not available in Ring Qt binding - row index used instead)

    // --- Populate cells
    for i = 1 to nMthRows
        rec      = aBuyHistory[i]
        iSym     = rec[2]
        iMths    = rec[7]
        iBuyCol  = rec[8]   // column index where buy started

        // preBuyMth = how many months ago was the column just before buyCol
        // M(preBuyMth) corresponds to lastMonthCol - preBuyMth = buyCol - 1
        // so preBuyMth = lastMonthCol - (buyCol - 1) = lastMonthCol - buyCol + 1 = iMths + 1
        preBuyMth = iMths + 1

        // --- Find the stock in aList
        posA = FIND(aList, iSym, 1)

        // --- Symbol cell
        wS = new QTableWidgetItem("zx")
        wS.setText(iSym)
        wS.setForeground(brushBlue)
        oMthPerfTable.setItem(i-1, 0, wS)

        posC = FIND(aClosedPrices, iSym, 1)

        for m = 0 to nMaxMth              
            wM = new QTableWidgetItem("zx")

            bShow    = (m = 0) OR (m <= iMths) OR (m = preBuyMth)
            bPreBuy  = (m = preBuyMth)

            if bShow AND posA > 0
                if m = 0
                    // --- Partial month: open at lastMonthCol, close from aClosedPrices
                    pPrice = 0 + aList[posA][lastMonthCol]
                    mPrice = 0
                    if posC > 0
                        mPrice = 0 + aClosedPrices[posC][len(aClosedPrices[posC])]
                    ok
                    if mPrice < 0.01   mPrice = 0 + aList[posA][nACol]   ok
                else
                    // --- Completed month: opens at (lastMonthCol-m), closes at (lastMonthCol-m+1)
                    buyC  = lastMonthCol - m
                    sellC = lastMonthCol - m + 1
                    if buyC  < 2      buyC  = 2      ok
                    if sellC > nACol  sellC = nACol  ok
                    pPrice = 0 + aList[posA][buyC]
                    mPrice = 0 + aList[posA][sellC]
                ok

                if pPrice > 0.01
                    mGainPct = (mPrice / pPrice - 1) * 100
                    cVal = Fmt2(mGainPct) + "%"
                    wM.setText(cVal)
                    wM.setTextAlignment(0x0082)
                    if bPreBuy
                        // Red border to highlight the month just before the buy streak
                        wM.setBackground(new qbrush() { setcolor(new qcolor(){setrgb(255,220,220,255)}) setStyle(1) })
                        wM.setForeground(new qbrush() { setcolor(new qcolor(){setrgb(180,0,0,255)}) setStyle(1) })
                    else
                        if mGainPct > 0
                            wM.setForeground(brushBlue)
                        elseif mGainPct < 0
                            wM.setForeground(brushRed)
                        else
                            wM.setForeground(brushBlack2)
                        ok
                    ok
                ok
            else
                wM.setText("")
            ok

            oMthPerfTable.setItem(i-1, m+1, wM)
        next
    next

    App.processEvents()

Return


// ============================================================
// Fmt2(n)  –  format to exactly 2 decimal places
// ============================================================

Func Fmt2(n)
    nRounded = ceil(n * 100) / 100
    cStr     = "" + nRounded
    dotPos   = subStr(cStr, ".")
    if dotPos = 0          return cStr + ".00"   ok
    decimals = len(cStr) - dotPos
    if decimals = 0        return cStr + "00"
    elseif decimals = 1    return cStr + "0"
    else                   return subStr(cStr, 1, dotPos + 2)
    ok

