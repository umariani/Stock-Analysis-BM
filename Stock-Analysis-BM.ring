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

load "Stock-DrawChart.ring"
load "Stock-YearlyReturns.ring"
# --------------------------

aTimeStamp = []
aAdClose   = [] 
   
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
comboTopTen   = null  // <<<<<
comboRangeMth = null  // <<<<<
comboDebugSet = null  // <<<<<
btnRun        = null
btnExport     = null
btnBrowse     = null
txtTickerFile = null
App           = null

# ------------------------------

$RangeMth     = 7        // Performance EndCol - StartCol
$Top10        = 7        // Buy if Rank <= 10
DataLen       = 64       // Nbr of Months of Data

csvFile       = "AAA-Spread.csv"   // NEEDED

# --------------------------------

// There are 19 predefined QColor objects: 
// white, black, red, darkRed, green, darkGreen, blue, darkBlue, cyan, darkCyan, 
// magenta, darkMagenta, yellow, darkYellow, gray, darkGray, lightGray, color0 


# Constants for Styling
C_STYLE_DARK = "
    QWidget {
        background-color: #2b2b2b;
        color: #000000 ;             // #ffffff;
        font-family: 'Segoe UI', sans-serif;
        font-size: 14px;
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
		resize(1400, 800)
		setStyleSheet(C_STYLE_DARK)

		# --- Layouts ---
		mainLayout     = new QVBoxLayout()
		controlsLayout = new QHBoxLayout()
		contentLayout  = new QHBoxLayout()

		# --- Controls Section ---
		groupControls = new QFrame( win,0) {
			setFrameShape(QFrame_StyledPanel)
			
			# Main layout for the frame (Vertical to hold Title + Controls)
			frameLayout = new QVBoxLayout() {
				
				# Title
				lblTitle = new QLabel( win) {
					setText("Configuration")
					setStyleSheet("color: #007acc; font-weight: bold;")
				}
				addWidget(lblTitle)

				# Controls Layout (Horizontal)
				controlsLayoutInner = new QHBoxLayout() {
					
					# Interval
					addWidget(new QLabel(win){setText("Interval:")})
					comboInterval = new QComboBox(win){
						alist = ["1mo", "1wk", "1d"]
						for x in aList additem(x,0) next
						}
					addWidget(comboInterval)
				
					# Range
					addWidget(new QLabel(win){setText("Range:")})
					comboRange = new QComboBox(win){
							alist = ["5y", "1y", "2y", "10y"]
						for x in aList additem(x,0) next
						}
					addWidget(comboRange)	

					# TopTen
					addWidget(new QLabel(win){setText("TopTen:")})
					comboTopTen = new QComboBox(win){
							alist = ["7", "5", "10", "15"]
						for x in aList additem(x,0) next
						}
					addWidget(comboTopTen)		

					# Range-Months
					addWidget(new QLabel(win){setText("RangeMth:")})
					comboRangeMth = new QComboBox(win){
							alist = ["7", "6", "8", "9","10","11","12"]
						for x in aList additem(x,0) next
						}
					addWidget(comboRangeMth)
											
					
					# Debug Selections
					addWidget(new QLabel(win){setText("Debug:")})
					comboDebugSet = new QComboBox(win){
							alist = ["DebugToggle", "Array-Data", "Performance", "Sort", "Sort-Name","Rank","Buy-Price","Gain",
							         "Monthly-Perf","Compound","Summary-Stock","Summary-Total","Show-Top10","Gain-Details"]
						for x in aList additem(x,0) next
						}
					addWidget(comboDebugSet)					
					
					

					# Ticker File
					addWidget(new QLabel(win){setText("Ticker File:")})
					txtTickerFile = new QLineEdit(win){setText("quotes.ini")}
					addWidget(txtTickerFile)
					
					btnBrowse = new QPushButton(win){setText("Browse...")}
					btnBrowse.setStyleSheet("background-color: yellow;")
					btnBrowse.setClickEvent("browseFile(this)")
					addWidget(btnBrowse)

					# Run Quotes Button
					btnQuotes = new QPushButton(win){setText("Get Quotes")}
					btnQuotes.setStyleSheet("background-color: cyan;")
					btnQuotes.setClickEvent("GetQuotes()")
					addWidget(btnQuotes)

					# Run Button
					btnRun = new QPushButton(win){setText("Run Analysis")}
					btnRun.setStyleSheet("background-color: cyan;")
					btnRun.setClickEvent("YearlyReturns()")
					addWidget(btnRun)

					// # Export Button
					// btnExport = new QPushButton(win){setText("Export CSV")}
					// btnExport.setStyleSheet("background-color: orange;")
					// btnExport.setClickEvent("exportCSV()")
					// btnExport.setEnabled(false)
					// addWidget(btnExport)
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
					setStyleSheet("color: #007acc; font-weight: bold;")
				}
				addWidget(lblTitle)

				txtLog = new QTextEdit(win){setReadOnly(true)setText("Ready to start...")}
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
					setStyleSheet("color: #007acc; font-weight: bold;")
					setMaximumHeight(40)
				}
				addWidget(lblTitle)

				oChartWidget = new StockChart( win)
				addWidget(oChartWidget)
			}
			setLayout(frameLayout)
		}

		# Add widgets to layouts
		controlsLayout.addWidget(groupControls)
		
		contentLayout.addWidget(groupData)
		contentLayout.addWidget(groupChart)
		contentLayout.setStretch(0, 1) # Log takes 1 part
		contentLayout.setStretch(1, 2) # Chart takes 2 parts

		mainLayout.addLayout(controlsLayout)
		mainLayout.addLayout(contentLayout)

		setLayout(mainLayout)
		show()
	}

    App.exec()
 
    exec()

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
// Note: Ticker is "AAPL" in this $url
// $url = 'https://query1.finance.yahoo.com/v8/finance/chart/AAPL?metrics=high?&interval=1wk&range=1mo'
//-----------------------------------------------------------------

Func GetQuotes()

ExtractYear = 0         // 1=Year  0=Month

WhoCalled = 'Ring'      // Ring 2 sysArgs  .Exe 6 sysArgs
$Symbol   = 'BMO'       // <<< Symbol    $url2 
$Interval = '1mo'       // <<< Interval  $url4                            
$Range    = '5y'        // '10y'  // <<< Range     $url6   "1y","2y","5y","10y" 


    cInterval   = comboInterval.currentText()
    cRange      = comboRange.currentText()
	cTopTen     = comboTopTen.currentText()
	cRangeMth   = comboRangeMth.currentText()
    cFile       = txtTickerFile.text()
	cInFileName = txtTickerFile.text() 
	
	
$Interval =    cInterval	// Curl GetQuotes
$Range    =    cRange	    // Curl GetQuores
$Top10    = 0+ cTopTen      // YearlyReturns
$RangeMth = 0+ cRangeMth    // YearlyReturns  "$RangeMth" is Month Range | NOT $Range for Curl


See "GetQuotes: $Interval: "+ $Interval +" $Range: "+ $Range +" $Top10: "+ $Top10 +" RangeMth: "+ $RangeMth +" Quotes: "+ cInFileName +nl 


//------------------------------------------------------------

$csvSpread   =  "AAA-Spread.csv"        # Directory + SpreadSheet New to OLD reversed
fpSpread     =  fopen($csvSpread,"w")   # Write to SpreadSheet CSV file

  DirName      =    CurrentDir()
//cInFileName  =    cFile              // Already extracted
  cOutFileName = "./Quotes.result"
  $csvDir      =   ""


//------------------------------------------------------------


$url1 = 'https://query1.finance.yahoo.com/v8/finance/chart/'
$url2 =  $Symbol                          // <<< Ticker 'RY'
$url3 = '?metrics=high?&interval='
$url4 =  $Interval                        // <<< Interval   1wk'                           
$url5 = '&range='
$url6 =  $Range                           // <<< Range '10y'

$URL  = $url1 + $url2 + $url3 + $url4 + $url5 + $url6

aSymbols  = []  // Extract .ini => array of symbols

//=================================================================

//==================================================================
//==================================================================

###------------------------------------------------
### HISTORY.ini --- Get symbol from Quote.ini each line in file

fpIn = fopen(cInFileName,"r")             //  Yahoo    BigCharts   DividendChannel   
    while not feof(fpIn)                  //  BMO.TO   CA:BMO      BMO.CA
        line   = Readline(fpIn)           //  CTC-A.TO CA:CTC.A    CTC.A.CA
        if line != ''                     //  ACO-X.TO CA:ACO.X    ACO.X.CA
            aParts = split(line," ")      //  HR-UN.TO CA:HR.UT    HR.UN.CA
            $Symbol = aParts[1]           
            
            Add(aSymbols, $Symbol)   
        ok
    end


    //========================================================================
    // CURL INIT  fix 2025-Mar-01
    //--- // START CURL INIT   ---
	
    curl = curl_easy_init()                      
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U;") 

count = 1   
foreach $Symbol in aSymbols

    //-----------------------------------------------
    // Convert to Yahoo ^ and =X  Format
    
    if $Symbol = "TNX"    $Symbol=  "^" + $Symbol   ok  
    if $Symbol = "VIX"    $Symbol=  "^" + $Symbol   ok 
    if $Symbol = "CADUSD" $Symbol=  $Symbol + "=X"  ok
    if $Symbol = "USDCAD" $Symbol=  $Symbol + "=X"  ok
       

    //See ""+count +" Working on: "+ $Symbol +tab +tab
    $url2 = $Symbol                          // <<< Ticker
    $url4 = $Interval                        // <<< Interval                             
    $url6 = $Range                           // <<< Range

    //----------------------------------------------------
    // COMBOL URL 
 
    $URL = $url1 + $url2 + $url3 + $url4 + $url5 + $url6    
    
    //========================================================================
    // CURL GET DATA  $URL ===>>>
          
    curl_easy_setopt(curl, CURLOPT_URL, $url);   ### <<<=== SetOpt + URL               
    cStr = curl_easy_perform_silent(curl)        ### <<<=== GET DATA ===>>> cStr
 
    // See cSTR
    // See nl+"len(cStar): "+ len(cStr) +nl
    
    if ( len(cStr) = 0 )  
       See nl+"NO INTERNET CONNECTION: " +nl +"CONNECT TO INTERNET AND TRY AGAIN: " +nl
       See "Press Enter to Exit"+ nl
       keyChar = GetChar()     
       
       return 9
    ok  
    
    //===========================================================================

        
    See $Symbol +tab    
    aList = JSON2List( cStr )   

    if ( substr( cStr, 'No data found' ) )
        See $Symbol +tab +" Notfound: " +nl
        continue   // foreach $Symbol in aSymbols
    ok
 
 
    aAdjClose  =  aList[:chart][:result][1][:indicators][:adjclose][1][:adjclose]
    aTimeStamp =  aList[:chart][:result][1][:timestamp]

    if ( len(aTimeStamp) = 0 )
         See $Symbol +tab +" Len: "+ len(aTimeStamp) +nl
         continue
    ok   

    
    //---------------------------------------------------
    // Combine Format from Arrays
    // Yahoo  Rmove the ^ and =x
    
    if $Symbol = "^TNX"     $Symbol=  substr( $Symbol, "^",  "" )  ok  
    if $Symbol = "^VIX"     $Symbol=  substr( $Symbol, "^",  "" )  ok 
    if $Symbol = "CADUSD=x" $Symbol=  substr( $Symbol, "=X", "" )  ok
    if $Symbol = "USDCSD=x" $Symbol=  substr( $Symbol, "=X", "" )  ok
    
    
    ###--- One Line at a time | $NextLine put in reverse order -----
    cHistory = ""
	Spread   = ""
	Spread   = Spread + aAdjClose[1]     // SpreadSheet Line
    

	for k =  2 to len(aTimeStamp)          // 2 .. Old to New
         		
			###--- SpreadSheet Line for $Symbol
		    Spread = Spread +", " + aAdjClose[k]
						  			
    next
	
	//----------------------------------------------------------------------
	// Fill in Left by Repeating Old Data if Not equal to DataLen 121 or 11
	
	
	if $Symbol = "QQQ"  // FIRST in QUOTES.INI  SPY
	    DataLen = len(aTimeStamp) +1
		See nl+"DataLen QQQ: "+ DataLen +nl
	ok
	
	addSize = DataLen - len(aTimeStamp)  // 121 - 80 =   41 to add
	if len(aTimeStamp) < DataLen
	
        //See nl+"Len aTimeStamp: "+ len(aTimeStamp) +" addSize: "+ addSize +nl
        //See "adjClose[1]: "+ aAdjClose[1] +" <<<<< "+nl
	
	    for i = 1 to addSize +1
	        Spread = string(aAdjClose[1]) +", "+ Spread   // Insert on Left
			
	    next
	ok
	
	//---------------------
	
	Spread = $Symbol +", "+ Spread    // ADD Symbol
	Spread = Spread +nl               // Show final quotes for this $Symbol
	
	
    //See ">>> "+ Spread
	
	Fputs(fpSpread, Spread)
    
    //---------------------------------------------------

    See "Finished history: "+count +" "+ $Symbol +nl
	
	    txtLog.append("Finished history: "+ count +" "+ $Symbol )
        App.processEvents() # Keep UI responsive
  
    //--------------------------------------------------  
  
    count++
    
 next                      // foreach $Symbol in aSymbols
 
    //---------------------
    // SpreadSheet Close:  If EXCEL is Open: Line 343 Error in parameter, NULL pointer!
 
    fclose(fpSpread)          
 
 //--------------------
 
 
    //======================================= 
    //======================================    

    See "Finished: History."+ nl
    
    t1 = clock()
    Sleep(1)
    t3 = clock()
	
    See "Sleep finished.  Total Time: " + ( (t3-t1)/ClocksPerSecond() ) + " Sec" + nl
	
	See "CSV File Closed: "+  $csvSpread +nl+nl
	
		txtLog.append("Finished Quotes:  CSV File Closed: "+ $csvSpread )
        //App.processEvents() # Keep UI responsive
    
    // See "Press Enter to Exit"+ nl
    // keyChar = GetChar()
	
    return 
 
//============================================================= 
//=============================================================
// FUNCTIONS
// Convert Epoch Secs to Human Readable Date

Func EpochToDate(EpochSecs)

   NbrDays   = EpochSecs / 86400                    // 1726776001
   DateHuman = AddDays( "01/01/1970", NbrDays )
 return DateHuman                                   // 19/09/2024
 
 
//////////////////////////////////////////////
///////////////////////////////////////////////

/*  
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

////////////////////////
