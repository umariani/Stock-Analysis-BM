// ============================================================
// Stock-BuyHistory.ring
// Bert Mariani  2025
//
// "Buy History" Tab  --  Tab 3
//
// For each of the current Top-10 stocks, walk backwards through
// rList to find the column where the stock FIRST entered the
// Top-10 in its current unbroken streak.
//
// KEY RULES:
//   1. Work backwards from the last "01/mm/yyyy" date column
//      in aTDate  (NOT the final live/mid-month column).
//      The last entry in aTDate is today's live date; ignore it.
//   2. Gain % shown in Blue for positive, Red for negative.
//   3. All cells default to plain Black so the parent dark
//      stylesheet does not bleed bold/coloured text.
// ============================================================

// Globals for this tab
oBuyHistTab   = null
oBuyHistTable = null
brushBlack2   = null    // local plain-black brush for table cells

// ============================================================
// BuildBuyHistTab(tabWidget)
// ============================================================

Func BuildBuyHistTab(tabWidget)

    oBuyHistTab = new QWidget()
    vLay = new QVBoxLayout()

    // Title
    lblBH = new QLabel(win)
    lblBH.setText("Top-10 Buy History  -  When Each Stock Last Became a Buy")
    lblBH.setStyleSheet("color: #007acc; font-weight: bold; font-size: 14px;")
    lblBH.setMaximumHeight(30)
    vLay.addWidget(lblBH)

    // Sub-title
    lblBH2 = new QLabel(win)
    lblBH2.setText("Working backwards from the last 01/mm date to find each stock's current holding streak.")
    lblBH2.setStyleSheet("color: #aaaaaa; font-size: 14px;")
    lblBH2.setMaximumHeight(22)
    vLay.addWidget(lblBH2)

    // Plain black brush -- created here so parent stylesheet cannot bleed
    colorBH2    = new qcolor()
    colorBH2.setrgb(0, 0, 0, 255)
    brushBlack2 = new qbrush()
    brushBlack2.setstyle(1)
    brushBlack2.setcolor(colorBH2)

    // Blue brush for positive Gain %
    colorBH3    = new qcolor()
    colorBH3.setrgb(0, 0, 200, 255)
    brushBlue2  = new qbrush()
    brushBlue2.setstyle(1)
    brushBlue2.setcolor(colorBH3)

    // Table -- override parent dark stylesheet explicitly
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
    oHeaders.append("Months Held")
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

    vLay.addWidget(oBuyHistTable)
    oBuyHistTab.setLayout(vLay)
    tabWidget.addTab(oBuyHistTab, "Buy History")

Return oBuyHistTab


// ============================================================
// FindLastMonthCol()
//
// aTDate[k] corresponds to aList column k+1
// (col 2 = aTDate[1], col k+1 = aTDate[k])
//
// The LAST entry of aTDate is the live mid-month date, e.g.
// "11/05/2026".  All proper monthly picks use "01/mm/yyyy".
//
// Walk BACKWARDS through aTDate to find the last index whose
// date string starts with "01/".  Return the corresponding
// aList column number = tIdx + 1.
// ============================================================

Func FindLastMonthCol()

    nTD = len(aTDate)
    for k = nTD to 1 step -1
        d = aTDate[k]
        if len(d) >= 3
            if subStr(d, 1, 3) = "01/"
                return k + 1    // aList column = aTDate index + 1
            ok
        ok
    next

    // Fallback: use second-to-last column of aList
    return len(aList[1]) - 1


// ============================================================
// RefreshBuyHistTab()
//   Called from RunAnalysis() after YearlyReturns() completes.
// ============================================================

Func RefreshBuyHistTab()

    if oBuyHistTable = null   return   ok
    if len(rList) < 2         return   ok
    if ! islist(rList[1])     return   ok

    nRow  = len(rList)
    nCol  = len(rList[1])      // col 1 = symbol, rest = monthly ranks

    // Last proper monthly column (01/mm date) -- ignore live last col
    lastMonthCol = FindLastMonthCol()

    // Current live price column in aList / aClosedPrices
    nACol = len(aList[1])

###    See "BuyHist: nCol="+ nCol +" lastMonthCol="+ lastMonthCol +
        " aTDate last="+ aTDate[len(aTDate)] +nl

    // ---------------------------------------------------
    // Step 1: Find current Top-10 using lastMonthCol rank
    // ---------------------------------------------------

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

    // Sort ascending by rank
    nT = len(aTop10Rows)
    for i = 1 to nT - 1
        for j = 1 to nT - i
            if aTop10Rows[j][1] > aTop10Rows[j+1][1]
                tmp             = aTop10Rows[j]
                aTop10Rows[j]   = aTop10Rows[j+1]
                aTop10Rows[j+1] = tmp
            ok
        next
    next

    // ---------------------------------------------------
    // Step 2: Walk backwards from lastMonthCol to find
    //         start of each stock's unbroken Top-K streak.
    //         warmupCol = first valid rank column.
    // ---------------------------------------------------

    aBuyHistory = []
    warmupCol   = $RangeMth + 2

    for ti = 1 to len(aTop10Rows)

        rnk  = aTop10Rows[ti][1]
        rRow = aTop10Rows[ti][2]
        sym  = rList[rRow][1]

        // Walk backwards -- buyCol is the earliest col still in Top-K
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

        // ---------------------------------------------------
        // Buy Price: aList price at buyCol
        // ---------------------------------------------------
        posA     = FIND(aList, sym, 1)
        buyPrice = 0
        if posA > 0 AND buyCol <= len(aList[posA])
            buyPrice = 0 + aList[posA][buyCol]
        ok

        // ---------------------------------------------------
        // Current (live) Price: last col of aClosedPrices
        //                       fall back to last col of aList
        // ---------------------------------------------------
        posC     = FIND(aClosedPrices, sym, 1)
        curPrice = 0
        if posC > 0
            curPrice = 0 + aClosedPrices[posC][ len(aClosedPrices[posC]) ]
        ok
        if curPrice < 0.01 AND posA > 0
            curPrice = 0 + aList[posA][nACol]
        ok

        // ---------------------------------------------------
        // Gain %
        // ---------------------------------------------------
        gainPct = 0
        if buyPrice > 0.01
            gainPct = (curPrice / buyPrice - 1) * 100
        ok

        // ---------------------------------------------------
        // Months Held  =  lastMonthCol - buyCol
        // ---------------------------------------------------
        monthsHeld = lastMonthCol - buyCol

        // ---------------------------------------------------
        // Buy Date from aTDate
        //   aTDate[k] = aList col k+1  =>  tIdx = buyCol - 1
        //   These are already "01/mm/yyyy" for all proper monthly
        //   columns (that is why FindLastMonthCol() picked them).
        // ---------------------------------------------------
        buyDate = ""
        tIdx = buyCol - 1
        if tIdx >= 1 AND tIdx <= len(aTDate)
            buyDate = aTDate[tIdx]
        ok
        if buyDate = ""
            buyDate = "col " + buyCol
        ok

        Add(aBuyHistory, [rnk, sym, buyDate, buyPrice, curPrice, gainPct, monthsHeld])

###        See "BuyHist: "+ sym +" rank="+ rnk +" buyCol="+ buyCol +
            " date="+ buyDate +" buyPx="+ buyPrice +" curPx="+ curPrice +
            " gain="+ ceil(gainPct*10)/10 +"% months="+ monthsHeld +nl
    next

    // ---------------------------------------------------
    // Step 3: Populate table
    // ---------------------------------------------------

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
        wBuy.setTextAlignment(0x0082)   // AlignRight + AlignVCenter
        wCur.setText(Fmt2(iCurPrice))
        wCur.setTextAlignment(0x0082)   // AlignRight + AlignVCenter
        wGain.setText("" + ceil(iGainPct * 10) / 10 + "%")
        wGain.setTextAlignment(0x0082)   // AlignRight + AlignVCenter
        wMth.setText("" + iMonths)

        // Default ALL cells to plain black (blocks stylesheet bleed)
        wRnk.setForeground(brushBlack2)
        wSym.setForeground(brushBlue)
        wDate.setForeground(brushBlack2)
        wBuy.setForeground(brushBlack2)
        wCur.setForeground(brushBlack2)
        wGain.setForeground(brushBlack2)
        wMth.setForeground(brushBlack2)

        // Gain %: Blue = positive,  Red = negative
        if iGainPct > 0
            wGain.setForeground(brushBlue)     // brushBlue from Stock-DrawChart.ring
        elseif iGainPct < 0
            wGain.setForeground(brushRed)
        ok

        // Months Held: Blue when >= 3 (long conviction hold)
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

Return

// ============================================================
// Fmt2(n)
//   Format a number to exactly 2 decimal places.
//   e.g.  257      => "257.00"
//         118.1    => "118.10"
//         515.84   => "515.84"
//         0.5      => "0.50"
// ============================================================

Func Fmt2(n)

    // Round to nearest cent
    nRounded = ceil(n * 100) / 100

    // Convert to string
    cStr = "" + nRounded

    // Find decimal point
    dotPos = subStr(cStr, ".")

    if dotPos = 0
        // No decimal point at all -- append ".00"
        return cStr + ".00"
    ok

    // How many digits after the dot?
    decimals = len(cStr) - dotPos

    if decimals = 0
        // Dot is at the end e.g. "257."
        return cStr + "00"
    elseif decimals = 1
        // Only one decimal digit e.g. "118.1"
        return cStr + "0"
    else
        // Two or more -- take exactly two
        return subStr(cStr, 1, dotPos + 2)
    ok

