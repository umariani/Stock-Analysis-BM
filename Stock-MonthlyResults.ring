// ============================================================
// Stock-MonthlyResults.ring
// Bert Mariani  2025
//
// "Monthly Results" Tab
//
// Three side-by-side panels (most recent month at TOP in each):
//
//  LEFT   : Monthly Picks – Last 12 Months
//             Period | Rank | Symbol | Mo Gain% | Port Avg%
//
//  MIDDLE : Monthly Performance vs QQQ & SPY
//             Period | Port% | QQQ% | SPY% | vs QQQ | vs SPY
//
//  RIGHT  : Last 12 Months – Monthly Results  (from Yearly tab)
//             Period | Portfolio | QQQ% | SPY% | vs QQQ | vs SPY
//
// Data sources (globals from Stock-YearlyReturns.ring):
//   rList, aList, cList, aTDate, $Top10
// ============================================================

// Globals
oMonthlyResTab   = null
oMoPicksTable    = null     // LEFT  : picks per month
oMoPerfVsTable   = null     // MIDDLE: port vs QQQ/SPY
oStatsLabel      = null     // MIDDLE: stats below table (drawdown/drawup/sharpe)
lblLP            = null     // LEFT  : title label (updated in Refresh)
lblLP2           = null     // LEFT  : subtitle label
lblMP            = null     // MIDDLE: title label (updated in Refresh)
lblMP2           = null     // MIDDLE: subtitle label (updated in Refresh)

// ============================================================
// BuildMonthlyResultsTab(tabWidget)
// ============================================================

Func BuildMonthlyResultsTab(tabWidget)

    oMonthlyResTab = new QWidget()
    hLay = new QHBoxLayout()
    hLay.setSpacing(6)

    // ---- shared brushes (plain black for cells) ----
    colorMBK = new qcolor()
    colorMBK.setrgb(0, 0, 0, 255)
    brushMBK = new qbrush()
    brushMBK.setstyle(1)
    brushMBK.setcolor(colorMBK)

    // ================================================================
    // LEFT PANEL  –  Monthly Picks
    // ================================================================
    leftFrame = new QFrame(win, 0)
    leftFrame.setFrameShape(QFrame_StyledPanel)
    leftVLay = new QVBoxLayout()
    leftVLay.setSpacing(4)

    lblLP = new QLabel(win)
    lblLP.setText("Monthly Picks  –  Last 12 Months")   // Updated in Refresh
    lblLP.setStyleSheet(
        "color:#007acc; font-weight:bold; font-size:14px; " +
        "border:2px solid #007acc; padding:3px 6px;")
    lblLP.setMaximumHeight(34)
    leftVLay.addWidget(lblLP)

    lblLP2 = new QLabel(win)
    lblLP2.setText("Stocks selected each period & their result  (most recent first)")
    lblLP2.setStyleSheet("color:#888888; font-size:12px;")
    lblLP2.setMaximumHeight(20)
    leftVLay.addWidget(lblLP2)

    oMoPicksTable = new QTableWidget(win)
    oMoPicksTable.setColumnCount(5)
    oMoPicksTable.setRowCount(0)
    oMoPicksTable.setEditTriggers(0)
    oMoPicksTable.setAlternatingRowColors(true)
    oMoPicksTable.setStyleSheet(
        "QTableWidget { color:#000000; font-size:13px; " +
        "background-color:#ffffff; alternate-background-color:#eef4fb; gridline-color:#cccccc; }" +
        "QHeaderView::section { background-color:#1a3a5c; color:#ffffff; " +
        "font-weight:bold; font-size:13px; padding:4px; border:1px solid #555; }" )

    oLPH = new QStringList()
    oLPH.append("Period")
    oLPH.append("Rank")
    oLPH.append("Symbol")
    oLPH.append("Mo/Wk Gain %")   // Updated in Refresh
    oLPH.append("Port Avg %")
    oMoPicksTable.setHorizontalHeaderLabels(oLPH)
    oMoPicksTable.horizontalHeader().setStretchLastSection(false)
    oMoPicksTable.setColumnWidth(0, 105)
    oMoPicksTable.setColumnWidth(1,  48)
    oMoPicksTable.setColumnWidth(2,  72)
    oMoPicksTable.setColumnWidth(3,  90)
    oMoPicksTable.setColumnWidth(4,  85)

    leftVLay.addWidget(oMoPicksTable)
    leftFrame.setLayout(leftVLay)

    // ================================================================
    // MIDDLE PANEL  –  Monthly Port % vs QQQ & SPY
    // ================================================================
    midFrame = new QFrame(win, 0)
    midFrame.setFrameShape(QFrame_StyledPanel)
    midVLay = new QVBoxLayout()
    midVLay.setSpacing(4)

    lblMP = new QLabel(win)
    lblMP.setText("Monthly Performance  vs  QQQ  &  SPY")   // Updated in Refresh
    lblMP.setStyleSheet(
        "color:#005500; font-weight:bold; font-size:14px; " +
        "border:2px solid #005500; padding:3px 6px;")
    lblMP.setMaximumHeight(34)
    midVLay.addWidget(lblMP)

    lblMP2 = new QLabel(win)
    lblMP2.setText("Current partial month (*) + last 12 completed months  —  Total sum + Compounded Port %")   // Updated in Refresh
    lblMP2.setStyleSheet("color:#888888; font-size:12px;")
    lblMP2.setMaximumHeight(20)
    midVLay.addWidget(lblMP2)

    oMoPerfVsTable = new QTableWidget(win)
    oMoPerfVsTable.setColumnCount(6)
    oMoPerfVsTable.setRowCount(0)
    oMoPerfVsTable.setEditTriggers(0)
    oMoPerfVsTable.setAlternatingRowColors(true)
    oMoPerfVsTable.setStyleSheet(
        "QTableWidget { color:#000000; font-size:13px; " +
        "background-color:#ffffff; alternate-background-color:#f0f8f0; gridline-color:#cccccc; }" +
        "QHeaderView::section { background-color:#1a3a1a; color:#ffffff; " +
        "font-weight:bold; font-size:12px; padding:3px; border:1px solid #555; }" )

    oMPH = new QStringList()
    oMPH.append("Period")
    oMPH.append("Port %")
    oMPH.append("QQQ %")
    oMPH.append("SPY %")
    oMPH.append("vs QQQ")
    oMPH.append("vs SPY")
    oMoPerfVsTable.setHorizontalHeaderLabels(oMPH)
    oMoPerfVsTable.horizontalHeader().setStretchLastSection(false)
    oMoPerfVsTable.setColumnWidth(0, 110)   // Period
    oMoPerfVsTable.setColumnWidth(1,  82)   // Port %
    oMoPerfVsTable.setColumnWidth(2,  78)   // QQQ %
    oMoPerfVsTable.setColumnWidth(3,  78)   // SPY %
    oMoPerfVsTable.setColumnWidth(4,  82)   // vs QQQ
    oMoPerfVsTable.setColumnWidth(5,  82)   // vs SPY

    midVLay.addWidget(oMoPerfVsTable)

    // ---- Stats row: Max Drawdown / Max Drawup / Sharpe ----
    oStatsLabel = new QLabel(win)
    oStatsLabel.setText("Max Drawdown: --   Max Drawup: --   Sharpe Ratio: --")
    oStatsLabel.setStyleSheet(
        "QLabel { background-color:#eef4fb; color:#003c78; font-weight:bold; " +
        "font-size:16px; font-family:Consolas,monospace; padding:6px 10px; " +
        "border:1px solid #b8c8dc; border-radius:4px; }")
    oStatsLabel.setMinimumHeight(88)
    oStatsLabel.setWordWrap(true)
    midVLay.addWidget(oStatsLabel)

    midFrame.setLayout(midVLay)

    // ---- Assemble ----
    hLay.addWidget(leftFrame)
    hLay.addWidget(midFrame)
    hLay.setStretch(0, 1)
    hLay.setStretch(1, 1)

    oMonthlyResTab.setLayout(hLay)
    tabWidget.addTab(oMonthlyResTab, "Monthly Results")

Return oMonthlyResTab


// ============================================================
// RefreshMonthlyResultsTab()
//   Called from RunAnalysis() after YearlyReturns() completes.
// ============================================================

Func RefreshMonthlyResultsTab()

    if oMonthlyResTab = null   return   ok

    // Update labels dynamically based on interval
    cPeriodWord = "month"
    cGainWord   = "Mo"
    if isstring(cInterval) AND cInterval = "1wk"
        cPeriodWord = "week"
        cGainWord   = "Wk"
    ok
    if oMoPicksTable != null
        lblLP.setText(cGainWord + "ly Picks  –  Last 12 " + cGainWord + "s")
        lblMP.setText(cGainWord + "ly Performance  vs  QQQ  &  SPY")
        lblMP2.setText("Current partial " + cPeriodWord + " (*) + last 12 completed " + cPeriodWord + "s  —  Total sum + Compounded Port %")
        oDynHdr = new QStringList()
        oDynHdr.append("Period")   oDynHdr.append("Rank")   oDynHdr.append("Symbol")
        oDynHdr.append(cGainWord + " Gain %")   oDynHdr.append("Port Avg %")
        oMoPicksTable.setHorizontalHeaderLabels(oDynHdr)
    ok

    // Collect period columns newest-first
    // Monthly: look for 01/ boundaries; Weekly: every column is a period
    nTD = len(aTDate)
    aMonthCols = []
    if isstring(cInterval) AND cInterval = "1wk"
        // Weekly: collect last 14 week columns
        for k = nTD to 1 step -1
            Add(aMonthCols, k + 1)
            if len(aMonthCols) = 14   exit   ok
        next
    else
        // Monthly: collect last 14 01/ columns
        for k = nTD to 1 step -1
            d = aTDate[k]
            if len(d) >= 3
                if subStr(d, 1, 3) = "01/"
                    Add(aMonthCols, k + 1)
                    if len(aMonthCols) = 14   exit   ok
                ok
            ok
        next
    ok

    // Locate QQQ and SPY
    posQQQ = 0   posSPY = 0
    for r = 1 to len(aList)
        if islist(aList[r])
            if aList[r][1] = "QQQ"   posQQQ = r   ok
            if aList[r][1] = "SPY"   posSPY = r   ok
        ok
    next

    nAMax = 0
    if posQQQ > 0   nAMax = len(aList[posQQQ])   ok
    nCRow = len(cList)

    // Shared brushes
    colorGn = new qcolor()
    colorGn.setrgb(0, 0, 200, 255)
    brushGn = new qbrush()
    brushGn.setstyle(1)
    brushGn.setcolor(colorGn)

    colorRd = new qcolor()
    colorRd.setrgb(200, 0, 0, 255)
    brushRd = new qbrush()
    brushRd.setstyle(1)
    brushRd.setcolor(colorRd)

    colorBK = new qcolor()
    colorBK.setrgb(0, 0, 0, 255)
    brushBK = new qbrush()
    brushBK.setstyle(1)
    brushBK.setcolor(colorBK)

    // Header-row brushes for picks panel
    colorHdr = new qcolor()
    colorHdr.setrgb(220, 230, 245, 255)
    brushHdr = new qbrush()
    brushHdr.setstyle(1)
    brushHdr.setcolor(colorHdr)

    colorHdrTxt = new qcolor()
    colorHdrTxt.setrgb(0, 60, 120, 255)
    brushHdrTxt = new qbrush()
    brushHdrTxt.setstyle(1)
    brushHdrTxt.setcolor(colorHdrTxt)

    oHdrFont  = new qfont("Arial", 12, 75, 0)
    oItemFont = new qfont("Arial", 12, 50, 0)
    oCFont    = new qfont("Consolas", 12, 50, 0)

    // ================================================================
    // LEFT: populate oMoPicksTable
    // ================================================================
    if oMoPicksTable != null
        oMoPicksTable.setRowCount(0)
        tRow = 0

        for mi = 1 to len(aMonthCols)
            buyCol  = aMonthCols[mi]
            sellCol = buyCol + 1
            if nAMax > 0 AND sellCol > nAMax   sellCol = nAMax   ok

            tIdx  = buyCol - 1
            cDate = ""
            if tIdx >= 1 AND tIdx <= len(aTDate)   cDate = aTDate[tIdx]   ok
            tIdxE = sellCol - 1
            cDateE = ""
            if tIdxE >= 1 AND tIdxE <= len(aTDate)   cDateE = aTDate[tIdxE]   ok
            cPeriod = cDate
            if cDateE != ""   cPeriod = cDate + "→" + subStr(cDateE, 4, 7)   ok

            // Top-K stocks at buyCol
            aMS = []
            for r = 1 to len(rList)
                if islist(rList[r])
                    if len(rList[r]) >= buyCol
                        rnk = 0 + rList[r][buyCol]
                        if rnk >= 1 AND rnk <= $Top10
                            Add(aMS, [rnk, rList[r][1]])
                        ok
                    ok
                ok
            next

            // Sort by rank
            nMS = len(aMS)
            for i = 1 to nMS - 1
                for j = 1 to nMS - i
                    if aMS[j][1] > aMS[j+1][1]
                        tmp = aMS[j]   aMS[j] = aMS[j+1]   aMS[j+1] = tmp
                    ok
                next
            next

            // Gains
            totalG = 0   nV = 0   aGains = []
            for si = 1 to len(aMS)
                sym = aMS[si][2]
                posA = 0
                for ar = 1 to len(aList)
                    if islist(aList[ar])
                        if aList[ar][1] = sym   posA = ar   exit   ok
                    ok
                next
                moG = 0
                if posA > 0 AND buyCol <= len(aList[posA]) AND sellCol <= len(aList[posA])
                    pB = 0 + aList[posA][buyCol]
                    pS = 0 + aList[posA][sellCol]
                    if pB > 0.01
                        moG = (pS / pB - 1) * 100
                        totalG = totalG + moG
                        nV = nV + 1
                    ok
                ok
                Add(aGains, moG)
            next
            portAvg = 0
            if nV > 0   portAvg = totalG / nV   ok

            // Header row
            oMoPicksTable.insertRow(tRow)
            hItem = new QTableWidgetItem("h")
            hItem.setText(cPeriod)
            hItem.setBackground(brushHdr)
            hItem.setForeground(brushHdrTxt)
            hItem.setTextAlignment(0x0084)
            hItem.setFont(oHdrFont)
            oMoPicksTable.setItem(tRow, 0, hItem)
            for c = 1 to 3
                fi = new QTableWidgetItem("hf")
                fi.setText("")   fi.setBackground(brushHdr)
                oMoPicksTable.setItem(tRow, c, fi)
            next
            pAvgSign = ""   if portAvg >= 0   pAvgSign = "+"   ok
            pAI = new QTableWidgetItem("pa")
            pAI.setText(pAvgSign + "" + Fmt2d(portAvg) + "%")
            pAI.setBackground(brushHdr)
            if portAvg >= 0   pAI.setForeground(brushGn)   else   pAI.setForeground(brushRd)   ok
            pAI.setTextAlignment(0x0082)
            pAI.setFont(oHdrFont)
            oMoPicksTable.setItem(tRow, 4, pAI)
            tRow = tRow + 1

            // Stock rows
            for si = 1 to len(aMS)
                rnk = aMS[si][1]   sym = aMS[si][2]   moG = aGains[si]
                oMoPicksTable.insertRow(tRow)

                w0 = new QTableWidgetItem("p")   w0.setText("")
                w0.setForeground(brushBK)   w0.setFont(oItemFont)
                oMoPicksTable.setItem(tRow, 0, w0)

                w1 = new QTableWidgetItem("r")   w1.setText("" + rnk)
                w1.setForeground(brushBK)   w1.setFont(oItemFont)
                w1.setTextAlignment(0x0084)
                oMoPicksTable.setItem(tRow, 1, w1)

                w2 = new QTableWidgetItem("s")   w2.setText(sym)
                w2.setForeground(brushGn)   w2.setFont(oItemFont)
                oMoPicksTable.setItem(tRow, 2, w2)

                gSign = ""   if moG >= 0   gSign = "+"   ok
                w3 = new QTableWidgetItem("g")
                w3.setText(gSign + "" + Fmt2d(moG) + "%")
                if moG >= 0   w3.setForeground(brushGn)   else   w3.setForeground(brushRd)   ok
                w3.setTextAlignment(0x0082)   w3.setFont(oItemFont)
                oMoPicksTable.setItem(tRow, 3, w3)

                w4 = new QTableWidgetItem("a")   w4.setText("")
                w4.setForeground(brushBK)   w4.setFont(oItemFont)
                oMoPicksTable.setItem(tRow, 4, w4)

                tRow = tRow + 1
            next
        next
    ok

    // ================================================================
    // MIDDLE: populate oMoPerfVsTable
    // ================================================================
    if oMoPerfVsTable != null AND posQQQ > 0
        oMoPerfVsTable.setRowCount(0)

        // Build a map of all period boundary columns
        // Monthly: 01/ dates only; Weekly: every column
        a01Cols = []
        if isstring(cInterval) AND cInterval = "1wk"
            for k = 1 to len(aTDate)
                Add(a01Cols, k + 1)
            next
        else
            for k = 1 to len(aTDate)
                if len(aTDate[k]) >= 3
                    if subStr(aTDate[k], 1, 3) = "01/"
                        Add(a01Cols, k + 1)
                    ok
                ok
            next
        ok

        dRow        = 0      // display row counter
        nComplete   = 0      // count of completed months written

        // Running totals for sum row and compound for Port%
        sumPort = 0   sumQQQ = 0   sumSPY = 0   sumVQ = 0   sumVS = 0
        compoundPort = 1.0   // multiplicative compound for Port%
        aMonthlyReturns = []  // collect each month's portPct for Sharpe

        for mi = 1 to len(aMonthCols)
            buyCol = aMonthCols[mi]   // opening col (01/ date, newest first)

            // sellCol = the next 01/ column after buyCol in ascending order
            sellCol  = 0
            bPartial = false
            for ci = 1 to len(a01Cols)
                if a01Cols[ci] = buyCol
                    if ci < len(a01Cols)
                        sellCol = a01Cols[ci + 1]
                    ok
                    exit
                ok
            next

            // Partial month: no next 01/ col — use last live column as close
            if sellCol = 0
                sellCol  = nAMax
                bPartial = true
            ok
            if sellCol > nAMax   sellCol = nAMax   ok

            // Show partial month + up to 12 completed months
            if ! bPartial
                nComplete = nComplete + 1
                if nComplete > 12   exit   ok
            ok

            tIdx = buyCol - 1
            cDate = ""
            if tIdx >= 1 AND tIdx <= len(aTDate)   cDate = aTDate[tIdx]   ok
            if bPartial   cDate = cDate + " *"   ok

            // QQQ monthly return
            // For completed months: open[buyCol] → open[sellCol]
            // For partial month: open[buyCol] → current close from aClosedPrices
            qqqPct = 0
            nQC = len(aList[posQQQ])
            qBuy = buyCol
            if qBuy > nQC   qBuy = nQC   ok
            if qBuy < 1     qBuy = 1     ok

            if bPartial
                // Use aClosedPrices for today's QQQ close — avoids column offset issues
                posQQQc = 0
                for rc = 1 to len(aClosedPrices)
                    if islist(aClosedPrices[rc])
                        if aClosedPrices[rc][1] = "QQQ"   posQQQc = rc   exit   ok
                    ok
                next
                qS = 0 + aList[posQQQ][qBuy]
                qE = 0
                if posQQQc > 0   qE = 0 + aClosedPrices[posQQQc][len(aClosedPrices[posQQQc])]   ok
                if qS > 0.01 AND qE > 0.01   qqqPct = (qE / qS - 1) * 100   ok
            else
                qSell = sellCol
                if qSell > nQC   qSell = nQC   ok
                qS = 0 + aList[posQQQ][qBuy]
                qE = 0 + aList[posQQQ][qSell]
                if qS > 0.01   qqqPct = (qE / qS - 1) * 100   ok
            ok

            // SPY monthly return — same pattern
            spyPct = 0
            if posSPY > 0
                nSC  = len(aList[posSPY])
                sBuy = buyCol
                if sBuy > nSC   sBuy = nSC   ok
                if sBuy < 1     sBuy = 1     ok

                if bPartial
                    possSPYc = 0
                    for rc = 1 to len(aClosedPrices)
                        if islist(aClosedPrices[rc])
                            if aClosedPrices[rc][1] = "SPY"   possSPYc = rc   exit   ok
                        ok
                    next
                    sS = 0 + aList[posSPY][sBuy]
                    sE = 0
                    if possSPYc > 0   sE = 0 + aClosedPrices[possSPYc][len(aClosedPrices[possSPYc])]   ok
                    if sS > 0.01 AND sE > 0.01   spyPct = (sE / sS - 1) * 100   ok
                else
                    sSell = sellCol
                    if sSell > nSC   sSell = nSC   ok
                    sS = 0 + aList[posSPY][sBuy]
                    sE = 0 + aList[posSPY][sSell]
                    if sS > 0.01   spyPct = (sE / sS - 1) * 100   ok
                ok
            ok

            // Portfolio via aSumTotal[3] compound ratios.
            // aSumTotal[3][k] = cumulative compound AFTER month k closes.
            // Completed month: start = aSumTotal[3][buyCol-1], end = aSumTotal[3][sellCol-1]
            // Partial month:   start = aSumTotal[3][buyCol-1], end = aSumTotal[3][sellCol-1]
            // (same formula works for both since sellCol=nAMax for partial)
            portPct = 0
            nST = len(aSumTotal[3])
            bc = buyCol  - 1
            ec = sellCol - 1
            if bc < 1    bc = 1    ok
            if bc > nST  bc = nST  ok
            if ec < 1    ec = 1    ok
            if ec > nST  ec = nST  ok
            stS = 0 + aSumTotal[3][bc]
            stE = 0 + aSumTotal[3][ec]
            if stS > 0.0001
                portPct = (stE / stS - 1) * 100
            elseif nCRow > 0
                nCC = len(cList[nCRow])
                if bc > nCC   bc = nCC   ok
                if ec > nCC   ec = nCC   ok
                tS = 0 + cList[nCRow][bc]
                tE = 0 + cList[nCRow][ec]
                if tS > 0.0001   portPct = (tE / tS - 1) * 100   ok
            ok

            vsQQQ = portPct - qqqPct
            vsSPY = portPct - spyPct

            // Accumulate totals and compound
            sumPort      = sumPort + portPct
            sumQQQ       = sumQQQ  + qqqPct
            sumSPY       = sumSPY  + spyPct
            sumVQ        = sumVQ   + vsQQQ
            sumVS        = sumVS   + vsSPY
            compoundPort = compoundPort * (1 + portPct / 100)
            Add(aMonthlyReturns, portPct)

            oMoPerfVsTable.insertRow(dRow)

            wP = new QTableWidgetItem("per")
            wP.setText(cDate)   wP.setForeground(brushBK)
            wP.setFont(oCFont)   wP.setTextAlignment(0x0084)
            oMoPerfVsTable.setItem(dRow, 0, wP)

            pSign = ""   if portPct >= 0   pSign = "+"   ok
            wPort = new QTableWidgetItem("port")
            wPort.setText(pSign + Fmt2d(portPct) + "%")
            if portPct >= 0   wPort.setForeground(brushGn)   else   wPort.setForeground(brushRd)   ok
            wPort.setTextAlignment(0x0082)   wPort.setFont(oCFont)
            oMoPerfVsTable.setItem(dRow, 1, wPort)

            qSign = ""   if qqqPct >= 0   qSign = "+"   ok
            wQ = new QTableWidgetItem("qqq")
            wQ.setText(qSign + Fmt2d(qqqPct) + "%")
            if qqqPct >= 0   wQ.setForeground(brushGn)   else   wQ.setForeground(brushRd)   ok
            wQ.setTextAlignment(0x0082)   wQ.setFont(oCFont)
            oMoPerfVsTable.setItem(dRow, 2, wQ)

            sSign = ""   if spyPct >= 0   sSign = "+"   ok
            wS = new QTableWidgetItem("spy")
            wS.setText(sSign + Fmt2d(spyPct) + "%")
            if spyPct >= 0   wS.setForeground(brushGn)   else   wS.setForeground(brushRd)   ok
            wS.setTextAlignment(0x0082)   wS.setFont(oCFont)
            oMoPerfVsTable.setItem(dRow, 3, wS)

            vqSign = ""   if vsQQQ >= 0   vqSign = "+"   ok
            wVQ = new QTableWidgetItem("vq")
            wVQ.setText(vqSign + Fmt2d(vsQQQ) + "%")
            if vsQQQ >= 0   wVQ.setForeground(brushGn)   else   wVQ.setForeground(brushRd)   ok
            wVQ.setTextAlignment(0x0082)   wVQ.setFont(oCFont)
            oMoPerfVsTable.setItem(dRow, 4, wVQ)

            vsSign = ""   if vsSPY >= 0   vsSign = "+"   ok
            wVS = new QTableWidgetItem("vs")
            wVS.setText(vsSign + Fmt2d(vsSPY) + "%")
            if vsSPY >= 0   wVS.setForeground(brushGn)   else   wVS.setForeground(brushRd)   ok
            wVS.setTextAlignment(0x0082)   wVS.setFont(oCFont)
            oMoPerfVsTable.setItem(dRow, 5, wVS)

            dRow = dRow + 1

        next

        // ---- Total sum row ----
        colorTot = new qcolor()
        colorTot.setrgb(238, 244, 251, 255)
        brushTotBG = new qbrush()
        brushTotBG.setstyle(1)
        brushTotBG.setcolor(colorTot)

        colorTotTxt = new qcolor()
        colorTotTxt.setrgb(0, 60, 120, 255)
        brushTotTxt = new qbrush()
        brushTotTxt.setstyle(1)
        brushTotTxt.setcolor(colorTotTxt)

        colorTotGn = new qcolor()
        colorTotGn.setrgb(0, 60, 120, 255)
        brushTotGn = new qbrush()
        brushTotGn.setstyle(1)
        brushTotGn.setcolor(colorTotGn)

        colorTotRd = new qcolor()
        colorTotRd.setrgb(0, 60, 120, 255)
        brushTotRd = new qbrush()
        brushTotRd.setstyle(1)
        brushTotRd.setcolor(colorTotRd)

        oTotFont = new qfont("Consolas", 12, 75, 0)

        oMoPerfVsTable.insertRow(dRow)

        wTL = new QTableWidgetItem("tot_lbl")
        cTotLbl = "Total (13 mo)"
        if isstring(cInterval) AND cInterval = "1wk"   cTotLbl = "Total (13 wk)"   ok
        wTL.setText(cTotLbl)
        wTL.setBackground(brushTotBG)
        wTL.setForeground(brushTotTxt)
        wTL.setFont(oTotFont)
        wTL.setTextAlignment(0x0084)
        oMoPerfVsTable.setItem(dRow, 0, wTL)

        pSign = ""   if sumPort >= 0   pSign = "+"   ok
        wTP = new QTableWidgetItem("tot_port")
        wTP.setText(pSign + Fmt2d(sumPort) + "%")
        wTP.setBackground(brushTotBG)
        if sumPort >= 0   wTP.setForeground(brushTotGn)   else   wTP.setForeground(brushTotRd)   ok
        wTP.setTextAlignment(0x0082)   wTP.setFont(oTotFont)
        oMoPerfVsTable.setItem(dRow, 1, wTP)

        qSign = ""   if sumQQQ >= 0   qSign = "+"   ok
        wTQ = new QTableWidgetItem("tot_qqq")
        wTQ.setText(qSign + Fmt2d(sumQQQ) + "%")
        wTQ.setBackground(brushTotBG)
        if sumQQQ >= 0   wTQ.setForeground(brushTotGn)   else   wTQ.setForeground(brushTotRd)   ok
        wTQ.setTextAlignment(0x0082)   wTQ.setFont(oTotFont)
        oMoPerfVsTable.setItem(dRow, 2, wTQ)

        sSign = ""   if sumSPY >= 0   sSign = "+"   ok
        wTS = new QTableWidgetItem("tot_spy")
        wTS.setText(sSign + Fmt2d(sumSPY) + "%")
        wTS.setBackground(brushTotBG)
        if sumSPY >= 0   wTS.setForeground(brushTotGn)   else   wTS.setForeground(brushTotRd)   ok
        wTS.setTextAlignment(0x0082)   wTS.setFont(oTotFont)
        oMoPerfVsTable.setItem(dRow, 3, wTS)

        vqSign = ""   if sumVQ >= 0   vqSign = "+"   ok
        wTVQ = new QTableWidgetItem("tot_vq")
        wTVQ.setText(vqSign + Fmt2d(sumVQ) + "%")
        wTVQ.setBackground(brushTotBG)
        if sumVQ >= 0   wTVQ.setForeground(brushTotGn)   else   wTVQ.setForeground(brushTotRd)   ok
        wTVQ.setTextAlignment(0x0082)   wTVQ.setFont(oTotFont)
        oMoPerfVsTable.setItem(dRow, 4, wTVQ)

        vsSign = ""   if sumVS >= 0   vsSign = "+"   ok
        wTVS = new QTableWidgetItem("tot_vs")
        wTVS.setText(vsSign + Fmt2d(sumVS) + "%")
        wTVS.setBackground(brushTotBG)
        if sumVS >= 0   wTVS.setForeground(brushTotGn)   else   wTVS.setForeground(brushTotRd)   ok
        wTVS.setTextAlignment(0x0082)   wTVS.setFont(oTotFont)
        oMoPerfVsTable.setItem(dRow, 5, wTVS)
        dRow = dRow + 1

        // ---- Compounded Port% row ----
        colorTot = new qcolor()
        colorTot.setrgb(238, 244, 251, 255)
        brushTotBG = new qbrush()
        brushTotBG.setstyle(1)
        brushTotBG.setcolor(colorTot)

        colorTotTxt = new qcolor()
        colorTotTxt.setrgb(0, 60, 120, 255)
        brushTotTxt = new qbrush()
        brushTotTxt.setstyle(1)
        brushTotTxt.setcolor(colorTotTxt)

        colorTotGn = new qcolor()
        colorTotGn.setrgb(0, 60, 120, 255)
        brushTotGn = new qbrush()
        brushTotGn.setstyle(1)
        brushTotGn.setcolor(colorTotGn)

        colorTotRd = new qcolor()
        colorTotRd.setrgb(0, 60, 120, 255)
        brushTotRd = new qbrush()
        brushTotRd.setstyle(1)
        brushTotRd.setcolor(colorTotRd)

        oTotFont = new qfont("Consolas", 12, 75, 0)

        compPct = (compoundPort - 1) * 100

        oMoPerfVsTable.insertRow(dRow)

        wTL = new QTableWidgetItem("tot_lbl")
        wTL.setText("Compounded")
        wTL.setBackground(brushTotBG)
        wTL.setForeground(brushTotTxt)
        wTL.setFont(oTotFont)
        wTL.setTextAlignment(0x0084)
        oMoPerfVsTable.setItem(dRow, 0, wTL)

        pSign = ""   if compPct >= 0   pSign = "+"   ok
        wTP = new QTableWidgetItem("tot_port")
        wTP.setText(pSign + Fmt2d(compPct) + "%")
        wTP.setBackground(brushTotBG)
        if compPct >= 0   wTP.setForeground(brushTotGn)   else   wTP.setForeground(brushTotRd)   ok
        wTP.setTextAlignment(0x0082)   wTP.setFont(oTotFont)
        oMoPerfVsTable.setItem(dRow, 1, wTP)

        // Columns 2-5 blank on compound row
        for c = 2 to 5
            wBlank = new QTableWidgetItem("tot_blank")
            wBlank.setText("")
            wBlank.setBackground(brushTotBG)
            oMoPerfVsTable.setItem(dRow, c, wBlank)
        next

    ok

    // ================================================================
    // STATS: Max Drawdown, Max Drawup, Sharpe Ratio (full range)
    // ================================================================
    if oStatsLabel != null

        // ---- Max Drawdown & Max Drawup: best/worst single month ----
        nST    = len(aSumTotal[3])
        maxDD  = 0.0     maxDDk = 2
        maxDU  = 0.0     maxDUk = 2

        // Build list of all period boundary columns in ascending order
        a01All = []
        if isstring(cInterval) AND cInterval = "1wk"
            for k = 1 to len(aTDate)
                Add(a01All, k + 1)
            next
        else
            for k = 1 to len(aTDate)
                if len(aTDate[k]) >= 3
                    if subStr(aTDate[k], 1, 3) = "01/"
                        Add(a01All, k + 1)
                    ok
                ok
            next
        ok

        for ci = 1 to len(a01All) - 1
            bc = a01All[ci]       // month open col
            ec = a01All[ci + 1]   // month close col (next 01/)
            if bc > nST   exit   ok
            if ec > nST   ec = nST   ok
            stS = 0 + aSumTotal[3][bc - 1]
            stE = 0 + aSumTotal[3][ec - 1]
            if stS > 0.0001
                moR = (stE / stS - 1) * 100
                if moR < maxDD   maxDD = moR   maxDDk = bc   ok
                if moR > maxDU   maxDU = moR   maxDUk = bc   ok
            ok
        next

        // ---- Sharpe Ratio from collected monthly returns ----
        // Annualized Sharpe = (mean monthly return / std dev monthly return) * sqrt(12)
        // Risk-free rate assumed 0 for simplicity (monthly excess return = monthly return)
        sharpe   = 0.0
        nMR      = len(aMonthlyReturns)

        if nMR > 1
            // Mean
            meanR = 0.0
            for r = 1 to nMR   meanR = meanR + aMonthlyReturns[r]   next
            meanR = meanR / nMR

            // Variance
            varR = 0.0
            for r = 1 to nMR
                diff = aMonthlyReturns[r] - meanR
                varR = varR + diff * diff
            next
            varR  = varR / (nMR - 1)   // sample variance

            // Std dev
            stdR = 0.0
            if varR > 0   stdR = sqrt(varR)   ok

            // Annualized Sharpe
            if stdR > 0.0001
                nPeriods = 12
                if isstring(cInterval) AND cInterval = "1wk"   nPeriods = 52   ok
                sharpe = (meanR / stdR) * sqrt(nPeriods)
            ok
        ok

        // ---- Format and display ----
        ddSign = ""   if maxDD >= 0   ddSign = "+"   ok
        duSign = ""   if maxDU >= 0   duSign = "+"   ok
        shSign = ""   if sharpe >= 0  shSign = "+"   ok

        cDDdate = ColToDate(maxDDk)
        cDUdate = ColToDate(maxDUk)

        cStats =
            "  Max Drawdown: "  + PadL(9, ddSign + Fmt2d(maxDD) + "%") + " (" + cDDdate + ")" +
            nl +
            "  Max Drawup:   " + PadL(9, duSign + Fmt2d(maxDU) + "%") + " (" + cDUdate + ")" +
            nl +
            "  Sharpe Ratio: " + PadL(9, shSign + Fmt2d(sharpe)) + " (annualized)"

        oStatsLabel.setText(cStats)

        // Color: if sharpe good (>1) show green text, else yellow
        if sharpe >= 1.0
            oStatsLabel.setStyleSheet(
                "QLabel { background-color:#eef4fb; color:#003c78; font-weight:bold; " +
                "font-size:16px; font-family:Consolas,monospace; padding:6px 10px; " +
                "border:1px solid #b8c8dc; border-radius:4px; }")
        else
            oStatsLabel.setStyleSheet(
                "QLabel { background-color:#eef4fb; color:#003c78; font-weight:bold; " +
                "font-size:16px; font-family:Consolas,monospace; padding:6px 10px; " +
                "border:1px solid #b8c8dc; border-radius:4px; }")
        ok
    ok

    App.processEvents()

Return


// ============================================================
// ColToDate(k)  –  return aTDate string for aList column k
// aTDate[k-1] = date label for column k
// ============================================================

Func ColToDate(k)
    tIdx = k - 1
    if tIdx >= 1 AND tIdx <= len(aTDate)   return aTDate[tIdx]   ok
    return "col" + k


// ============================================================
// Fmt2d(n)  –  format a number to exactly 2 decimal places
//   e.g.  9.9  => "9.90"    26.0 => "26.00"   -7.1 => "-7.10"
// ============================================================

Func Fmt2d(n)
    nR   = ceil(n * 100) / 100
    cStr = "" + nR
    dot  = subStr(cStr, ".")
    if dot = 0
        return cStr + ".00"
    ok
    dec = len(cStr) - dot
    if dec = 0      return cStr + "00"
    elseif dec = 1  return cStr + "0"
    else            return subStr(cStr, 1, dot + 2)
    ok

