// ============================================================
// Stock-YearlyVsQQQ.ring
// Bert Mariani  2025
// ============================================================

// Globals
oYearlyTab   = null
oYearlyChart = null
oYearlyTable = null
aYearData    = []

// ============================================================
// DrawYearly() - plain function, paints directly on oYearlyChart
// Uses brushWhite, brushBlue from Stock-DrawChart.ring globals
// ============================================================

Func DrawYearly()

    if oYearlyChart = null   return   ok

    w = oYearlyChart.width()
    h = oYearlyChart.height()
    if w < 10 or h < 10   return   ok

    // Layout
    mLeft   = 65
    mRight  = 15
    mTop    = 45
    mBottom = 50
    plotW   = w - mLeft - mRight
    plotH   = h - mTop  - mBottom
    nYears  = len(aYearData)

    if nYears = 0
        p1 = new qpicture()
        new qpainter() { begin(p1) fillRect(0,0,w,h,brushWhite) endpaint() }
        oYearlyChart{ setpicture(p1) show() }
        return
    ok

    // Find min/max across all returns
    vMax = -9999   vMin = 9999
    for yi = 1 to nYears
        v2 = aYearData[yi][2]
        v3 = aYearData[yi][3]
        v4 = aYearData[yi][4]
        if v2 > vMax  vMax = v2  ok   if v2 < vMin  vMin = v2  ok
        if v3 > vMax  vMax = v3  ok   if v3 < vMin  vMin = v3  ok
        if v4 > vMax  vMax = v4  ok   if v4 < vMin  vMin = v4  ok
    next
    if vMax < 10    vMax = 10   ok
    if vMin > -10   vMin = -10  ok
    vMax   = vMax * 1.18
    if vMin < 0   vMin = vMin * 1.18   ok
    vRange = vMax - vMin
    if vRange = 0   vRange = 1   ok

    // Zero line Y
    zeroY = mTop + plotH * (1.0 - (-vMin / vRange))

    // Bar dimensions
    gap    = 6
    groupW = plotW / nYears
    barW   = (groupW - gap * 2) / 3 - 1

    // SPY brush (orange) - defined inline since not in DrawChart globals
    colorSPY2  = new qcolor()
    colorSPY2.setrgb(200, 100, 0, 255)
    brushSPY2  = new qbrush()
    brushSPY2.setstyle(1)
    brushSPY2.setcolor(colorSPY2)

    p1 = new qpicture()

    new qpainter() {
        begin(p1)
        setRenderHint(QPainter_Antialiasing, true)

        // White background
        fillRect(0, 0, w, h, brushWhite)

        // Grid lines
        setPen(penGrid)
        nGrid = 5
        for g = 0 to nGrid
            gy   = mTop + g * plotH / nGrid
            gVal = vMax - g * vRange / nGrid
            drawLine(mLeft, gy, mLeft + plotW, gy)
            setPen(penBlack)
            setFont(new qfont("Arial", 10, 50, 0))
            drawText(2, gy + 4, "" + ceil(gVal) + "%")
            setPen(penGrid)
        next

        // Zero line
        setPen(penBlack)
        drawLine(mLeft, zeroY, mLeft + plotW, zeroY)

        // Bars
        for yi = 1 to nYears
            portPct = aYearData[yi][2]
            qqqPct  = aYearData[yi][3]
            spyPct  = aYearData[yi][4]
            cYear   = aYearData[yi][1]
            bYTD    = aYearData[yi][7]

            groupX  = mLeft + (yi - 1) * groupW + gap

            // Portfolio bar - Blue
            barH = fabs(portPct) / vRange * plotH
            if portPct >= 0   barY = zeroY - barH   else   barY = zeroY   ok
            fillRect(groupX,              barY, barW, barH+1, brushBlue)

            // QQQ bar - Gray
            barH = fabs(qqqPct) / vRange * plotH
            if qqqPct >= 0    barY = zeroY - barH   else   barY = zeroY   ok
            fillRect(groupX + barW + 1,   barY, barW, barH+1, brushGray)

            // SPY bar - Orange
            barH = fabs(spyPct) / vRange * plotH
            if spyPct >= 0    barY = zeroY - barH   else   barY = zeroY   ok
            fillRect(groupX + (barW+1)*2, barY, barW, barH+1, brushSPY2)

            // Year label
            setPen(penBlack)
            setFont(new qfont("Arial", 10, 50, 0))
            cYLbl = cYear
            if bYTD = 1   cYLbl = cYear + " YTD"   ok
            lx = groupX + groupW / 2 - 24
            drawText(lx, h - mBottom + 18, cYLbl)
        next

        // Legend
        setFont(new qfont("Arial", 10, 50, 0))
        fillRect(mLeft+10,       mTop-28, 16, 10, brushBlue)
        fillRect(mLeft+10+80,    mTop-28, 16, 10, brushGray)
        fillRect(mLeft+10+155,   mTop-28, 16, 10, brushSPY2)
        setPen(penBlack)
        drawText(mLeft+30,       mTop-19, "Portfolio")
        drawText(mLeft+10+100,   mTop-19, "QQQ")
        drawText(mLeft+10+175,   mTop-19, "SPY")

        // Chart title
        setFont(new qfont("Arial", 11, 75, 0))
        drawText(mLeft + plotW/2 - 130, mTop - 8,
                 "Calendar Year Returns  (Portfolio / QQQ / SPY)")

        endpaint()
    }

    oYearlyChart{ setpicture(p1) show() }

Return

// ============================================================

Func FormatPct(n)
    s = "" + ceil(n)
    if n >= 0
        return "+" + s + "%"
    ok
    return s + "%"

Func PctColor(n)
    if n >= 0   return "#00cc00"   ok
    return "#ff4444"



// SPY bar color - orange (DrawChart has no orange brush)
colorSPY2 = new qcolor() { setrgb(200, 100, 0, 255) }
brushSPY2 = new qbrush() { setstyle(1) setcolor(colorSPY2) }

Func BuildYearlyTab(tabWidget)

    oYearlyTab = new QWidget()

    hSplit = new QHBoxLayout()

    # ---- LEFT: chart frame ----
    chartFrame = new QFrame(win, 0)
    chartFrame.setFrameShape(QFrame_StyledPanel)
    chartFrameLayout = new QVBoxLayout()

    lblChartTitle = new QLabel(win)
    lblChartTitle.setText("Annual Return: Portfolio vs QQQ vs SPY")
    lblChartTitle.setStyleSheet("color: #0000cc; font-weight: bold; font-size: 14px;")
    lblChartTitle.setMaximumHeight(28)
    chartFrameLayout.addWidget(lblChartTitle)

    oYearlyChart = new QLabel(win)
    chartFrameLayout.addWidget(oYearlyChart)
    chartFrame.setLayout(chartFrameLayout)

    # ---- RIGHT: table frame ----
    tableFrame = new QFrame(win, 0)
    tableFrame.setFrameShape(QFrame_StyledPanel)
    tableFrame.setFixedWidth(500)                      // (430)
    tableFrameLayout = new QVBoxLayout()

    lblTableTitle = new QLabel(win)
    lblTableTitle.setText("Year-by-Year Results")
	
	
    lblTableTitle.setStyleSheet("color: #0000cc; font-weight: bold; font-size: 16px;")   // #0000cc 14px
	

    lblTableTitle.setMaximumHeight(28)
    tableFrameLayout.addWidget(lblTableTitle)

    oYearlyTable = new QTableWidget(win)
    oYearlyTable.setColumnCount(6)
    oYearlyTable.setRowCount(0)
    oHeaderLabels = new QStringList()
	
    oHeaderLabels.append("Year")
    oHeaderLabels.append("Portfolio")
    oHeaderLabels.append("QQQ %")
    oHeaderLabels.append("SPY %")
    oHeaderLabels.append("vs QQQ")
    oHeaderLabels.append("vs SPY")
	
    oYearlyTable.setHorizontalHeaderLabels(oHeaderLabels)
    oYearlyTable.horizontalHeader().setStretchLastSection(true)
    oYearlyTable.setEditTriggers(0)
    oYearlyTable.setAlternatingRowColors(false)
	
    oYearlyTable.setStyleSheet("
        QTableWidget {
            background-color: #eeeef6;  // #1a1a2e;
            color: #00ff00;
            gridline-color: #333366;
            font-size: 14px;
            font-family: Consolas, monospace;
        }
        QHeaderView::section {
            background-color: #16213e;
            color: #aaaaff;
            font-weight: bold;
            font-size: 14px;
            padding: 4px;
            border: 1px solid #333366;
        }
        QTableWidget::item { padding: 3px 6px; }
    ")
	
    oYearlyTable.setColumnWidth(0, 70)
    oYearlyTable.setColumnWidth(1, 80)
    oYearlyTable.setColumnWidth(2, 65)
    oYearlyTable.setColumnWidth(3, 65)
    oYearlyTable.setColumnWidth(4, 70)
    oYearlyTable.setColumnWidth(5, 70)
    tableFrameLayout.addWidget(oYearlyTable)
    tableFrame.setLayout(tableFrameLayout)

    hSplit.addWidget(chartFrame)
    hSplit.addWidget(tableFrame)
    hSplit.setStretch(0, 3)         // 0, 3
    hSplit.setStretch(1, 0)         // 1, 0
    oYearlyTab.setLayout(hSplit)

    tabWidget.addTab(oYearlyTab, "Yearly vs QQQ")

Return oYearlyTab


// ============================================================

Func RefreshYearlyTab()

    if oYearlyChart = null   return  ok

    aYearData = CalcYearlyReturns()
	
    DrawYearly()
    PopulateYearlyTable(aYearData)

Return


Func CalcYearlyReturns()

    aYearData = []

    if len(aTDate) < 2   return aYearData   ok

    // Find QQQ and SPY rows in aList
    posQQQ = 0   posSPY = 0
    for r = 1 to len(aList)
        if aList[r][1] = "QQQ"  posQQQ = r  ok
        if aList[r][1] = "SPY"  posSPY = r  ok
    next
    if posQQQ = 0   return aYearData   ok

    nAListCols = len(aList[posQQQ])
    nDates     = len(aTDate)
    nST        = len(aSumTotal[3])

    // Detect colOffset from leading duplicate price columns
    colOffset  = 3
    firstPrice = "" + aList[posQQQ][2]
    for c = 3 to nAListCols
        if ("" + aList[posQQQ][c]) != firstPrice
            colOffset = c - 2
            break
        ok
    next

    // lastRealCol excludes bogus extra column appended after aTDate was built
    lastRealCol = nDates + colOffset
    if lastRealCol > nAListCols   lastRealCol = nAListCols   ok

    // -------------------------------------------------------
    // Build janCols: map year -> aList column of January price
    // aTDate[i] = "dd/mm/yyyy", aList col = i + colOffset
    // -------------------------------------------------------
    janCols  = []   // list of [cYear, aListCol]
    for i = 1 to nDates
        aParts = split(aTDate[i], "/")
        cMon   = aParts[2]
        cYear  = aParts[3]
        if cMon = "01"
            Add(janCols, [cYear, i + colOffset])
        ok
    next

    if len(janCols) < 1   return aYearData   ok

    // -------------------------------------------------------
    // Build year entries: Jan-to-Jan for complete years, Jan-to-now for YTD
    // -------------------------------------------------------
    aYearMap = []
    nJan     = len(janCols)

    for j = 1 to nJan
        cYear  = janCols[j][1]
        scCol  = janCols[j][2]         // Jan 1 of this year

        if j < nJan
            // Complete year: Jan this year to Jan next year
            ecCol  = janCols[j+1][2]   // Jan 1 of next year
            bYTD   = 0
        else
            // Last January found: YTD to lastRealCol
            ecCol  = lastRealCol
            bYTD   = 1
        ok

        Add(aYearMap, [cYear, scCol, ecCol, bYTD])
    next

    // -------------------------------------------------------
    // Calculate returns for each year using aList prices directly
    // -------------------------------------------------------
    for entry in aYearMap
        cYear  = entry[1]
        scCol  = entry[2]
        ecCol  = entry[3]
        bYTD   = entry[4]

        // Clamp
        if scCol < 2            scCol = 2            ok
        if scCol > lastRealCol  scCol = lastRealCol  ok
        if ecCol > lastRealCol  ecCol = lastRealCol  ok
        if ecCol < scCol        ecCol = scCol        ok

        // QQQ return: Jan price to Jan-next (or latest) price
        qStart = 0 + aList[posQQQ][scCol]
        qEnd   = 0 + aList[posQQQ][ecCol]
        if qStart < 0.01   qStart = qEnd    ok
        if qEnd   < 0.01   qEnd   = qStart  ok
        if qStart = 0      qStart = 1       ok
        qqqPct = (qEnd / qStart - 1) * 100

        // SPY return
        spyPct = 0
        if posSPY > 0
            nSCols = len(aList[posSPY])
            sc2 = scCol   ec2 = ecCol
            if sc2 > nSCols  sc2 = nSCols  ok
            if ec2 > nSCols  ec2 = nSCols  ok
            sStart = 0 + aList[posSPY][sc2]
            sEnd   = 0 + aList[posSPY][ec2]
            if sStart < 0.01  sStart = sEnd    ok
            if sEnd   < 0.01  sEnd   = sStart  ok
            if sStart = 0     sStart = 1        ok
            spyPct = (sEnd / sStart - 1) * 100
        ok

        // Portfolio return from aSumTotal[3]
        // aSumTotal[k] = value at aList col (k+1), so col c -> index c-1
        portPct = 0
        nCRow   = len(cList)
        if nCRow > 0
            nCCols = len(cList[nCRow])

            // Start: scCol-1 = end of previous year (Dec compound value)
            // cList[k] records gain from buying at col k, selling at k+1
            // So year start = last compound value BEFORE this year's January
            portStartCol = scCol - 1
            if portStartCol < 2   portStartCol = 2   ok
            tStart = 0 + cList[nCRow][portStartCol]
            if tStart < 0.0001
                for fwd = portStartCol to nCCols
                    tStart = 0 + cList[nCRow][fwd]
                    if tStart > 0.0001   exit   ok
                next
            ok

            // End: walk backward from ecCol to find last non-zero
            tEnd = 0 + cList[nCRow][ecCol]
            if tEnd < 0.0001
                for bk = ecCol to 1 step -1
                    tEnd = 0 + cList[nCRow][bk]
                    if tEnd > 0.0001   exit   ok
                next
            ok

            if tStart > 0.0001
                portPct = (tEnd / tStart - 1) * 100
            ok
        ok
        vsQQQ = portPct - qqqPct
        vsSPY = portPct - spyPct

        Add(aYearData, [cYear, portPct, qqqPct, spyPct, vsQQQ, vsSPY, bYTD])
    next

Return aYearData

Func PopulateYearlyTable(aYearData)

    if oYearlyTable = null   return  ok

    oYearlyTable.setRowCount(0)
    oYearlyTable.setRowCount(len(aYearData))

    for r = 1 to len(aYearData)
        row     = aYearData[r]
        cYear   = row[1]
        portPct = row[2]
        qqqPct  = row[3]
        spyPct  = row[4]
        vsQQQ   = row[5]
        vsSPY   = row[6]
        bYTD    = row[7]

        cYearLbl = cYear
        if bYTD = 1   cYearLbl = cYear + " YTD"   ok

        cPort = FormatPct(portPct)
        cQQQ  = FormatPct(qqqPct)
        cSPY  = FormatPct(spyPct)
        cVQ   = FormatPct(vsQQQ)
        cVS   = FormatPct(vsSPY)

                oItemFont = new qfont("Arial", 12, 50, 0)

        YearItem = new QTableWidgetItem("1Year")
        YearItem.setText(cYearLbl)
        YearItem.setForeground(brushBlack)
        YearItem.setTextAlignment(0x0082)
        YearItem.setFont(oItemFont)

        PortItem = new QTableWidgetItem("2Port")
        PortItem.setText(cPort)
        if portPct >= 0   PortItem.setForeground(brushBlue)   else   PortItem.setForeground(brushRed)   ok
        PortItem.setTextAlignment(0x0082)
        PortItem.setFont(oItemFont)

        QQQItem = new QTableWidgetItem("3QQQ")
        QQQItem.setText(cQQQ)
        if qqqPct >= 0   QQQItem.setForeground(brushBlue)   else   QQQItem.setForeground(brushRed)   ok
        QQQItem.setTextAlignment(0x0082)
        QQQItem.setFont(oItemFont)

        SPYItem = new QTableWidgetItem("4SPY")
        SPYItem.setText(cSPY)
        if spyPct >= 0   SPYItem.setForeground(brushBlue)   else   SPYItem.setForeground(brushRed)   ok
        SPYItem.setTextAlignment(0x0082)
        SPYItem.setFont(oItemFont)

        VQItem = new QTableWidgetItem("5VQ")
        VQItem.setText(cVQ)
        if vsQQQ >= 0   VQItem.setForeground(brushBlue)   else   VQItem.setForeground(brushRed)   ok
        VQItem.setTextAlignment(0x0082)
        VQItem.setFont(oItemFont)

        VSItem = new QTableWidgetItem("6VS")
        VSItem.setText(cVS)
        if vsSPY >= 0   VSItem.setForeground(brushBlue)   else   VSItem.setForeground(brushRed)   ok
        VSItem.setTextAlignment(0x0082)
        VSItem.setFont(oItemFont)

        oYearlyTable.setItem(r-1, 0, YearItem)
        oYearlyTable.setItem(r-1, 1, PortItem)
        oYearlyTable.setItem(r-1, 2, QQQItem)
        oYearlyTable.setItem(r-1, 3, SPYItem)
        oYearlyTable.setItem(r-1, 4, VQItem)
        oYearlyTable.setItem(r-1, 5, VSItem)
    next

Return
