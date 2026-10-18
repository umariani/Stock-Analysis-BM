// CURL-GET-Yahoo History Data for a Stock "AAPL" and Parse JSON returned data.
// Bert Mariani 2024-09-18
//
// "NOTE--NEEDED"
// "cd C:\MyStuff\AA-CurlApp-Distribute"
// "To converted to a Distribute - Console Application"
// "ADD ring.dll and ring_libcurl.dll from current version of: Ring/bin"
// "Use command:             ring2exe     Curl-Get-HIS.ring   <<<=== "
// "Use command: C:\ring\bin\ring2exe.exe Curl-Get-HIS.ring   <<<=== "
// "This will produce Curl-Get-QHD.exe which uses ring.dll file "
//
// curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U;") 
//
// https://stockanalysis.com/list/mega-cap-stocks/
//
// ----------------------------------------------------------------

load "libcurl.ring"
load "stdlibcore.ring"
load "jsonlib.ring"
load "guilib.ring"
load "csvlib.ring"

load "Stock-DrawChart.ring"                    // <<<=== UPDATE VERION USING
load "Stock-YearlyReturns.ring"
load "Stock-YearlyVsQQQ.ring"
load "Stock-AlgoGrid.ring"
load "Stock-BuyHistory.ring"
load "Stock-MonthlyResults.ring"
load "Stock-StockContrib.ring"
# --------------------------
$Dollars   = 10000   // How many Shares to Buy with $10,0000  
todayDate  = " "+ Date() +"  "+ Time()    // "01/01/2026 09:30"  
sellBelow  = -12     // drops -12% from open for month

stockName  = "TOTal"
aTimeStamp = []
aTDate     = []    // to dd/mm/yyy
aAdjClose  = [] 
aOpen      = []
aSymbols   = []             // Extract .ini => array of symbols
aSymbolsAlpha = []          // Alphabetically sorted copy of aSymbols
bUpdatingList = false       // Guard: suppress StockListSelected during programmatic updates

aClosedPrices = [[],[]]     // 2D - 162x64  Update Later to [[NbrSymbol],[ADD price entries]]

StockDirection = "DN"       // "DN" StockCount++  "UP" StockCount--
SortOrder      = "Ranked"   // "Ranked" | "Alpha"  — controls Stk-NEXT/PREV order
aAlphaList     = []         // alphabetically sorted copy of nList (built in RunAnalysis)
   
# --------------------------

# Global Data Containers
aGlobalCurves = [[], []]
aGlobalTop7   = []

# Global Objects
win           = null
oChartWidget  = null
txtLog        = null
comboInterval = null
comboRange    = null
newDate       = null

btnRun        = null
btnExport     = null
btnBrowse     = null
txtTickerFile = null
App           = null

# ADD for Any Widget Field to make it Accessible to Later function
comboTopTen    = null  // <<<<<

// Interval/setting globals - initialized to defaults so Build* functions
// can safely reference them before GetQuotes() or RunAnalysis() is called
cInterval   = "1mo"    // default; updated in GetQuotes() and RunAnalysis()
cRange      = "2y"
cTopTen     = "10"
cRangeMth   = "7"
cInFileName = ""
cAlgorithm  = "Momentum (original)"    // default; updated in RunAnalysis()

comboRangeMth  = null  // <<<<<
comboDebugSet  = null  // <<<<<
comboAlgorithm = null  // <<<<<  Algorithm Dropdown
stockSymbol    = null  // <<<<<
comboStockList = null
btnSortOrder   = null   // Toggle button: "Ranked" | "Alpha"
txtDollars     = null  // <<<<
oSplashLabel = null    // Splash image shown at startup in right panel
oYearlyTab   = null
oYearlyChart = null
oYearlyTable = null
oAlgoTab     = null
oHeatmapLabel= null
oConfigTable = null
oBuyHistTab    = null    // Buy History Tab
oContribTab    = null    // Stock Contributions Tab

# --- Overview Tab: Top-Line Summary Stat Cards -------------------------
oCardReturn    = null    // Total Return   value QLabel
oCardQQQ       = null    // QQQ / SPY Return  value QLabel
oCardRatio     = null    // Outperform x (QQQ/SPY)  value QLabel
oCardCAGR      = null    // Annual CAGR    value QLabel
oCardSharpe    = null    // Sharpe Ratio   value QLabel
oCardDD        = null    // Max Drawdown   value QLabel

# ------------------------------

lastDate = "01/02/2026"

$RangeMth     = 7        // Performance EndCol - StartCol
$Top10        = 7        // Buy if Rank <= 10
DataLen       = 10       // Nbr of Months of Data

csvFile       = "AAA-Spread.csv"   // NEEDED
StockCount    = 1

# ==============================

// There are 19 predefined QColor objects: 
// white, black, red, darkRed, green, darkGreen, blue, darkBlue, cyan, darkCyan, 
// magenta, darkMagenta, yellow, darkYellow, gray, darkGray, lightGray, color0 


# Constants for Styling
C_STYLE_DARK = "
    QWidget {
        background-color: #2b2b2b;
        color: #000000 ;             // #ffffff;
        font-family: 'Segoe UI', sans-serif;
        font-size: 17px;
    }
    QPushButton {
        background-color: #007acc;
        border: none;
        padding: 8px 16px;
        border-radius: 4px;
        color: white;
        font-weight: bold;
    }
    QPushButton:hover {
        background-color: #005999;
    }
    QPushButton:pressed {
        background-color: #004080;
    }
    QLineEdit, QComboBox {
        background-color: #3c3c3c;
        border: 1px solid #555;
        padding: 4px;
        border-radius: 3px;
        color: white;
    }
    QFrame {
        border: 1px solid #555;
        border-radius: 5px;
        margin-top: 10px;
        padding: 5px;
        background-color: #333;
    }
    QLabel {
        font-weight: bold;
        color: #cccccc;
    }
"

# =====================================
# =====================================

func main
    App = new QApp
        
      
    win = new QWidget() {
        setWinIcon(self,"appicon.png")
        setWindowTitle("Stock Analysis Pro - Ring Edition")
        resize(1400, 850)
        setStyleSheet(C_STYLE_DARK)

        # --- Layouts ---
        mainLayout     = new QVBoxLayout()
        controlsLayout = new QHBoxLayout()
        contentLayout  = new QHBoxLayout()

	    ###-----------------------------------
        ### Font Type and Size
            
        oFont = new qfont('Segoe UI',16,0,0)
        setfont(oFont)
		
		

        # --- Controls Section ---
        groupControls = new QFrame( win,0) {
            setFrameShape(QFrame_StyledPanel)
            setMaximumHeight(160)       // Tall enough for 2 rows + scroll list
            setSizePolicy(1, 0)         // Horizontal=Expanding, Vertical=Fixed
            
            # Main layout for the frame (Vertical - holds Row1 and Row2)
            frameLayout = new QVBoxLayout() {
                setContentsMargins(4, 2, 4, 2)   // Tight top/bottom margins
                setSpacing(2)
						

                # ---- ROW 1: Dollars + Debug ----
                row1Layout = new QHBoxLayout() {

                    # --- Dollars Label + Edit Box
                    addWidget(new QLabel(win){setText(" DollarsPerStock: ")})
                    txtDollars = new QLineEdit(win) {
                        setText("10000")
                        setFixedWidth(80)
                        setTextChangedEvent("DollarsChanged()")
                    }
                    addWidget(txtDollars)

                    #--------------------
                    # --- Debug Selections
                    addWidget(new QLabel(win){setText(" Debug: ")})
                    comboDebugSet = new QComboBox(win){
                            abcList = ["DebugToggle", "HistoryRet", "Array-Data", "Performance", "Sort", "Sort-Name","Rank",
					         "Buy-Price","Gain","Monthly-Perf","Compound","Summary-Stock",
							 "Summary-Total","Show-Top10","Gain-Details"]
                        for x in abcList additem(x,0) next
                        }
                    addWidget(comboDebugSet)
					
					//-------------------------
					// --- Algorithm Selection

					addWidget(new QLabel(win){setText(" Algorithm: ")})
					comboAlgorithm = new QComboBox(win){
							abcList = ["Momentum (original)", "All-Pairs Momentum", "Avg Momentum (all months)",
							           "Moving Average Cross", "MACD", "Sharpe Momentum", "Pullback from High", "Composite (blend)"]
						for x in abcList additem(x,0) next
						}
					addWidget(comboAlgorithm)

					//-------------------------
					// --- CurrentDate

					addWidget(new QLabel(win){setText(" Date: " )})
				    newDate = new QLineEdit(win) {
                        setText("  "+ Date() +"  "+ Time())         // Fill in with Current Date-Time  15/05/2026 09:30
                        setFixedWidth(130)                      
                    }
                    addWidget(newDate)
					
					
					//--------------------------

                    # Stretch to push items to the left
                    addStretch(1)
                }
                addLayout(row1Layout)

                # --------------------------------------
                # ---- ROW 2: All original controls ----
                controlsLayoutInner = new QHBoxLayout() {
                    
                    # Interval
                    addWidget(new QLabel(win){setText("Interval:")})
                    comboInterval = new QComboBox(win){
                        abcList = ["1mo", "1wk", "1d"]
                        for x in abcList additem(x,0) next
                        }
                    addWidget(comboInterval)
                
                    # Range
                    addWidget(new QLabel(win){setText("Range:")})
                    comboRange = new QComboBox(win){
                            abcList = ["2y","5y", "1y", "2y", "10y"]
                        for x in abcList additem(x,0) next
                        }
                    addWidget(comboRange)   

                    # TopTen
                    addWidget(new QLabel(win){setText("TopTen:")})
                    comboTopTen = new QComboBox(win){
                            abcList = ["10","7","5","3","1","2","3","4","5","6","7","8","9","10","12","15","18","20","25","30","40","50"]
                        for x in abcList additem(x,0) next
                        }
                    addWidget(comboTopTen)      

                    # Range-Months
                    addWidget(new QLabel(win){setText("RangeMth:")})
                    comboRangeMth = new QComboBox(win){
                            abcList = ["7","5","28","30","1","2","3","4","5","6","7","8","9","10","12","16","20","24","28","30","32","36","40","50","52","100","150","200","250","300"]
                        for x in abcList additem(x,0) next
                        }
                    addWidget(comboRangeMth)
                                            
                    
                    //---------------------

                    # Ticker File: Globals: txtTickerFile = null
                    addWidget(new QLabel(win){setText("Ticker File:")})
                    txtTickerFile = new QLineEdit(win){setText("Quotes-Mega-250.ini")}
                    addWidget(txtTickerFile)
                    
                                                            
                    btnBrowse = new QPushButton(win){setText("Browse...")}
                    btnBrowse.setStyleSheet("background-color: yellow;")
                    btnBrowse.setClickEvent("browseFile(this)")
                    addWidget(btnBrowse)
                                        
                    # -----------------------

                    # Run Quotes Button
                    btnQuotes = new QPushButton(win){setText("Get Quotes")}
                    btnQuotes.setStyleSheet("background-color: cyan;")
                    btnQuotes.setClickEvent("GetQuotes()")
                    addWidget(btnQuotes)

                    # Run Analysis Button
                    btnRun = new QPushButton(win){setText("Run Analysis")}
                    btnRun.setStyleSheet("background-color: cyan;")
                    btnRun.setClickEvent("RunAnalysis()")
					//btnRun.setEnabled(false)   // Disable until Get Quotes done
                    addWidget(btnRun)
                    
                    //-------------------
                    //------------------                

                    //--- Sort-Order label + toggle button (left of stock list) ---
                    addWidget(new QLabel(win){setText("Order:")})
                    btnSortOrder = new QPushButton(win){setText("Ranked")}
                    btnSortOrder.setStyleSheet("background-color: #9b59b6; color: white; font-weight: bold;")
                    btnSortOrder.setFixedWidth(80)
                    btnSortOrder.setClickEvent("ToggleSortOrder()")
                    addWidget(btnSortOrder)

                    # Ranked Stock Scroll List + Nav Buttons
                    comboStockList = new QListWidget(win) {
                        setFixedWidth(150)
                        setFixedHeight(95)
                        setToolTip("Select a ranked stock")
                        setCurrentRowChangedEvent("StockListSelected()")
                    }
                    addWidget(comboStockList)

                    # Display Stock NEXT Button 1.2.3.4.5
                    btnDisplayStockDN = new QPushButton(win){setText("Stk-NEXT")}
                    btnDisplayStockDN.setStyleSheet("background-color: cyan;")
                    btnDisplayStockDN.setClickEvent("DisplayStockDN()")
                    addWidget(btnDisplayStockDN)

                    # Display Stock PREVIOUS Button  5.4.3.2.1
                    btnDisplayStockUp = new QPushButton(win){setText("Stk-PREV")}
                    btnDisplayStockUp.setStyleSheet("background-color: cyan;")
                    btnDisplayStockUp.setClickEvent("DisplayStockUP()")
                    addWidget(btnDisplayStockUP)

                    # Hidden field to track current stock name (replaces visible stockSymbol QLineEdit)
                    stockSymbol = new QLineEdit(win){setText("TOT")}
                    stockSymbol.hide()
                    addWidget(stockSymbol)
                    
                    //----------------------

                    # Export Button
                    btnExport = new QPushButton(win){setText("Export CSV")}
                    btnExport.setStyleSheet("background-color: orange;")
                    btnExport.setClickEvent("exportCSV()")
                    //btnExport.setEnabled(false)
                    addWidget(btnExport)
                }
                addLayout(controlsLayoutInner)
            }
            setLayout(frameLayout)
        }

        # --- Content Section ---
        
        # Left: Data/Log
        groupData = new QFrame(win,0) {
            setFrameShape(QFrame_StyledPanel)
            frameLayout = new QVBoxLayout() {
                lblTitle = new QLabel(win) {
                    setText("Analysis Log")
                    setStyleSheet("color: #007acc; font-weight: bold;font-size: 14px;")
                }
                addWidget(lblTitle)

                txtLog = new QTextEdit(win){setReadOnly(true)setStyleSheet("font-size: 14px;")setText("Ready to start...")}
				txtLog.append("Date: "+ Date() +"  "+ Time() )
                //App.processEvents() # Keep UI responsive
				
                addWidget(txtLog)
            }
            setLayout(frameLayout)
        }

        # Right: Chart Area
        groupChart = new QFrame(win, 0) {
            setFrameShape(QFrame_StyledPanel)
            frameLayout = new QVBoxLayout() {
                lblTitle = new QLabel(win) {
                    setText("Performance Chart")
                    setStyleSheet("color: #007acc; font-weight: bold; font-size: 14px;")
                    setMaximumHeight(40)
                }
                addWidget(lblTitle)

                oChartWidget = new StockChart( win)
                oChartWidget.hide()   // Hidden until Run Analysis is clicked
                addWidget(oChartWidget)

                # Splash image shown at startup — capped to natural image size (373x576)
                oSplashLabel = new QLabel(win) {
                    splashPixmap = new QPixmap("CapAmer-1.png")
                    scaledPixmap = splashPixmap.scaled(373, 576, 1, 1)  // natural size, KeepAspectRatio=1, SmoothTransform=1
                    setPixmap(scaledPixmap)
                    setAlignment(132)   // Qt::AlignHCenter | Qt::AlignVCenter
                    setScaledContents(false)
                    setMaximumSize(373, 576)
                }
                addWidget(oSplashLabel)
            }
            setLayout(frameLayout)
        }

        # --- Add widgets to layouts 16px
        controlsLayout.addWidget(groupControls)
        
        oTabMain = new QTabWidget(win)
        oTabMain.tabBar().setUsesScrollButtons(false)
        oTabMain.tabBar().setExpanding(false)
        oTabMain.setStyleSheet("
            QTabBar::tab {
                background: #2b2b2b;
                color: #cccccc;
                padding: 5px 14px 8px 14px;
                font-size: 13px;
                font-weight: bold;
                min-width: 150px;
                border: 1px solid #555;
                border-bottom: none;
                margin-right: 2px;
            }
            QTabBar::tab:selected {
                background: #007acc;
                color: white;
            }
            QTabWidget::pane {
                border: 1px solid #555;
            }
        ")

        // --- Tab 0 -- existing Overview (Stat Cards + Log + Chart)
        tabPage0  = new QWidget()
        overviewV = new QVBoxLayout()

        # --- Top-Line Summary Stat Cards --------------------------------
        cardsRow = new QHBoxLayout() {
            setSpacing(8)
            setContentsMargins(0, 0, 0, 0)
        }
        oCardReturn = BuildStatCard(win, cardsRow, "Total Return")
        oCardQQQ    = BuildStatCard(win, cardsRow, "QQQ / SPY Return")
        oCardRatio  = BuildStatCard(win, cardsRow, "Outperform x (QQQ/SPY)")
        oCardCAGR   = BuildStatCard(win, cardsRow, "Annual CAGR")
        oCardSharpe = BuildStatCard(win, cardsRow, "Sharpe Ratio")
        oCardDD     = BuildStatCard(win, cardsRow, "Max Drawdown")

        cardsFrame = new QWidget() {
            setMaximumHeight(46)
        }
        cardsFrame.setLayout(cardsRow)
        overviewV.addWidget(cardsFrame)

        existingH = new QHBoxLayout()
        existingH.addWidget(groupData)
        existingH.addWidget(groupChart)
        existingH.setStretch(0, 1)
        existingH.setStretch(1, 2)

        existingWrap = new QWidget()
        existingWrap.setLayout(existingH)
        overviewV.addWidget(existingWrap)

        tabPage0.setLayout(overviewV)
        oTabMain.addTab(tabPage0, "Overview")

        // --- Tab 1 -- Yearly vs QQQ
        BuildYearlyTab(oTabMain)

//        // Tab 2 -- Algorithm Grid
//        BuildAlgoGridTab(oTabMain)

        // Tab 3 -- Buy History
        BuildBuyHistTab(oTabMain)

        // Tab 4 -- Monthly Results
        BuildMonthlyResultsTab(oTabMain)

        // Tab 5 -- Stock Contributions
        BuildStockContribTab(oTabMain)
		
        // Tab 2 -- Algorithm Grid
        BuildAlgoGridTab(oTabMain)		

        oTabMain.setCurrentChangedEvent("OnTabChanged()")
        contentLayout.addWidget(oTabMain)

        mainLayout.addLayout(controlsLayout)
        mainLayout.addLayout(contentLayout)
        mainLayout.setStretch(0, 0)    // Controls row: do NOT stretch
        mainLayout.setStretch(1, 1)    // Content area: takes all remaining space

        setLayout(mainLayout)
        show()
    }

    App.exec()
 

//=================================================================

//====================================== 

Func browseFile(win)
    new QFileDialog(win) {
        cFile = getOpenFileName(win, "Select Ticker File", ".", "INI Files (*.ini);;All Files (*.*)")
        if cFile != ""
            //txtTickerFile.setText(cFile)
                        
            pos         = subStr(cFile, "Quotes" )    // Strip Path upto Quotes-xxx.ini
            cInFileName = subStr(cFile, pos )
            txtTickerFile.setText(cInFileName )       // Display It
            
            See "Quotes: "+ cInFileName +nl
        ok
    }


// ----------------------------------------------------------------
// Update $Dollars global whenever the Dollars edit box changes
// ----------------------------------------------------------------

Func DollarsChanged()
    val = txtDollars.text()
    if val != "" and number(val) > 0
        $Dollars = number(val)
    ok

// ----------------------------------------------------------------
// Note: Ticker is "AAPL" in this $url
// $url = 'https://query1.finance.yahoo.com/v8/finance/chart/AAPL?metrics=high?&interval=1wk&range=1mo'
//-----------------------------------------------------------------

Func GetQuotes()

    # Restore splash image and hide chart when getting new quotes
    oChartWidget.hide()
    if oSplashLabel != null
        oSplashLabel.show()
    ok

btnRun.setEnabled(true)              // Disable until Get Quotes done

    todayDate = Date() +" "+ Time()  // In newDate Label
	newDate.setText("  "+ todayDate)


ExtractYear = 0         // 1=Year  0=Month

WhoCalled = 'Ring'      // Ring 2 sysArgs  .Exe 6 sysArgs
$Symbol   = 'BMO'       // <<< Symbol    $url2 
$Interval = '1mo'       // <<< Interval  $url4                            
$Range    = '5y'        // '10y'  // <<< Range     $url6   "1y","2y","5y","10y" 


    cInterval   = comboInterval.currentText()
    cRange      = comboRange.currentText()
    cTopTen     = comboTopTen.currentText()
    cRangeMth   = comboRangeMth.currentText()
    cAlgorithm  = comboAlgorithm.currentText()
    cFile       = txtTickerFile.text()
    cInFileName = txtTickerFile.text() 
    
    
$Interval =    cInterval    // Curl GetQuotes
$Range    =    cRange       // Curl GetQuores
$Top10    = 0+ cTopTen      // YearlyReturns
$RangeMth = 0+ cRangeMth    // YearlyReturns  "$RangeMth" is Month Range | NOT $Range for Curl
$Algorithm=    cAlgorithm   // YearlyReturns  Ranking Algorithm selected


See "GetQuotes: $Interval: "+ $Interval +" $Range: "+ $Range +" $Top10: "+ $Top10 +" RangeMth: "+ $RangeMth +" Quotes: "+ cInFileName +nl 


//------------------------------------------------------------

  DirName      =    CurrentDir()
//cInFileName  =    cFile              // Already extracted
  cOutFileName = "./Quotes.result"
  $csvDir      =   ""


//------------------------------------------------------------
// MAKE URL


$url1 = 'https://query1.finance.yahoo.com/v8/finance/chart/'
$url2 =  $Symbol                          // <<< Ticker 'RY'
$url3 = '?metrics=high?&interval='
$url4 =  $Interval                        // <<< Interval   1wk'                           
$url5 = '&range='
$url6 =  $Range                           // <<< Range '10y'

$URL  = $url1 + $url2 + $url3 + $url4 + $url5 + $url6

//--- Extract QuotesXYZ.ini => array of symbols -- Global Clear Old List: --- 

aSymbols  = [] 
Add(aSymbols,"QQQ")
Add(aSymbols,"SPY") 


    //==================================================================
    //==================================================================
    
    ###-------------------------------------------------------------
    ### HISTORY.ini --- Get SYMBOL from Quote.ini each line in file
    ### NOTE: this list must be built BEFORE the "no internet" check below,
    ###       since aSymbolsAlpha is needed either way (online or offline)

    fpIn = fopen(cInFileName,"r")             //  Yahoo    BigCharts   DividendChannel   
    while not feof(fpIn)                  //  BMO.TO   CA:BMO      BMO.CA
        line   = Readline(fpIn)           //  CTC-A.TO CA:CTC.A    CTC.A.CA
        if line != ''                     //  ACO-X.TO CA:ACO.X    ACO.X.CA
            aParts = split(line," ")      //  HR-UN.TO CA:HR.UT    HR.UN.CA
            $Symbol = aParts[1]           
            
            Add(aSymbols, $Symbol)   
        ok
    end
    fclose(fpIn)

    //--- Build alphabetically sorted copy of aSymbols for Alpha navigation ---
    aSymbolsAlpha = sort( aSymbols )
    


    //========================================================================
    // CURL INIT  fix 2025-Mar-01
    //--- // START CURL INIT   ---
    
    curl = curl_easy_init()                      
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U;") 


    //========================================================================
    // CONNECTIVITY PRE-CHECK -- fix 2026-Aug-23
    // Test the FIRST symbol before opening/truncating AAA-Spread.csv.
    // The old code opened AAA-Spread.csv for "w" (which erases it) BEFORE
    // ever checking whether we had internet, so a saved file was destroyed
    // the instant Get Quotes was clicked -- even when offline. Testing first
    // means a saved AAA-Spread.csv / AAA-Spread.csv.bkp is never touched
    // unless we actually have fresh data to replace it with.
    //========================================================================

    $Symbol = aSymbols[1]
    $url2   = $Symbol
    $url4   = $Interval
    $url6   = $Range
    $URL    = $url1 + $url2 + $url3 + $url4 + $url5 + $url6

    curl_easy_setopt(curl, CURLOPT_URL, $url)
    cStr = curl_easy_perform_silent(curl)

	// --------------------------------------
	// NO INTERNET -- fall back to previously saved quotes, don't touch the CSV
	// --------------------------------------

    if ( len(cStr) = 0 )

        See "Date: "+ Date() +"  "+ Time() +nl
        See nl+"NO INTERNET CONNECTION: " +nl +"USING PREVIOUSLY SAVED QUOTES: " +nl

        txtLog.append("NO INTERNET CONNECTION -- using previously saved quotes")
        App.processEvents()                         # Keep UI responsive

        //--- Prefer the .bkp written after the last FULLY successful GetQuotes()
        //    (see line ~930), fall back to whatever AAA-Spread.csv already has
        //    on disk. Neither file was opened/truncated above, so both are
        //    still intact -- unlike before this fix.

        if fexists("AAA-Spread.csv.bkp")
            See 'DEBUG: Will Use existing "AAA-Spread.csv.bkp" '+nl 
            cString =  Read("AAA-Spread.csv.bkp")           // bkp OLD CSV
                       Write("AAA-Spread.csv", cString)      // refresh working copy
            txtLog.append("Using AAA-Spread.csv.bkp (last successful download)")
        else
            if fexists("AAA-Spread.csv")
                See 'DEBUG: No "AAA-Spread.csv.bkp" found -- using existing "AAA-Spread.csv" '+nl 
                txtLog.append("Using AAA-Spread.csv as-is (no backup file found)")
            else
                See 'ERROR: No saved quotes found (AAA-Spread.csv / AAA-Spread.csv.bkp missing)'+nl 
                txtLog.append("ERROR: No internet AND no saved quotes file found -- cannot run analysis")
                App.processEvents()
                return   // Nothing we can do without any data at all
            ok
        ok

        // Call RunAnalysis() (not just YearlyReturns()) so the offline run
        // finishes exactly like a normal one: hides the splash image, shows
        // the chart, refreshes the stat cards / stock list / other tabs, and
        // runs the RangeMth/TopK grid search ("Grid best: ..."). Calling
        // YearlyReturns() alone -- the previous behaviour -- left the splash
        // image on screen and skipped the grid search entirely.
        RunAnalysis()

        return // Skip the live-download loop below

    ok

    //========================================================================
    // INTERNET IS AVAILABLE -- proceed with the normal live download
    //========================================================================

$csvSpread   =  "AAA-Spread.csv"        # Directory + SpreadSheet New to OLD reversed
fpSpread     =  fopen($csvSpread,"w")   # Write to SpreadSheet CSV file

    aClosedPrices = List(len(aSymbols), 1) 
    count = 1   
    foreach $Symbol in aSymbols

    

    //See ""+count +" Working on: "+ $Symbol +tab +tab
    $url2 = $Symbol                          // <<< Ticker
    $url4 = $Interval                        // <<< Interval                             
    $url6 = $Range                           // <<< Range

    //===================================================
    // COMBOL URL 
 
    $URL = $url1 + $url2 + $url3 + $url4 + $url5 + $url6    
    
    //====================================================
    // CURL GET DATA  $URL ===>>>
          
    curl_easy_setopt(curl, CURLOPT_URL, $url);   ### <<<=== SetOpt + URL               
    cStr = curl_easy_perform_silent(curl)        ### <<<=== GET DATA ===>>> cStr
 
            // See cSTR
            // See nl+"len(cStar): "+ len(cStr) +nl
    
	// --------------------------------------
	// CONNECTION LOST MID-DOWNLOAD (rare) -- don't leave a half-written
	// AAA-Spread.csv on disk; restore the last good backup instead.
	// --------------------------------------
	
    if ( len(cStr) = 0 )  
	    See "Date: "+ Date() +"  "+ Time() +nl
        See nl+"CONNECTION LOST MID-DOWNLOAD: " +nl +"USING PREVIOUSLY SAVED QUOTES: " +nl
		
		txtLog.append("Connection lost mid-download -- restoring last good quotes")
		App.processEvents()                         # Keep UI responsive
		
        fclose(fpSpread)                  // opened above -- close before overwriting

        if fexists("AAA-Spread.csv.bkp")
            cString =  Read("AAA-Spread.csv.bkp")	      // bkp OLD CSV
                       Write("AAA-Spread.csv", cString)  // restore working copy
        ok

        // Same reasoning as the pre-check branch above -- RunAnalysis()
        // finishes the UI properly (hides splash, shows chart, grid search).
        RunAnalysis()

        return // Do nothing

    ok  	
	
  
    
    //===========================================================================
    //  Line 33 Parsing Error (JSONLib) : Can't parse the content
    //  <!doctype html public "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
    //  <html>
    //  <head>
    //  <title>Yahoo! - Error report</title>
    //
    //  In raise() In function json2list() 
    //  in//fileC:\ring\bin\load//../../libraries/jsonlib/jsonlib.ring
    //  Called from line 466 In function getquotes() 
    
    
    //---JSON ERROR in YAHOO----------------------------------
    
    if  subStr(cStr, '<title>Yahoo! - Error report</title>' )
                  See ""+ $Symbol +"  JSON: Yahoo! - Error report:  " +nl
				  
        txtLog.append(""+ $Symbol +"  JSON: Yahoo! - Error report:  " )
		App.processEvents() # Keep UI responsive
				
        continue
    ok


    //---------------------------------
	// aLIST CREATED from JSON Yahoo
	
    // See $Symbol +tab    
    aList = JSON2List( cStr )   // <<<=== Yahoo can have ERROR above


    //--- NO DATA FOUND --------------------------
    if ( substr( cStr, 'No data found' ) )
        See $Symbol +tab +" Notfound: " +nl
        continue   // foreach $Symbol in aSymbols
    ok
 
            // aOpen      =  aList[:chart][:result][1][:indicators][:quote][1][:open]
            // aHigh      =  aList[:chart][:result][1][:indicators][:quote][1][:high]
            // aLow       =  aList[:chart][:result][1][:indicators][:quote][1][:low]
            // aClose     =  aList[:chart][:result][1][:indicators][:quote][1][:close]
            // aVolume    =  aList[:chart][:result][1][:indicators][:quote][1][:volume]
            // aAdjClose  =  aList[:chart][:result][1][:indicators][:adjclose][1][:adjclose]
            // aTimeStamp =  aList[:chart][:result][1][:timestamp]   // 1726459200
 
 
    //--- EXTRACT JSON to aLIST  Open Close etc --------------------------------
    aOpen      =  aList[:chart][:result][1][:indicators][:quote][1][:open]
    aAdjClose  =  aList[:chart][:result][1][:indicators][:adjclose][1][:adjclose]
    aTimeStamp =  aList[:chart][:result][1][:timestamp]

    // --- Last aTimeStamp Date to dd/mm/yyyy ---
	if $Symbol = "QQQ"
	    lastDate  = EpochToDate( aTimeStamp[len(aTimeStamp)] )        
        aLastDate = split(lastDate,"/")  
		
		See "Symbol QQQ Date: "+ $Symbol +" "+ lastDate  +" "+ len(aTimeStamp) +nl
		
		aTDate = List( len(aTimeStamp) )
		
		for i = 1 to len(aTimeStamp)                     // was 1
		    aTDate[i]  = EpochToDate( aTimeStamp[i] )  		
		next
		
	ok	
	

	
	
	// --- FIX First of Month in last aTimeStamp --- 
	// --- Make a last Duplicate entry           ---
	
	aDate = split(Date(),"/")
	if aLastDate[1] = "01"        // First of Month 
	 
	    Pos = len(aTimeStamp)
		
		ADD(aOpen,      aOpen[Pos])
		ADD(aAdjClose,  aAdjClose[Pos])
		Add(aTimeStamp, aTimeStamp[Pos])
	 	 
	ok
	 	
	// ------------------------------
		
	
	//--- In MONTHLY Yahoo Open=01/mm  aAdjClose= CurDay -----------
	// CREATE aClosedPrices
	
	aClosedPrices[count][1] = $Symbol
	for p = 2 to len(aAdjClose)     
		 ADD( aClosedPrices[count], aAdjClose[p])
		 
	next  
	
    //-----------------------------------------------------
    //	USING OPEN Prices
	//--- Use Last Close Price to Chart last most recent trading close price

    if len(aTimeStamp) = 0 
       See " "+ $Symbol +" lenTS: "+ len(aTimeStamp) +nl
       continue
    ok
	
	lenTime        = len(aTimeStamp)
	aOpen[lenTime] = aAdjClose[lenTime]    // FIX use last close for Chart Display
	
	aAdjClose = aOpen                      // <<<=== USE OPEN PRICEs , Pretend they are AdjClose for rest of code
 

    //---------------------------------------------
    // SKIP EMPTY -- USE continue for next Symbol
	
    if ( lenTime = 0 )
         See $Symbol +tab +" Len: "+ lenTime +nl
         continue
    ok   

    
    //---------------------------------------------------
    // Combine Format from Arrays
        
    
    ###--- ONE LINE AT A TIME | $NextLine put in reverse order -----
    cHistory = ""
    Spread   = ""
    Spread   = Spread + aAdjClose[1]       // SpreadSheet Line
     
	 

             //------------------------------------

    for k =  2 to lenTime          // 2 .. Old to New
    
             lastDate = EpochToDate( aTimeStamp[k] )        // This Date to dd/mm/yyyy
            alastDate = split(lastDate,"/")                 
            
               
            ###---FIX NULL --- SpreadSheet Line for $Symbol ---------
			if aAdjClose[k] =  "null" OR   aAdjClose[k] = " null"
			
			  //See "CSV NULL: "+ k +" |"+ aAdjClose[k] +"|"+ "  Prev: |"+ aAdjClose[k-1] +"|"+     nl
			    aAdjClose[k] = aAdjClose[k-1]
		    ok		
			
            Spread = Spread +", " + aAdjClose[k]
            
                                    
    next
    
    //=======================================================================
    // FILL IN LEFT BY REPEATING OLD DATA if Not equal to DataLen 121 or 11
    
    
    if $Symbol = "QQQ"                        // FIRST in QUOTES.INI  SPY
        DataLen = lenTime   /// +1                  // Symbol + Prices
        See nl+"DataLen QQQ: "+ DataLen +nl
    ok
    
    addSize = DataLen - lenTime  // 121 - 80 =   41 to add
    if lenTime < DataLen
    
                //See nl+"Len aTimeStamp: "+ lenTime +" addSize: "+ addSize +nl
                //See "adjClose[1]: "+ aAdjClose[1] +" <<<<< "+nl
    
        for i = 1 to addSize
            Spread = string(aAdjClose[1]) +", "+ Spread   // Insert on Left
            
        next
    ok
    
    //---------------------
    
    Spread = $Symbol +", "+ Spread    // ADD Symbol
    Spread = Spread +nl               // Show final quotes for this $Symbol
    
    Fputs(fpSpread, Spread)
    
    //---------------------------------------------------
    // See "Finished history: "+count +" "+ $Symbol +nl
    
        txtLog.append("Finished history: "+ count +" "+ $Symbol )
        App.processEvents() # Keep UI responsive
  
    //--------------------------------------------------  
  
    count++
    
 next  // End -- foreach $Symbol in aSymbols
 		txtLog.append("Date: "+ Date() +"  "+ Time() )
        App.processEvents() # Keep UI responsive
 
 
   // --- DATE ------------
   Spread = ""
	
	for k = 1 to len(aTDate)
	    Spread = Spread +", " + aTDate[k]      // <<<<<<<<<<
	next 
	Spread = "Date"  + Spread                  // ADD Symbol  Date
	Spread = Spread +nl                        // Show final quotes for this $Symbol
   Fputs(fpSpread, Spread)	
	
 
 //---------------------
 // CLOSE EXCEL SpreadSheet: ... Error in parameter, NULL pointer!
    fclose(fpSpread)         //  Error in parameter, NULL pointer!  IF EXCEL IS OPEN.  Close it  

    cRead = Read($csvSpread)           // make a bkp for offline
	Write($csvSpread +".bkp", cRead)
 
 //--------------------
 
    //------------------------------------------------------
    //--- FIX COLS if less than QQQ len. 
	//    FILL IN OldPrice if NbrPrices < DataLen  QQQ Len+1
   
    for cRow = 1 to len(aClosedPrices)
	    lenRow  = len(aClosedPrices[cRow])
        nCol    = DataLen - lenRow -1           // How many Cols to Insert
			
	   
	    // FIX Yahoo Error -- Sym: 0 DataLen: 62 lenRow: 1 nbrCol: 60 st
		// FILL in Cols at Left for stocks with Not Enough Data
		
	    if nCol > 0 AND lenRow > 10  
		
		    //See "Sym: "+ aClosedPrices[cRow][1] +" DataLen: "+ DataLen +" lenRow: "+ lenRow +" nbrCol: "+ nCol +nl
		    
		    for k = 1 to nCol
			    // See "Sym: "+ aClosedPrices[cRow][1] +" k-nCol: "+ k +nl
		        PriceOld = aClosedPrices[cRow][2]
		        Insert(aClosedPrices[cRow], 2, PriceOld )  // Fill LEFT List Index Value ..Col	
			next  
		ok
		    
	next
   
 
   # See "aClosedPrices 2D =================="+nl
   # DebugArray(aClosedPrices)
   # See "aClosedPrices 2D =================="+nl
 
 //======================================= 
 //=================================================================

Func RunAnalysis()
    # Hide splash image and reveal chart panel
    if oSplashLabel != null
        oSplashLabel.hide()
    ok
    oChartWidget.show()

    YearlyReturns()         // Runs full analysis — populates nList ranked by performance

    UpdateStatCards()       // Push Total Return / QQQ Return / Outperform x / CAGR / Sharpe / Max Drawdown

    // aSymbolsAlpha already built when .ini was read in GetQuotes()
    // Just refresh the scroll list in whatever order is selected
    StockCount = 1
    PopulateStockList()

    if len(nList) > 0
        txtLog.append("Stock list updated: " + string(len(nList)) + " stocks ranked.")
    ok

    App.processEvents()

    RefreshYearlyTab()
    App.processEvents()

    RunAlgoGrid()
    RefreshBuyHistTab()
    RefreshMonthlyResultsTab()
    RefreshStockContribTab()

return

//======================================   

    See "Finished: History."+ nl
    
    t1 = clock()
    Sleep(1)
    t3 = clock()
    
    //See "Sleep finished.  Total Time: " + ( (t3-t1)/ClocksPerSecond() ) + " Sec" + nl
    
    See "CSV File Closed: "+  $csvSpread +nl+nl
    
        txtLog.append("Finished Quotes:  CSV File Closed: "+ $csvSpread )
        //App.processEvents() # Keep UI responsive
    
            // See "Press Enter to Exit"+ nl
            // keyChar = GetChar()
    
 return 
    
//============================================================= 
//=============================================================
// DISPLAY STOCK  the Selected Stock as a Chart from lineEdit1 box 
// lineedit1.setText("SPY")
// $symbol = Upper( lineEdit1.text() )
// aList has Price Data for Symbols
// nList has Name by Perforance in Last Cell
// txtSymbol = new QLineEdit(win){setText("NVDA")}


// PREV 

Func DisplayStockUp()
    StockDirection = "Up"

    nMax = comboStockList.count()
    if nMax = 0
        PopulateStockList()
        nMax = comboStockList.count()
    ok

    StockCount--
    if StockCount < 1   StockCount = nMax   ok

    DisplayStock()

return

//=====================
// NEXT
    
Func DisplayStockDn()

    StockDirection = "DN"

    nMax = comboStockList.count()
    if nMax = 0
        PopulateStockList()
        nMax = comboStockList.count()
    ok

    StockCount++
    if StockCount > nMax   StockCount = 1   ok

    DisplayStock()

return

//=================================================
// DISPLAY STOCK -- aSumTotal -- MU,LRCX APP etc

Func DisplayStock()

        if len(nList) = 0  return  ok

        if SortOrder = "Alpha"

            // In Alpha mode, StockCount is the 1-based row in the sorted list widget
            nRows = comboStockList.count()
            if nRows = 0  return  ok
            if StockCount < 1         StockCount = nRows   ok
            if StockCount > nRows     StockCount = 1       ok

            // Get ticker name directly from the sorted list widget
            bUpdatingList = true
            comboStockList.setCurrentRow(StockCount - 1, 3)
            bUpdatingList = false
            stockName = comboStockList.item(StockCount - 1).text()

            // Strip the "   N" rank number appended to the right of the ticker
            aTok = split(stockName, " ")
            if len(aTok) > 0
                stockName = aTok[1]
            ok

        else

            // Ranked mode — ticker name is in the LAST column of nList
            if StockCount < 1             StockCount = len(nList)   ok
            if StockCount > len(nList)    StockCount = 1            ok
            PosEnd    = len(nList[1])
            stockName = nList[StockCount][PosEnd]
            if comboStockList.count() > 0
                bUpdatingList = true
                comboStockList.setCurrentRow(StockCount - 1, 3)
                bUpdatingList = false
            ok

        ok

        stockSymbol.setText(stockName + "  " + StockCount)

        for k = 1 to len(aList)
            if aList[k][1] = stockName
                aSumTotal[1] = aList[1]
                aSumTotal[2] = pList[1]
                aSumTotal[3] = aList[k]
                aSumTotal[4] = pList[2]      // SPY performance row (pList row 2)
            ok
        next

        if StockCount <= len(nList)

            LenD = len(aSumTotal[3])

            Del(aSumTotal[1], len(aSumTotal[1]))
            Del(aSumTotal[1], 1)

            Del(aSumTotal[2], len(aSumTotal[2]))
            Del(aSumTotal[2], 1)

            Del(aSumTotal[3], 1)

            Del(aSumTotal[4], len(aSumTotal[4]))
            Del(aSumTotal[4], 1)

            oChartWidget.setData(aSumTotal)

        ok

return  

//=============================================================
// POPULATE the QListWidget with ranked stock names from nList
// Called lazily on first Stk-NEXT / Stk-PREV press once nList is ready

Func PopulateStockList()

    comboStockList.clear()

    if len(nList) = 0
        return
    ok

    if SortOrder = "Alpha"

        // Build a symbol -> rank lookup from nList (Ranked order) so we can
        // show each stock's rank number to the right of its ticker below
        aRankLookup = []
        if len(nList) > 0 AND islist(nList[1])
            PosEndR = len(nList[1])
            for i = 1 to len(nList)
                symTmp = nList[i][PosEndR]
                if isstring(symTmp)
                    aRankLookup + [symTmp, i]
                ok
            next
        ok

        // Find the longest ticker so the rank numbers line up in a column
        nMaxLen = 0
        for i = 1 to len(aSymbolsAlpha)
            sName = aSymbolsAlpha[i]
            if sName != "Date" AND len(sName) > nMaxLen
                nMaxLen = len(sName)
            ok
        next

        // aSymbolsAlpha was sorted when the .ini file was read in GetQuotes()
        for i = 1 to len(aSymbolsAlpha)
            sName = aSymbolsAlpha[i]
            if sName != "Date"

                nRank = 0
                for k = 1 to len(aRankLookup)
                    if aRankLookup[k][1] = sName
                        nRank = aRankLookup[k][2]
                        exit
                    ok
                next

                sLine = sName
                for k = len(sName) to nMaxLen
                    sLine = sLine + " "
                next
                sLine = sLine + "   "
                if nRank > 0
                    sLine = sLine + string(nRank)
                ok

                comboStockList.addItem(sLine)
            ok
        next

    else

        // Ranked order — nList sorted by performance, ticker name is in the LAST column
        if len(nList) > 0 AND islist(nList[1])
            PosEnd = len(nList[1])
            for i = 1 to len(nList)
                sName = nList[i][PosEnd]
                if isstring(sName) AND sName != "Date"
                    comboStockList.addItem(string(i) + ". " + sName)
                ok
            next
        ok

    ok

    // Sync highlight to current position — guard flag prevents StockListSelected firing
    if comboStockList.count() > 0
        syncRow = StockCount - 1
        if syncRow >= 0 AND syncRow < comboStockList.count()
            bUpdatingList = true
            comboStockList.setCurrentRow(syncRow, 3)
            bUpdatingList = false
        ok
    ok

return

//=============================================================
// USER clicked a row in the Ranked Stocks list => jump directly to that stock

Func StockListSelected()

    // Ignore programmatic row changes triggered by PopulateStockList / DisplayStock
    if bUpdatingList  return  ok

    row = comboStockList.currentRow()   // 0-based
    if row < 0  return  ok

    StockCount     = row + 1
    StockDirection = "DN"

    // Get ticker name from the list widget using item(row).text()
    stockName = comboStockList.item(row).text()

    // Strip the "N. " rank prefix present in Ranked mode
    if SortOrder = "Ranked"
        dotPos = substr(stockName, ". ")
        if dotPos > 0
            stockName = substr(stockName, dotPos + 2)
        ok
    else
        // Strip the "   N" rank number appended to the right in Alpha mode
        aTok = split(stockName, " ")
        if len(aTok) > 0
            stockName = aTok[1]
        ok
    ok

    if stockName = "Date"  return  ok

    stockSymbol.setText(stockName + "  " + StockCount)

    for k = 1 to len(aList)
        if aList[k][1] = stockName
            aSumTotal[1] = aList[1]
            aSumTotal[2] = pList[1]
            aSumTotal[3] = aList[k]
            aSumTotal[4] = pList[2]      // SPY performance row (pList row 2)
        ok
    next

    Del(aSumTotal[1], len(aSumTotal[1]))
    Del(aSumTotal[1], 1)
    Del(aSumTotal[2], len(aSumTotal[2]))
    Del(aSumTotal[2], 1)
    Del(aSumTotal[3], 1)
    Del(aSumTotal[4], len(aSumTotal[4]))
    Del(aSumTotal[4], 1)

    oChartWidget.setData(aSumTotal)

return

//=============================================================
//=============================================================
// bList = BuyPrice 


//=============================================================
// TOGGLE between Ranked and Alphabetical navigation order

Func ToggleSortOrder()
    if SortOrder = "Ranked"
        SortOrder = "Alpha"
        btnSortOrder.setText("Alpha")
        btnSortOrder.setStyleSheet("background-color: #e67e22; color: white; font-weight: bold;")
    else
        SortOrder = "Ranked"
        btnSortOrder.setText("Ranked")
        btnSortOrder.setStyleSheet("background-color: #9b59b6; color: white; font-weight: bold;")
    ok

    StockCount = 1          // Reset to first position in new order
    if len(nList) > 0
        PopulateStockList()
        DisplayStock()
    ok

return

//=============================================================

Func exportCSV()

See "IN ExportCSV "+nl

    new QFileDialog(win) {
        cFile = getSaveFileName(win, "Save CSV", "AAA-CompareResult.csv", "CSV Files (*.csv)")
        if cFile != ""
            
            fp = fopen(cFile, "w")
            
            # Header
            fwrite(fp, "Stock, BuyPrice " + nl)
            
            # Data
            nRows = len(bList)
            nCols = len(bList[1])

            
            for i = 1 to nRows
                for j = 1 to nCols
                          
                    fwrite(fp, "" + bList[i][j] +"," )
                    
                    
                next
                fwrite(fp, "" + nl )
            next
            
            fclose(fp)
            txtLog.append("Successfully exported to: " + cFile)
        ok
    }
    
    
//============================================================= 
//=============================================================
    
    
 
//============================================================= 
//=============================================================
// FUNCTIONS
// Convert Epoch Secs to Human Readable Date

Func OnTabChanged()
    DrawYearly()
    DrawHeatmap()
    // Redraw bar chart when tab is activated -- ensures correct label dimensions
    if len(aContribData) > 0
        DrawContribBars()
    ok
Return

Func EpochToDate(EpochSecs)

   NbrDays   = EpochSecs / 86400                    // 1726776001
   DateHuman = AddDays( "01/01/1970", NbrDays )
 return DateHuman                                   // 19/09/2024


//=================================================================
// STAT CARDS  -- Overview Tab top-line summary (Total Return, QQQ
// Return, Outperform x, Annual CAGR, Sharpe Ratio, Max Drawdown)
// Mirrors the "cards_frame" row in the Python app (Stock_Analysis_GUI_v2.py)
//=================================================================

// Builds one card (title + big value) and adds it to oLayout.
// Returns the value QLabel so callers can update its text/color later.

Func BuildStatCard(parentWin, oLayout, cTitle)

    oFrame = new QFrame(parentWin, 0) {
        setFrameShape(QFrame_StyledPanel)
        setStyleSheet("QFrame { background-color: #dceeff; border: 1px solid #a9cdec; border-radius: 5px; }")
    }

    oHBox = new QHBoxLayout() {
        setContentsMargins(12, 6, 12, 6)
        setSpacing(6)

        oTitleLbl = new QLabel(parentWin) {
            setText(cTitle + ":")
            setStyleSheet("color: #000000; font-size: 12px; font-weight: bold; border: none; background: transparent;")
        }
        addWidget(oTitleLbl)

        oValueLbl = new QLabel(parentWin) {
            setText("--")
            setStyleSheet("color: #000000; font-size: 12px; font-weight: bold; border: none; background: transparent;")
        }
        addWidget(oValueLbl)

        addStretch(1)
    }
    oFrame.setLayout(oHBox)
    oLayout.addWidget(oFrame)

Return oValueLbl

//-----------------------------------------------------------------
// Pushes the freshly-computed globals ( $maxTOT / $maxQQQ / $Ratio /
// $CAGR / $Sharpe / $MaxDD -- all set in Stock-YearlyReturns.ring )
// into the stat cards. Called from RunAnalysis() after YearlyReturns().

Func UpdateStatCards()

    if oCardReturn = null  return  ok

    nTotRet = ($maxTOT  - 1) * 100
    nQQQRet = ($maxQQQ  - 1) * 100
    nSPYRet = ($maxSPY  - 1) * 100
    nCAGR   =  $CAGR         * 100
    nMaxDD  =  $MaxDD        * 100

    oCardReturn.setText( FmtSigned(nTotRet, 1) + "%" )
    SetCardColor(oCardReturn, "#000000")

    oCardQQQ.setText( "QQQ " + FmtSigned(nQQQRet, 1) + "%   SPY " + FmtSigned(nSPYRet, 1) + "%" )
    SetCardColor(oCardQQQ, "#000000")

    oCardRatio.setText( FmtNum($Ratio, 2) + "x / " + FmtNum($RatioSPY, 2) + "x" )
    SetCardColor(oCardRatio, "#000000")

    oCardCAGR.setText( FmtSigned(nCAGR, 1) + "%" )
    SetCardColor(oCardCAGR, "#000000")

    oCardSharpe.setText( FmtNum($Sharpe, 3) )
    SetCardColor(oCardSharpe, "#000000")

    oCardDD.setText( "-" + FmtNum(nMaxDD, 1) + "%" )
    SetCardColor(oCardDD, "#b02a24")

Return

//-----------------------------------------------------------------

Func SetCardColor(oLbl, cColor)
    oLbl.setStyleSheet("color: "+ cColor +"; font-size: 12px; font-weight: bold; border: none; background: transparent;")
Return

//-----------------------------------------------------------------
// Dark green if >= 0,  Dark red if < 0  (kept readable on the pale-blue card)

Func PickColor(n)
    if n >= 0  return "#0d5fa8"  ok
Return "#b02a24"

//-----------------------------------------------------------------
// Round to nDec decimals and prepend a "+" sign when >= 0
// eg FmtSigned(287.14, 1) => "+287.1"   FmtSigned(-14.2, 1) => "-14.2"

Func FmtSigned(n, nDec)
    cSign = ""
    if n >= 0  cSign = "+"  ok
Return cSign + FmtNum(n, nDec)

//-----------------------------------------------------------------
// Format n to exactly nDec decimal places (Ring has no built-in round(),
// so we roll our own using floor() -- same trick as NumFmt() in
// Stock-YearlyReturns.ring, just with a configurable decimal count).
// eg FmtNum(287.14, 1) => "287.1"   FmtNum(-14.26, 2) => "-14.26"

Func FmtNum(n, nDec)
    n      = 0 + n            // ensure numeric
    cSign  = ""
    if n < 0   cSign = "-"   n = -n   ok

    nFactor  = 1
    for i = 1 to nDec
        nFactor *= 10
    next

    nScaled = floor(n * nFactor + 0.5)     // round to nDec decimals
    nInt    = floor(nScaled / nFactor)
    nFrac   = nScaled - (nInt * nFactor)

    if nDec = 0
        return cSign + string(nInt)
    ok

    cFrac = string(nFrac)
    while len(cFrac) < nDec
        cFrac = "0" + cFrac
    end

Return cSign + string(nInt) + "." + cFrac

//////////////////////////////////////////////
///////////////////////////////////////////////

/*  

             //--- NOTE: *** Yahoo will use Previous Date as Jan-01 ---------------
             // DAILY        Open        High        Low         Close       Adj Close   Volume
             // Jan 7, 2026  1,227.76    1,234.86    1,223.56    1,225.68    1,225.68    292,645
             // Jan 6, 2026  1,222.82    1,246.38    1,222.42    1,242.19    1,242.19    1,894,600
             // Jan 5, 2026  1,211.22    1,237.86    1,211.22    1,228.19    1,228.19    3,290,600
             // Jan 2, 2026  1,133.76    1,172.77    1,133.48    1,163.78    1,163.78    2,697,900
             //
             // MONTHLY      Open        High        Low         Close       Adj Close   Volume
             // Jan 7, 2026  1,227.76    1,234.86    1,223.56    1,225.96    1,225.96    304,235
             // Jan 1, 2026  1,133.76    1,246.38    1,133.48    1,242.19    1,242.19    7,883,100
             // Dec 1, 2025	1,056.03	1,141.72	1,010.01	1,069.86	1,069.86	26,277,900
	         //
             // Ex: ASML Jan-07 1226   <<< Current Date
             //          Jan-06 1242   <<< Monthly Jan-01 1242
             //          Jan-02 1163   <<< 




ACT.csv  Weekly History C\NetData\CSV\ACT.csv
2024-01-25,28.410000,28.480000,28.155001,28.309999,189051,28.309999 
2024-01-22,28.260000,28.540001,28.100000,28.270000,1590500,28.270000 
2024-01-15,28.100000,28.160000,27.410000,28.059999,891100,28.059999 
2024-01-08,28.480000,28.719999,27.990000,28.200001,2185700,28.200001 
2024-01-01,28.840000,28.889999,28.299999,28.430000,643300,28.430000 
2023-12-25,29.190001,29.430000,28.889999,28.889999,447100,28.889999 
2023-12-18,28.650000,29.490000,28.410000,29.170000,1641800,29.170000 
2023-12-11,27.540001,28.910000,27.400000,28.500000,1738000,28.500000 
2023-12-04,27.780001,28.107000,26.980000,27.540001,1116400,27.540001 
2023-11-27,27.719999,27.990000,27.530001,27.900000,889200,27.900000 

=================================
Yahoo History cStr <= JSON Data

$url = 'https://query1.finance.yahoo.com/v8/finance/chart/AAPL?metrics=high?&interval=1wk&range=1mo'

RAW cStr DATA

{"chart":{"result":[{"meta":{"currency":"USD","symbol":"AAPL","exchangeName":"NMS","fullExchangeName":"NasdaqGS","instrumentType":"EQUITY","firstTradeDate":345479400,"regularMarketTime":1726689602,"hasPrePostMarketData":true,"gmtoffset":-14400,"timezone":"EDT","exchangeTimezoneName":"America/New_York","regularMarketPrice":220.69,"fiftyTwoWeekHigh":222.7,"fiftyTwoWeekLow":217.54,"regularMarketDayHigh":222.7,"regularMarketDayLow":217.54,"regularMarketVolume":58797956,"longName":"Apple Inc.","shortName":"Apple Inc.","chartPreviousClose":216.79,"priceHint":2,"currentTradingPeriod":{"pre":{"timezone":"EDT","start":1726732800,"end":1726752600,"gmtoffset":-14400},"regular":{"timezone":"EDT","start":1726752600,"end":1726776000,"gmtoffset":-14400},"post":{"timezone":"EDT","start":1726776000,"end":1726790400,"gmtoffset":-14400}},"dataGranularity":"1wk","range":"5w","validRanges":["1d","5d","1mo","3mo","6mo","1y","2y","5y","10y","ytd","max"]},"timestamp":[1726459200,1726689602],"indicators":{"quote":[{"volume":[59788400,58797956],"open":[217.5500030517578,217.58999633789062],"low":[217.5399932861328,217.5399932861328],"high":[222.7100067138672,222.6999969482422],"close":[220.69000244140625,220.69000244140625]}],"adjclose":[{"adjclose":[220.69000244140625,220.69000244140625]}]}}],"error":null}}
 
//============================ 
FORMATED Data in WebPage 
 
{
    "chart": {
        "result": [
            {
                "meta": {
                    "currency": "USD",
                    "symbol": "AAPL",
                    "exchangeName": "NMS",
                    "fullExchangeName": "NasdaqGS",
                    "instrumentType": "EQUITY",
                    "firstTradeDate": 345479400,
                    "regularMarketTime": 1726776001,
                    "hasPrePostMarketData": true,
                    "gmtoffset": -14400,
                    "timezone": "EDT",
                    "exchangeTimezoneName": "America/New_York",
                    "regularMarketPrice": 228.87,
                    "fiftyTwoWeekHigh": 229.82,
                    "fiftyTwoWeekLow": 224.64,
                    "regularMarketDayHigh": 229.82,
                    "regularMarketDayLow": 224.64,
                    "regularMarketVolume": 66307649,
                    "longName": "Apple Inc.",
                    "shortName": "Apple Inc.",
                    "chartPreviousClose": 225.89,
                    "priceHint": 2,
                    "currentTradingPeriod": {
                        "pre": {
                            "timezone": "EDT",
                            "start": 1726732800,
                            "end": 1726752600,
                            "gmtoffset": -14400
                        },
                        "regular": {
                            "timezone": "EDT",
                            "start": 1726752600,
                            "end": 1726776000,
                            "gmtoffset": -14400
                        },
                        "post": {
                            "timezone": "EDT",
                            "start": 1726776000,
                            "end": 1726790400,
                            "gmtoffset": -14400
                        }
                    },
                    "dataGranularity": "1wk",
                    "range": "1mo",
                    "validRanges": [
                        "1d",
                        "5d",
                        "1mo",
                        "3mo",
                        "6mo",
                        "1y",
                        "2y",
                        "5y",
                        "10y",
                        "ytd",
                        "max"
                    ]
                },
                "timestamp": [
                    1724040000,
                    1724644800,
                    1725249600,
                    1725854400,
                    1726459200,
                    1726776001
                ],
                "indicators": {
                    "quote": [
                        {
                            "low": [
                                223.0399932861328,
                                223.88999938964844,
                                217.47999572753906,
                                216.7100067138672,
                                213.9199981689453,
                                224.63999938964844
                            ],
                            "open": [
                                225.72000122070312,
                                226.75999450683594,
                                228.5500030517578,
                                220.82000732421875,
                                216.5399932861328,
                                225.13999938964844
                            ],
                            "close": [
                                226.83999633789062,
                                229,
                                220.82000732421875,
                                222.5,
                                220.69000244140625,
                                228.8699951171875
                            ],
                            "high": [
                                228.33999633789062,
                                232.9199981689453,
                                229,
                                224.0399932861328,
                                222.7100067138672,
                                229.82000732421875
                            ],
                            "volume": [
                                188124900,
                                209486100,
                                179069200,
                                237622900,
                                164771600,
                                66307649
                            ]
                        }
                    ],
                    "adjclose": [
                        {
                            "adjclose": [
                                226.83999633789062,
                                229,
                                220.82000732421875,
                                222.5,
                                220.69000244140625,
                                228.8699951171875
                            ]
                        }
                    ]
                }
            }
        ],
        "error": null
    }
}

*/
