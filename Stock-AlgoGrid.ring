// ============================================================
// Stock-AlgoGrid.ring
// Bert Mariani  2025
// Algorithm Grid Tab: RangeMth x TopK heatmap + sorted config table
//
// Implements backtest() directly from aList prices - matching
// the Python Stock_Analysis_GUI.py backtest() function exactly.
// No YearlyReturns functions called - no list corruption issues.
// ============================================================

// Globals
oAlgoTab        = null
oHeatmapLabel   = null
oConfigTable    = null
aGridResults    = []
aConfigList     = []

aGridRangeMth   = [3, 5, 6, 7, 9, 12]
aGridTopK       = [5, 7, 10, 12, 15, 20]
nGridBestRM     = 0
nGridBestTK     = 0
nGridBestRet    = 0

// ============================================================
// BuildAlgoGridTab(tabWidget)
// ============================================================

Func BuildAlgoGridTab(tabWidget)

    oAlgoTab = new QWidget()

    hSplit = new QHBoxLayout()

    // LEFT: heatmap frame
    heatFrame = new QFrame(win, 0)
    heatFrame.setFrameShape(QFrame_StyledPanel)
    heatLayout = new QVBoxLayout()

    lblHeatTitle = new QLabel(win)
    lblHeatTitle.setText("Total Return Heatmap (RangeMth × TopK)")
    lblHeatTitle.setStyleSheet("color: #007acc; font-weight: bold; font-size: 14px;")
    lblHeatTitle.setMaximumHeight(30)
    heatLayout.addWidget(lblHeatTitle)

    oHeatmapLabel = new QLabel(win)
    oHeatmapLabel.setMinimumSize(400, 350)
    heatLayout.addWidget(oHeatmapLabel)
    heatFrame.setLayout(heatLayout)

    // RIGHT: config table frame
    tableFrame = new QFrame(win, 0)
    tableFrame.setFrameShape(QFrame_StyledPanel)
    tableFrame.setFixedWidth(480)
    tableLayout = new QVBoxLayout()

    lblTableTitle = new QLabel(win)
    lblTableTitle.setText("All Configurations")
    lblTableTitle.setStyleSheet("color: #007acc; font-weight: bold; font-size: 14px;")
    lblTableTitle.setMaximumHeight(30)
    tableLayout.addWidget(lblTableTitle)

    oConfigTable = new QTableWidget(win)
    oConfigTable.setColumnCount(6)
    oConfigTable.setRowCount(0)

    oConfigHeaders = new QStringList()
    oConfigHeaders.append("RangeMth")
    oConfigHeaders.append("TopK")
    oConfigHeaders.append("Total Ret%")
    oConfigHeaders.append("QQQ Ret%")
    oConfigHeaders.append("Ratio")
    oConfigHeaders.append("CAGR%")
    oConfigTable.setHorizontalHeaderLabels(oConfigHeaders)
    oConfigTable.horizontalHeader().setStretchLastSection(true)
    oConfigTable.setEditTriggers(0)

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
	
	oConfigTable.setColumnWidth(0, 75)
    oConfigTable.setColumnWidth(1, 52)
    oConfigTable.setColumnWidth(2, 82)
    oConfigTable.setColumnWidth(3, 75)
    oConfigTable.setColumnWidth(4, 60)
    oConfigTable.setColumnWidth(5, 60)

    tableLayout.addWidget(oConfigTable)
    tableFrame.setLayout(tableLayout)

    hSplit.addWidget(heatFrame)
    hSplit.addWidget(tableFrame)
    hSplit.setStretch(0, 3)
    hSplit.setStretch(1, 0)
    oAlgoTab.setLayout(hSplit)

    tabWidget.addTab(oAlgoTab, "Algorithm Grid")

Return oAlgoTab

// ============================================================
// GridBacktest(rm, tk) -> [totalRetPct, qqqRetPct, ratio, cagr]
//
// Direct implementation matching Python backtest():
// - Ranks stocks each month by perf = price[col] / price[col-rm]
// - Buys top tk stocks, sells next month
// - Compounds average monthly gain
// ============================================================

Func GridBacktest(rm, tk)

    nRows    = len(aList)
    nCols    = len(aList[1])   // includes symbol col 1, prices col 2..nCols

    // Find QQQ row
    posQQQ3 = 0
    for r = 1 to nRows
        if aList[r][1] = "QQQ"   posQQQ3 = r   ok
    next

    // Python: start = range_mth + 1 (0-indexed row)
    // Ring:   startCol = rm + 2     (1-indexed, col1=symbol, col2=first price)
    startCol = rm + 2
    if startCol > nCols - 1   return [0, 0, 0, 0]   ok

    compound   = 1.0
    qqqStart   = 0 + aList[posQQQ3][startCol]
    nMonths    = 0

    // Loop: col = startCol to nCols-1
    // At col: rank by perf = price[col]/price[col-rm]
    // Gain:   price[col+1]/price[col] for top tk stocks
	
    for col = startCol to nCols - 1

        // --- Rank all stocks by performance over last rm months
        // perf = price[col] / price[col - rm]
        lookCol = col - rm

        aPerf = []    // [perf_ratio, row_index]
        for r = 1 to nRows
		
		
		
            if aList[r][1] != "QQQ" AND 
			   aList[r][1] != "SPY" AND 
			   aList[r][1] != "Date" AND
			   len(aList[r][1]) > 0
			   
                nRCols2  = len(aList[r])
                if lookCol < 2         lookCol2 = 2          else   lookCol2 = lookCol   ok
                if lookCol2 > nRCols2  lookCol2 = nRCols2   ok
                colEnd2 = col
                if colEnd2 > nRCols2   colEnd2 = nRCols2    ok
				
                pStart2 = 0 + aList[r][lookCol2]
                pEnd2   = 0 + aList[r][colEnd2]
				
                if pStart2 > 0.01
                    perf2 = pEnd2 / pStart2
                else
                    perf2 = 0
                ok
                Add(aPerf, [perf2, r])
            ok
        next

        // --- Sort aPerf descending by perf (simple selection of top tk)
        // Use partial selection sort - only need top tk
        nPerf = len(aPerf)
        for i = 1 to tk
            if i > nPerf   exit   ok
            maxIdx = i
            for j = i+1 to nPerf
                if aPerf[j][1] > aPerf[maxIdx][1]
                    maxIdx = j
                ok
            next
            if maxIdx != i
                tmp        = aPerf[i]
                aPerf[i]   = aPerf[maxIdx]
                aPerf[maxIdx] = tmp
            ok
        next

        // --- Buy top tk stocks at price[col], sell at price[col+1]
        gainSum = 0
        gainCnt = 0
        for i = 1 to tk
            if i > nPerf   exit   ok
            r2      = aPerf[i][2]
            nR2Cols = len(aList[r2])
            if col > nR2Cols     loop   ok   // skip this stock, try next
            sellCol = col + 1
            if sellCol > nR2Cols   sellCol = nR2Cols   ok
            buy2  = 0 + aList[r2][col]
            sell2 = 0 + aList[r2][sellCol]
            if buy2 > 0.01
                gainSum = gainSum + (sell2 / buy2)
                gainCnt++
            ok
        next

        if gainCnt > 0
            avgGain  = gainSum / gainCnt
            compound = compound * avgGain
            nMonths++
        ok

    next

    // Total return
    totalRet = (compound - 1) * 100
###    See "  Backtest rm="+rm+" tk="+tk+" months="+nMonths+" compound="+ceil(compound)+" ret="+ ceil(totalRet)+"%"+nl

    // QQQ return over same period
    qqqEnd3 = 0 + aList[posQQQ3][nCols]
    qqqRet3 = 0
    if qqqStart > 0.01
        qqqRet3 = (qqqEnd3 / qqqStart - 1) * 100
    ok

    // Ratio
    ratio3 = 0
    if qqqRet3 != 0   ratio3 = totalRet / qqqRet3   ok

    // CAGR: compound^(12/months) - 1
    cagr3 = 0
    if nMonths > 0
        cagr3 = (pow(compound, 12.0 / nMonths) - 1) * 100
    ok

Return [totalRet, qqqRet3, ratio3, cagr3]

// ============================================================
// RunAlgoGrid()
// ============================================================

Func RunAlgoGrid()

    if oHeatmapLabel = null   return   ok

    nRM = len(aGridRangeMth)
    nTK = len(aGridTopK)

    // Init results grid
    aGridResults = []
    for r = 1 to nRM
        aRow = []
        for c = 1 to nTK
            Add(aRow, 0)
        next
        Add(aGridResults, aRow)
    next

    aConfigList  = []
    nGridBestRet = -9999
    nGridBestRM  = 0
    nGridBestTK  = 0

    // Run all combos using direct backtest (no YearlyReturns functions)
    for ri = 1 to nRM
        rm = aGridRangeMth[ri]
        for ci = 1 to nTK
            tk = aGridTopK[ci]

            aResult = GridBacktest(rm, tk)
            totRet  = aResult[1]
            qqqRet  = aResult[2]
            ratio   = aResult[3]
            cagr    = aResult[4]

###            See "Grid rm="+rm+" tk="+tk+" ret="+ ceil(totRet)+ "% qqq="+ ceil(qqqRet) +"%"+nl

            aGridResults[ri][ci] = totRet

            if totRet > nGridBestRet
                nGridBestRet = totRet
                nGridBestRM  = rm
                nGridBestTK  = tk
            ok

            Add(aConfigList, [rm, tk, totRet, qqqRet, ratio, cagr])
        next
    next

    // Sort aConfigList descending by totRet (bubble sort)
    nCfg = len(aConfigList)
    for i = 1 to nCfg - 1
        for j = 1 to nCfg - i
            if aConfigList[j][3] < aConfigList[j+1][3]
                tmp              = aConfigList[j]
                aConfigList[j]   = aConfigList[j+1]
                aConfigList[j+1] = tmp
            ok
        next
    next

    DrawHeatmap()
    PopulateConfigTable()

    See "Grid best: RangeMth="+nGridBestRM+" TopK="+nGridBestTK+
        " ("+ceil(nGridBestRet)+"%)" +nl

Return

// ============================================================
// DrawHeatmap() - matches Python's imshow(cmap="YlOrRd")
// Yellow(low) -> Orange -> Red(high), blue border on best cell
// ============================================================

Func DrawHeatmap()

    if oHeatmapLabel = null   return   ok
    if len(aGridResults) = 0  return   ok

    w = oHeatmapLabel.width()
    h = oHeatmapLabel.height()
    if w < 50 or h < 50   return   ok

    nRM = len(aGridRangeMth)
    nTK = len(aGridTopK)

    // Find min/max for color scaling
    vMin =  999999999
    vMax = -999999999
    for ri = 1 to nRM
        for ci = 1 to nTK
            v = aGridResults[ri][ci]
            if v > vMax   vMax = v   ok
            if v < vMin   vMin = v   ok
        next
    next
    vRange = vMax - vMin
    if vRange = 0   vRange = 1   ok

    // Layout
    mLeft   = 55
    mRight  = 15
    mTop    = 40
    mBottom = 45
    plotW   = w - mLeft - mRight
    plotH   = h - mTop  - mBottom

    cellW = plotW / nTK
    cellH = plotH / nRM

    p1 = new qpicture()

    new qpainter() {
        begin(p1)
        setRenderHint(QPainter_Antialiasing, false)

        fillRect(0, 0, w, h, brushWhite)

        // Draw cells with YlOrRd colormap: yellow->orange->red
        for ri = 1 to nRM
            for ci = 1 to nTK
                v = aGridResults[ri][ci]
                t = (v - vMin) / vRange    // 0.0 = coldest, 1.0 = hottest

                // YlOrRd colormap approximation:
                // t=0.0: rgb(255,255,204)  pale yellow
                // t=0.25: rgb(254,217,142) light orange-yellow
                // t=0.5:  rgb(253,141,60)  orange
                // t=0.75: rgb(227,26,28)   red
                // t=1.0:  rgb(128,0,38)    dark red
                if t < 0.25
                    s  = t / 0.25
                    r3 = 255
                    g3 = ceil(255 - s * (255 - 217))
                    b3 = ceil(204 - s * (204 - 142))
                elseif t < 0.5
                    s  = (t - 0.25) / 0.25
                    r3 = 254
                    g3 = ceil(217 - s * (217 - 141))
                    b3 = ceil(142 - s * (142 - 60))
                elseif t < 0.75
                    s  = (t - 0.5) / 0.25
                    r3 = ceil(253 - s * (253 - 227))
                    g3 = ceil(141 - s * (141 - 26))
                    b3 = ceil(60  - s * (60  - 28))
                else
                    s  = (t - 0.75) / 0.25
                    r3 = ceil(227 - s * (227 - 128))
                    g3 = ceil(26  - s * 26)
                    b3 = ceil(28  + s * (38 - 28))
                ok

                cellColor = new qcolor()
                cellColor.setrgb(r3, g3, b3, 255)
                cellBrush = new qbrush()
                cellBrush.setstyle(1)
                cellBrush.setcolor(cellColor)

                cx = mLeft + (ci - 1) * cellW
                cy = mTop  + (ri - 1) * cellH

                fillRect(cx, cy, cellW - 1, cellH - 1, cellBrush)

                // Blue border on best cell
                if aGridRangeMth[ri] = nGridBestRM AND aGridTopK[ci] = nGridBestTK
                    setPen(penBlue)
                    drawRect(cx + 1, cy + 1, cellW - 3, cellH - 3)
                    drawRect(cx + 2, cy + 2, cellW - 5, cellH - 5)
                ok

                // Cell value - bold text, dark color
                setPen(penBlack)
                setFont(new qfont("Arial", 10, 75, 0))  // size 10 bold
                cVal = "" + ceil(v)
                drawText(cx + cellW/2 - 16, cy + cellH/2 + 5, cVal)
            next
        next

        // X axis labels (TopK values)
        setPen(penBlack)
        setFont(new qfont("Arial", 10, 50, 0))  // size 10 normal
        for ci = 1 to nTK
            cx = mLeft + (ci - 1) * cellW + cellW/2 - 6
            drawText(cx, h - mBottom + 18, "" + aGridTopK[ci])
        next
        drawText(mLeft + plotW/2 - 18, h - 5, "Top-K")

        // Y axis labels (RangeMth values)
        setFont(new qfont("Arial", 10, 50, 0))  // size 10 normal
        for ri = 1 to nRM
            cy = mTop + (ri - 1) * cellH + cellH/2 + 5
            drawText(2, cy, "" + aGridRangeMth[ri] + "mo")
        next

        // Chart title
        setFont(new qfont("Arial", 11, 75, 0))  // size 11 bold
        drawText(mLeft + plotW/2 - 50, mTop - 8, "Total Return %")

        endpaint()
    }

    oHeatmapLabel{ setpicture(p1) show() }

Return

// ============================================================
// PopulateConfigTable()
// ============================================================

Func PopulateConfigTable()

    if oConfigTable = null   return   ok

    nCfg = len(aConfigList)
    oConfigTable.setRowCount(nCfg)

    for r = 1 to nCfg
        rm     = aConfigList[r][1]
        tk     = aConfigList[r][2]
        totRet = aConfigList[r][3]
        qqqRet = aConfigList[r][4]
        ratio  = aConfigList[r][5]
        cagr   = aConfigList[r][6]

        iRM  = new QTableWidgetItem("zx")
        iTK  = new QTableWidgetItem("zx")
        iTot = new QTableWidgetItem("zx")
        iQQQ = new QTableWidgetItem("zx")
        iRat = new QTableWidgetItem("zx")
        iCAG = new QTableWidgetItem("zx")

        oFont14 = new qfont("Arial", 10, 50, 0)  // pt 10 = ~14px

        iRM.setText("" + rm)           iRM.setFont(oFont14)   iRM.setTextAlignment(0x0082)
        iTK.setText("" + tk)           iTK.setFont(oFont14)   iTK.setTextAlignment(0x0082)
        iTot.setText("" + ceil(totRet) + "%")   iTot.setFont(oFont14)   iTot.setTextAlignment(0x0082)
        iQQQ.setText("" + ceil(qqqRet) + "%")   iQQQ.setFont(oFont14)   iQQQ.setTextAlignment(0x0082)
        iRat.setText("" + ceil(ratio))           iRat.setFont(oFont14)   iRat.setTextAlignment(0x0082)
        iCAG.setText("" + ceil(cagr)   + "%")   iCAG.setFont(oFont14)   iCAG.setTextAlignment(0x0082)

        // Best row highlighted in blue
        if rm = nGridBestRM AND tk = nGridBestTK
            iRM.setForeground(brushBlue)
            iTK.setForeground(brushBlue)
            iTot.setForeground(brushBlue)
            iQQQ.setForeground(brushBlue)
            iRat.setForeground(brushBlue)
            iCAG.setForeground(brushBlue)
        ok

        oConfigTable.setItem(r-1, 0, iRM)
        oConfigTable.setItem(r-1, 1, iTK)
        oConfigTable.setItem(r-1, 2, iTot)
        oConfigTable.setItem(r-1, 3, iQQQ)
        oConfigTable.setItem(r-1, 4, iRat)
        oConfigTable.setItem(r-1, 5, iCAG)
    next

Return

