# Author: Azzeddine Remmal
# modify: Bert Mariani for penColors

load "guilib.ring"

qpainter_antialiasing = 1
qt_solidpattern = 1
qt_dotline = 1

###-------------------------------
### Define Colours, Pens, Brushes

colorRed     = new qcolor() { setrgb(255,000,000,255) }
colorGreen   = new qcolor() { setrgb(000,255,000,255) }  
colorBlue    = new qcolor() { setrgb(000,000,255,255) }
colorYellow  = new qcolor() { setrgb(255,255,000,255) }  
colorWhite   = new qcolor() { setrgb(255,255,255,255) }  
colorBlack   = new qcolor() { setrgb(000,000,000,255) }
colorGray    = new qcolor() { setrgb(128,128,128,255) }  
colorMagenta = new qcolor() { setrgb(000,255,255,016) }  
colorAqua    = new qcolor() { setrgb(000,255,255,255) }  
colorGrid    = new QColor() { setRGB(192,192,192,255) }
colorBack    = new QColor() { setRGB(192,192,192,255) }
colorBlue1   = new qcolor() { setrgb(000,000,128,255) }

penGreen    = new qpen() { setcolor(colorGreen)   setwidth(2) }
penRed      = new qpen() { setcolor(colorRed)     setwidth(2) }
penBlue     = new qpen() { setcolor(colorBlue)    setwidth(2) }  
penYellow   = new qpen() { setcolor(colorYellow)  setwidth(2) } 
penWhite    = new qpen() { setcolor(colorWhite)   setwidth(2) }
penBlack    = new qpen() { setcolor(colorBlack)   setwidth(1) }
penGray     = new qpen() { setcolor(colorGray)    setwidth(1) }
penMagenta  = new qpen() { setcolor(colorMagenta) setwidth(1) }
penAqua     = new qpen() { setcolor(colorAqua)    setwidth(1) }
penGrid     = new qpen() { setcolor(colorGrid)    setwidth(1) }
penBack     = new qpen() { setcolor(colorBack)    setwidth(1) }
penBlue1    = new qpen() { setcolor(colorBlue1)   setwidth(1) }

brushRed     = new qbrush() { setstyle(1)  setcolor (colorRed)}      
brushGreen   = new qbrush() { setstyle(1)  setcolor (colorGreen)}    
brushBlue    = new qbrush() { setstyle(1)  setcolor (colorBlue)}     
brushYellow  = new qbrush() { setstyle(1)  setcolor (colorYellow)} 
brushWhite   = new qbrush() { setstyle(1)  setcolor (colorWhite)}
brushBlack   = new qbrush() { setstyle(1)  setcolor (colorBlack)}  
brushGray    = new qbrush() { setstyle(1)  setcolor (colorGray)}     
brushMagenta = new qbrush() { setstyle(1)  setcolor (colorMagenta)}  
brushAqua    = new qbrush() { setstyle(1)  setcolor (colorAqua)} 
brushBack    = new qbrush() { setstyle(1)  setcolor (colorWhite)}  // Background
brushBlue1   = new qbrush() { setstyle(1)  setcolor (colorBlue1)}


brushEmpty   = new qbrush() { setstyle(0)  setcolor (colorYellow)}   

// There are 19 predefined QColor objects: 
// white, black, red, darkRed, green, darkGreen, blue, darkBlue, cyan, darkCyan, 
// magenta, darkMagenta, yellow, darkYellow, gray, darkGray, lightGray, color0 

// ======================================================================

class StockChart from QLabel
    
    aPortfolioData = []
    aSPYData       = []
    
    # ================================
    Func init(parent)
        super.init(parent)
        return this

    # ================================
    # Array is 3 x 62  (26)
    
    Func setData(aSumTotal)
    
        aNbr           = aSumTotal[1]
        aPortfolioData = aSumTotal[3]
        if len(aSumTotal) >= 4
            aSPYData    = aSumTotal[4]        // SPY benchmark series (Red line)
        else
            aSPYData    = aSumTotal[2]        // fallback: QQQ series if SPY not supplied
        ok

// See "aNbr          : "+ len(aNbr) +nl    
// See "aSPYData      : "+ len(aSPYData ) +nl   
// See "aPortfolioData: "+ len(aPortfolioData) +nl      


        Draw()  // ===>>> DRAW

    # ================================        
    Func Draw
        #--- Capture dimensions and data locally to avoid scope issues inside QPainter block
        w = this.width()
        h = this.height()

        aS    = aSPYData
        aPort = aPortfolioData
        
        if w < 10 or h < 10 return ok
        
        p1 = new qpicture()
        
        p = new qpainter() {
            begin(p1)
            setRenderHint(QPainter_Antialiasing, true)
            
            #--- Background
            fillRect(0, 0, w, h, brushBack)
            
            if len(aPort) < 2
                setPen(penBlack) 
                drawText(10, 20, "No Data to Display")
                endpaint()
            else
                //--- Padding on Left and Right before Chart Grid
                pad = 40      
                
                #--- Find Min/Max
                minVal =  1000
                maxVal = -1000
                
                    for v in aPort          
                        if v < minVal minVal = v ok
                        if v > maxVal maxVal = v ok
                    next
                    curAPort = aSumTotal[3][len(aSumTotal[3])]  // Current Price
                
        
                    for v in aS 
                        if v < minVal minVal = v ok
                        if v > maxVal maxVal = v ok
                    next
                    curASPY   = aSumTotal[4][len(aSumTotal[4])]                 
                    curARatio = (curAPort -1) / (curASPY -1)
                
                              
                range = maxVal - minVal
                if range = 0 range = 1 ok
                
                #-- Draw Grid (Detailed)
                setPen(penGrid)
                
                #--- Horizontal lines ====  Price
                nSteps = 10                               // 12 
                
                value = maxVal / nSteps
                for i = 0 to nSteps
                    y = pad + (i * (h - 2*pad) / nSteps)
                    drawLine(pad, y, w - pad, y)
                    
                    //--- Put Percent Multiplier on Left ---
                    setPen(penBlack)
                    nbr = maxVal -( value * i)      
                    drawText(pad-30, y, ""+nbr) 
                    setPen(penGrid)
                    
                next
                
                //---------------------------------
                //--- Vertical lines |||  Time
                
                setPen(penGrid)
                nSteps =  DataLen - 1                  // <<<=== Match price line divisor (nCount-1)
                Offset =  0                            // Mod = 0 (nSteps divides evenly now)
                Months = 1                             // Each step = 1 data point
                
                See "nSteps: "+ nSteps +nl
                
                //---------------------
                //See "Vert: Datalen: "+ Datalen +" nSteps: "+ nSteps +" Offset: "+ Offset +" Months: "+  Months +nl
                
                MthName = ["J","F","M","A","M","J","J","A","S","O","N","D"]  #### ,"Z"]
                
                for i = 1 to nSteps  

     ###if cInterval = "1wk"    
     ###            if i % 13 = 0                 // #### Weekly -12 months - Year boundary - black line           
     ###                setPen(penBlack)
     ###            ok
     ###else
                 if i % 12 = 0                 // #### 12 months - Year boundary - black line           
                     setPen(penBlack)
                 ok
     ###ok          
                    
                    
                    x = pad + (i * (w - 2*pad) / nSteps)
                    drawLine(x, pad, x, h - pad)
                    
                    //--- Put MONTH NUMBERS on Bottom  -- cInterval 1wk weekly  "1mo" monthly ---
                    aDate = split(Date(), "/")
                    mDate = 0+ aDate[2]                        // Todays - Month nbr 05 = May
                                       
                    
            if cInterval = "1wk"                
                if (nSteps - i) % 4 = 0
                    monthsAgo = (nSteps - i) / 4               // 4 Weekly to Monthly
                    
                    //See "monthsAgo-W: "+ monthsAgo +nl
                    
                    pos = ((mDate + 1 - monthsAgo - 1) % 12 + 12) % 12 + 1
                                    
                    setPen(penBlack)
                        drawText(x, y+10, ""+ monthsAgo )       // Months ago: counts down to 0
                        drawText(x, y+20, ""+ MthName[pos] )
                    setPen(penGrid)
                ok
                
            else    
                    monthsAgo = nSteps - i
                            
                    //See "monthsAgo-M: "+ monthsAgo +nl                      
                    
                        // Rightmost (monthsAgo=0) shows current month (mDate)
                        // Shift +1 so rightmost label = June (next month after May)
                    
                    pos = ((mDate + 1 - monthsAgo - 1) % 12 + 12) % 12 + 1
                    
                    
                    setPen(penBlack)
                        drawText(x, y+10, ""+ monthsAgo )       // Months ago: counts down to 0
                        drawText(x, y+20, ""+ MthName[pos] )
                    setPen(penGrid)
                    
            ok      
                next

                //---------------------------------------------
                //--- Label the leftmost point (i=0, x=pad) ---
				
                aDate2 = split(Date(), "/")
                mDate2 = 0+ aDate2[2]
                MthName2 = ["J","F","M","A","M","J","J","A","S","O","N","D","Z"]
                
                pos0 = ((mDate2 + 1 - nSteps - 1) % 12 + 12) % 12 + 1
                setPen(penBlack)
                drawText(pad, y+10, ""+ nSteps )
                drawText(pad, y+20, ""+ MthName2[pos0] )

                #--- Draw Axes
                setPen(penBlue1) 
                drawLine(pad, pad,     pad,     h - pad)
                drawLine(pad, h - pad, w - pad, h - pad)
                
                #--- Zero Line
                y1 = h - pad - (1.0 - minVal) * (h - 2*pad) / range
                if y1 >= pad and y1 <= h - pad
                    setPen(penBlue1)  
                    drawLine(pad, y1, w - pad, y1)
                    
                    drawText(pad+10, y1-2, "1.00") 
                    drawText( w/2 , y+30, "Months")
                ok
                
                #--- Draw SPY (Red)
                setPen(penRed)  
                nCount = len(aS)          // Dont count Symbol
                for i = 1 to nCount - 1
                    x1 = pad + (i - 1) * (w - 2*pad) / (nCount - 1)
                    y1 = h - pad - (aS[i] - minVal) * (h - 2*pad) / range
                    
                    x2 = pad + (i) * (w - 2*pad) / (nCount - 1)
                    y2 = h - pad - (aS[i+1] - minVal) * (h - 2*pad) / range
                    
                    drawLine(x1, y1, x2, y2)
                next
                
                #--- Draw Portfolio or STOCK (Blue)
                setPen(penBlue) 
                nCount = len(aPort)         // Dont count Symbol
                for i = 1 to nCount - 1
                    x1 = pad + (i - 1) * (w - 2*pad) / (nCount - 1)
                    y1 = h - pad - (aPort[i] - minVal) * (h - 2*pad) / range
                    
                    x2 = pad + (i) * (w - 2*pad) / (nCount - 1)
                    y2 = h - pad - (aPort[i+1] - minVal) * (h - 2*pad) / range
                    
                    drawLine(x1, y1, x2, y2)
                next

                #--- Compute and Draw Moving Average (Green) based on $RangeMth ---
                maPeriod = ceil($RangeMth / 1)   // Shorter MA
                
                
                if maPeriod < 1   maPeriod = 1   ok
                if maPeriod > nCount  maPeriod = nCount  ok

                colorGreen2  = new qcolor() { setrgb(000,160,000,255) }
                penMA        = new qpen()   { setcolor(colorGreen2)  setwidth(2) }
                setPen(penMA)

                #--- Find first index where real (non-padded) data begins.
                #    Padded leading values are all equal to aPort[1].
                #    Real data starts at the first index where the value differs.
                padVal  = aPort[1]
                maStart = nCount        // fallback: no padding found
                for i = 2 to nCount
                    if aPort[i] != padVal
                        maStart = i
                        exit
                    ok
                next

                #--- Compute MA array indexed 1..nCount.
                #    Only fill entries from maStart onward; earlier entries stay 0.
                aMA = list(nCount)
                for i = maStart to nCount
                    winStart = i - maPeriod + 1
                    if winStart < maStart  winStart = maStart  ok
                    sumMA = 0
                    for j = winStart to i
                        sumMA += aPort[j]
                    next
                    aMA[i] = sumMA / (i - winStart + 1)
                next
                    finalMA = aMA[nCount]

                #--- Draw MA only once a full window of real data is accumulated ---
                maDrawFrom = maStart + maPeriod - 1
                if maDrawFrom > nCount  maDrawFrom = nCount  ok

                for i = maDrawFrom to nCount - 1
                    x1 = pad + (i - 1) * (w - 2*pad) / (nCount - 1)
                    y1 = h - pad - (aMA[i]   - minVal) * (h - 2*pad) / range
                    x2 = pad + (i)     * (w - 2*pad) / (nCount - 1)
                    y2 = h - pad - (aMA[i+1] - minVal) * (h - 2*pad) / range
                    drawLine(x1, y1, x2, y2)
                next

                #--- Legend Values in Top-Left -----------
                curAPort2   = aSumTotal[3][len(aSumTotal[3]) -1 ]   // Previous Price
                curAPercent = curAPort / curAPort2 * 100 -100       // Current
                
                setFont(new qfont("Arial", 10, 60, 0))   // Legend: medium weight
                
                setPen(penBlue)
                drawText(pad +10, 14, "--- Portfolio_____(Blue) "+"  "+ stockName +" "+ curAPort2 +" ==> "+ curAPort +"  "+ curAPercent +"%" )
                
                setPen(penRed)
                drawText(pad +10, 34, "--- SPY_______(Red) "+ curASPY)
                
                setPen(penBlack)
                drawText(pad +210, 34, "--- Performance__Ratio "+ curARatio)
                colorGreen3 = new qcolor() { setrgb(000,160,000,255) }
                penMA2 = new qpen() { setcolor(colorGreen3) setwidth(2) }
                
                setPen(penMA2)
                drawText(pad +410, 34, "--- MA -"+ maPeriod +" mth___(Green) "+ finalMA)
                
                setFont(new qfont("Arial", 8, 50, 0))    // Restore small font for axis labels
                
                endpaint()
            ok
        }
        
        setPicture(p1)
        show()
        
# ============================      
