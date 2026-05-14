// ============================================================
// Stock-StockContrib.ring
// Bert Mariani  2025
//
// "Stock Contributions" Tab
//
// Left Panel:  "Top 20 by Compound Gain"
//              Horizontal bar chart using qpicture/qpainter
//              (same pattern as Stock-AlgoGrid.ring DrawHeatmap)
//
// Right Panel: "Full Stock Table"
//              QTableWidget: Ticker | Appearances | Avg Mo Gain% | Compound Gain%
//
// Data sources (globals from Stock-YearlyReturns.ring):
//   gList  -- per-stock monthly gain ratios  (rows=stocks, cols=months)
//   mList  -- last col = each stock's compound multiplier
//   aList  -- col-1 = ticker names
//   $RangeMth, $Top10
// ============================================================

oContribTab       = null
oContribBarLabel  = null      // QLabel canvas for bar chart (qpicture target)
oContribTable     = null
aContribData      = []        // [[sym, appearances, avgMoGain%, compoundGain%], ...]

// Extra colors/pens/brushes needed here
// (all globals from Stock-DrawChart.ring already available:
//  colorBlack colorWhite colorBlue colorGreen colorGray
//  penBlack penBlue penGray brushWhite brushBlack brushGreen brushBlue)

colorDkGreen  = new qcolor() { setrgb( 34, 139,  34, 255) }
penDkGreen    = new qpen()   { setcolor(colorDkGreen) setwidth(1) }
brushDkGreen  = new qbrush() { setstyle(1) setcolor(colorDkGreen) }

colorLtGray   = new qcolor() { setrgb(200, 200, 200, 255) }
penLtGray     = new qpen()   { setcolor(colorLtGray) setwidth(1) }

colorDkBlue   = new qcolor() { setrgb(  0,   0, 180, 255) }
brushDkBlue   = new qbrush() { setstyle(1) setcolor(colorDkBlue) }

// ============================================================
// BuildStockContribTab(tabWidget)
// ============================================================

Func BuildStockContribTab(tabWidget)

    oContribTab = new QWidget()
    hSplit      = new QHBoxLayout()
    hSplit.setSpacing(8)

    // ---- LEFT PANEL ----------------------------------------
    leftFrame = new QFrame(win, 0)
    leftFrame.setFrameShape(QFrame_StyledPanel)
    leftVLay  = new QVBoxLayout()
    leftVLay.setSpacing(4)

    lblLeft = new QLabel(win)
    lblLeft.setText("Top 20 by Compound Gain")
    lblLeft.setStyleSheet(
        "color:#007acc; font-weight:bold; font-size:14px; " +
        "border:2px solid #007acc; padding:3px 6px;")
    lblLeft.setMaximumHeight(34)
    leftVLay.addWidget(lblLeft)

    oContribBarLabel = new QLabel(win)
    oContribBarLabel.setMinimumSize(480, 500)
    oContribBarLabel.setStyleSheet("background-color:#ffffff;")
    leftVLay.addWidget(oContribBarLabel)

    leftFrame.setLayout(leftVLay)

    // ---- RIGHT PANEL ----------------------------------------
    rightFrame = new QFrame(win, 0)
    rightFrame.setFrameShape(QFrame_StyledPanel)
    // rightFrame width determined by equal stretch
    rightVLay  = new QVBoxLayout()
    rightVLay.setSpacing(4)

    lblRight = new QLabel(win)
    lblRight.setText("Full Stock Table")
    lblRight.setStyleSheet(
        "color:#007acc; font-weight:bold; font-size:14px; " +
        "border:2px solid #007acc; padding:3px 6px;")
    lblRight.setMaximumHeight(34)
    rightVLay.addWidget(lblRight)

    oContribTable = new QTableWidget(win)
    oContribTable.setColumnCount(4)
    oContribTable.setRowCount(0)
    oContribTable.setEditTriggers(0)
    oContribTable.setStyleSheet(
        "QTableWidget { color:#000000; font-weight:normal; font-size:14px; " +
        "background-color:#ffffff; alternate-background-color:#f0f4f8; gridline-color:#cccccc; }" +
        "QHeaderView::section { background-color:#2b2b2b; color:#ffffff; " +
        "font-weight:bold; font-size:14px; padding:4px; border:1px solid #555; }" )

    oHdrs = new QStringList()
    oHdrs.append("Ticker")
    oHdrs.append("Appearances")
    oHdrs.append("Avg Mo Gain%")
    oHdrs.append("Compound Gain%")
    oContribTable.setHorizontalHeaderLabels(oHdrs)
    oContribTable.horizontalHeader().setStretchLastSection(true)
    oContribTable.setAlternatingRowColors(true)
    oContribTable.setColumnWidth(0,  75)   // Ticker
    oContribTable.setColumnWidth(1, 100)   // Appearances
    oContribTable.setColumnWidth(2, 115)   // Avg Mo Gain%
    oContribTable.setColumnWidth(3, 130)   // Compound Gain%

    rightVLay.addWidget(oContribTable)
    rightFrame.setLayout(rightVLay)

    // ---- Assemble ------------------------------------------
    hSplit.addWidget(leftFrame)
    hSplit.addWidget(rightFrame)
    hSplit.setStretch(0, 4)  // left wider
    hSplit.setStretch(1, 3)  // right narrower

    oContribTab.setLayout(hSplit)
    tabWidget.addTab(oContribTab, "Stock Contributions")

Return oContribTab


// ============================================================
// CalcContribData()
//   Walk gList to compute per-stock:
//     appearances  = months stock had a non-zero gain entry
//     avgMoGain%   = mean monthly gain %
//     compoundGain%= (product of gain ratios - 1) * 100
//   Sort descending by compoundGain%.
// ============================================================

Func CalcContribData()

    aContribData = []

    if len(gList) < 2     return   ok
    if ! islist(gList[1]) return   ok

    nGRow = len(gList)
    nGCol = len(gList[1])

    for r = 1 to nGRow

        sym = gList[r][1]
        if sym = "" OR sym = "TOT" OR sym = "QQQ" OR sym = "SPY"   loop   ok
        if len(sym) = 0   loop   ok

        appearances = 0
        sumGain     = 0
        compound    = 1.0

        for c = $RangeMth + 2 to nGCol
            g = 0 + gList[r][c]
            if g > 0.01                  // non-zero ratio means stock was held
                appearances++
                pct      = (g - 1) * 100
                sumGain += pct
                compound *= g
            ok
        next

        if appearances = 0   loop   ok

        avgMoGain = sumGain / appearances
        compGain  = (compound - 1) * 100

        Add(aContribData, [sym, appearances, avgMoGain, compGain])
    next

    // Sort descending by compoundGain% -- bubble sort
    nC = len(aContribData)
    for i = 1 to nC - 1
        for j = 1 to nC - i
            if aContribData[j][4] < aContribData[j+1][4]
                tmp               = aContribData[j]
                aContribData[j]   = aContribData[j+1]
                aContribData[j+1] = tmp
            ok
        next
    next

Return


// ============================================================
// DrawContribBars()
//   Paint horizontal bar chart using qpicture + qpainter
//   Follows exact pattern of DrawHeatmap() in Stock-AlgoGrid.ring:
//     p1 = new qpicture()
//     new qpainter() { begin(p1) ... endpaint() }
//     oLabel{ setpicture(p1) show() }
// ============================================================

Func DrawContribBars()

    if oContribBarLabel = null    return   ok
    if len(aContribData) = 0     return   ok

    w = oContribBarLabel.width()
    h = oContribBarLabel.height()
    if w < 50 OR h < 50   return   ok

    // Top-20 slice
    nBars = 20
    if len(aContribData) < nBars   nBars = len(aContribData)   ok

    // Layout margins
    mLeft   = 55    // ticker labels
    mRight  = 65    // % value labels
    mTop    = 36
    mBottom = 36

    barAreaW = w - mLeft - mRight
    barAreaH = h - mTop  - mBottom
    barH     = floor(barAreaH / nBars) - 3
    if barH < 6    barH = 6    ok
    if barH > 26   barH = 26   ok
    gap      = floor((barAreaH - nBars * barH) / nBars)
    if gap < 1   gap = 1   ok

    // Max compound gain for x-axis scaling
    maxGain = 1
    for i = 1 to nBars
        if aContribData[i][4] > maxGain   maxGain = aContribData[i][4]   ok
    next

    // Round maxGain up to nearest 200 so bars fill the area
    axisMax = ceil(maxGain / 200) * 200
    if axisMax < 200   axisMax = 200   ok
	

    p1 = new qpicture()

    new qpainter() {
        begin(p1)
        setRenderHint(QPainter_Antialiasing, false)

        // White background
        fillRect(0, 0, w, h, brushWhite)

        // ---- Chart title ----
        setPen(penBlack)
        drawText( mLeft + barAreaW/2 - 120, 22, "Stock Compound Gains (Best Algorithm)")

        // ---- X-axis grid lines and labels ----
        nGridLines = 5
        for g = 0 to nGridLines
            gx   = mLeft + floor(g * barAreaW / nGridLines)
            gPct = floor(g * axisMax / nGridLines)

            setPen(penLtGray)
            drawLine(gx, mTop, gx, mTop + barAreaH)

            setPen(penBlack)
            gStr = "" + gPct + "%"
            drawText(gx - 12, mTop + barAreaH + 18, gStr)
        next

        // X-axis footer label
        setPen(penBlack)
        drawText(mLeft + barAreaW/2 - 50, h - 6, "Compound Gain %")

        // ---- Bars ----
        for i = 1 to nBars

            sym      = aContribData[i][1]
            compGain = aContribData[i][4]

            barW = floor(compGain / axisMax * barAreaW)
            if barW < 2   barW = 2   ok

            yTop  = mTop + (i - 1) * (barH + gap)
            xLeft = mLeft

            // Ticker label -- right-aligned in left margin
            setPen(penBlack)
            drawText(2, yTop + barH/2 + 4, sym)

            // Green filled bar
            fillRect(xLeft, yTop, barW, barH, brushDkGreen)

            // Bar border
            setPen(penDkGreen)
            drawRect(xLeft, yTop, barW, barH)

            // % label right of bar
            setPen(penBlack)
            gainStr = "" + floor(compGain * 10) / 10 + "%"
            drawText(xLeft + barW + 4, yTop + barH/2 + 4, gainStr)

        next

        endpaint()
    }

    oContribBarLabel { setpicture(p1)  show() }

Return


// ============================================================
// PopulateContribTable()
//   Fill the right-panel QTableWidget from aContribData.
// ============================================================

Func PopulateContribTable()

    if oContribTable = null   return   ok

    nD = len(aContribData)
    oContribTable.setRowCount(nD)

    for i = 1 to nD

        rec    = aContribData[i]
        iSym   = rec[1]
        iApp   = rec[2]
        iAvgMo = rec[3]
        iComp  = rec[4]

        wSym  = new QTableWidgetItem("zx")
        wApp  = new QTableWidgetItem("zx")
        wAvg  = new QTableWidgetItem("zx")
        wComp = new QTableWidgetItem("zx")

        wSym.setText("" + iSym)
        wApp.setText("" + iApp)
        wAvg.setText(Fmt2(iAvgMo) + "%")
        wComp.setText(Fmt2(iComp) + "%")

        // Right-justify numeric columns
        wApp.setTextAlignment(0x0082)
        wAvg.setTextAlignment(0x0082)
        wComp.setTextAlignment(0x0082)

        // Default all black
        wSym.setForeground(brushBlack)
        wApp.setForeground(brushBlack)
        wAvg.setForeground(brushBlack)
        wComp.setForeground(brushBlack)

        // Ticker in blue
        wSym.setForeground(brushBlue)

        // Positive gains in green
        if iAvgMo > 0   wAvg.setForeground(brushBlue)   ok
        if iComp  > 0   wComp.setForeground(brushBlue)  ok

        oContribTable.setItem(i-1, 0, wSym)
        oContribTable.setItem(i-1, 1, wApp)
        oContribTable.setItem(i-1, 2, wAvg)
        oContribTable.setItem(i-1, 3, wComp)
    next

Return


// ============================================================
// RefreshStockContribTab()
//   Called from RunAnalysis() after gList/mList are populated.
// ============================================================

Func RefreshStockContribTab()

    if oContribTab = null     return   ok
    if len(gList)  < 2        return   ok
    if ! islist(gList[1])     return   ok

    CalcContribData()
    DrawContribBars()
    PopulateContribTable()

    App.processEvents()

Return
