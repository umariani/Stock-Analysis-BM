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
penBlue1    = new qpen() { setcolor(colorBlue)   setwidth(1) }

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
    aQQQData = []
    
    func init(parent)
        super.init(parent)
        return this

    func setData(aSumTotal)
	
	    aNbr           = aSumTotal[1]
        aQQQData       = aSumTotal[2]
		aPortfolioData = aSumTotal[3]
		
        draw()
        
    func draw
        # Capture dimensions and data locally to avoid scope issues inside QPainter block
        w = this.width()
        h = this.height()
        aPort = aPortfolioData
        aQ    = aQQQData
        
        if w < 10 or h < 10 return ok
        
        p1 = new qpicture()
        
        p = new qpainter() {
            begin(p1)
            setRenderHint(QPainter_Antialiasing, true)
            
            # Background
			fillRect(0, 0, w, h, brushBack)
            
            if len(aPort) < 2
                setPen(penBlack) 
                drawText(10, 20, "No Data to Display")
                endpaint()
            else
			    //--- Padding on Left and Right before Chart Grid
                pad = 40      
                
                # Find Min/Max
                minVal =  1000
                maxVal = -1000
                
                    for v in aPort 			
                        if v < minVal minVal = v ok
                        if v > maxVal maxVal = v ok
                    next
				    curAPort = aSumTotal[3][len(aSumTotal[3])]
				
		
                    for v in aQ 
                        if v < minVal minVal = v ok
                        if v > maxVal maxVal = v ok
                    next
				    curAQQQ = aSumTotal[2][len(aSumTotal[2])]					
					curARatio = (curAPort -1) / (curAQQQ -1)
				
				              
                range = maxVal - minVal
                if range = 0 range = 1 ok
                
                # Draw Grid (Detailed)
                setPen(penGrid)
                
                # Horizontal lines
                nSteps = 10                               // 12 nSteps
				
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
                
                # Vertical lines
				Offset =  DataLen % nSteps             // Mod = 4
				Months = (DataLen - Offset) / nSteps   // 64 -4 /  12 = 5
				
                for i = 0 to nSteps                           
                    x = pad + (i * (w - 2*pad) / nSteps)
                    drawLine(x, pad, x, h - pad)
					
					//---Put Month Numbers on Bottom ---
					setPen(penBlack)
					drawText(x, y+10, ""+ (i * Months))    // Label 1-12
					setPen(penGrid)
					
                next

                # Draw Axes
                setPen(penBlue1) 
                drawLine(pad, pad,     pad,     h - pad)
                drawLine(pad, h - pad, w - pad, h - pad)
                
                # Zero Line
                y1 = h - pad - (1.0 - minVal) * (h - 2*pad) / range
                if y1 >= pad and y1 <= h - pad
                    setPen(penBlue1)  
                    drawLine(pad, y1, w - pad, y1)
					
					drawText(pad+10, y1-2, "1.00") 
					drawText( w/2 , y+30, "Months")
                ok
                
                # Draw QQQ (Red)
                setPen(penRed)  
                nCount = len(aQ)
                for i = 1 to nCount - 1
                    x1 = pad + (i - 1) * (w - 2*pad) / (nCount - 1)
                    y1 = h - pad - (aQ[i] - minVal) * (h - 2*pad) / range
                    
                    x2 = pad + (i) * (w - 2*pad) / (nCount - 1)
                    y2 = h - pad - (aQ[i+1] - minVal) * (h - 2*pad) / range
                    
                    drawLine(x1, y1, x2, y2)
                next
                
                # Draw Portfolio (Blue)
                setPen(penBlue) 
                nCount = len(aPort)
                for i = 1 to nCount - 1
                    x1 = pad + (i - 1) * (w - 2*pad) / (nCount - 1)
                    y1 = h - pad - (aPort[i] - minVal) * (h - 2*pad) / range
                    
                    x2 = pad + (i) * (w - 2*pad) / (nCount - 1)
                    y2 = h - pad - (aPort[i+1] - minVal) * (h - 2*pad) / range
                    
                    drawLine(x1, y1, x2, y2)
                next
                
                # Legend
                setPen(penBlack)  
                drawText(pad +10, 10, "--- Portfolio_____(Blue) "+ curAPort)
                drawText(pad +10, 30, "--- QQQ________(Red) "+ curAQQQ)
				drawText(pad +10, 50, "--- Performance__Ratio "+ curARatio)
                
                endpaint()
            ok
        }
        
        setPicture(p1)
        show()
		
# ============================		