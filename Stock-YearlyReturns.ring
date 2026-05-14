### NASD-100 Monthly 121 Data
### Sort by Yearly 12 Month Performance
### Moving 1 Month at a Time
### Buy Top 10
### 101 lines X 121 columns 
### Col-1 = Symbol  Row-1 Label#
###  List2CSV(aList)      --> cCSVString
###  CSV2List(cCSVString) --> aList


// load "stdlibcore.ring"
// load "csvlib.ring"
// load "guilib.ring"

# =========================================


//$RangeMth = 7        // Performance EndCol - StartCol
//$Top10    = 7        // Short-10.csv  Long = 10     // Buy if Rank <= 10
//csvFile   = "AAA-Spread.csv"   // NEEDED

a2DTest  = ["",""]

tList    = [""]   // tList with Symbol in Col-1
aList    = [""]   // CSV List
pList    = [""]   // Performance
sList    = [""]   // Sort  Performance
nList    = [""]   // Sort  Name-Position after Sorted
rList    = [""]   // GenerateRank  Rank 1-10 ... 100
bList    = [""]   // Buy Price
gList    = [""]   // Gain %percent 
mList    = [""]   // Montly gain 
cList    = [""]   // Compoud Gain 
hList    = [""]   // History Ret 

aSumTotal = ["","",""]   // Nbr 1-120,  QQQ, TOT 

aDateRead = []      // aTimpStamp to Human Readable 

# ------------------------------------

DebugTlist = 0    //  temp Debug =1
DebugAlist = 0    //  array Data 
DebugPlist = 0    //  performance   
DebugSlist = 0    //  sort 
DebugNlist = 0    //  sort-name 
DebugRlist = 0    //  rank  
DebugBlist = 0    //  buy price 
DebugGlist = 0    //  gain  
DebugMlist = 0    //  montly performance 
DebugClist = 0    //  compound 


DebugSClist = 0    // Summary Stock compounded        Compount for Row-last  mList
DebugTClist = 0    // Summart Total compounded vs QQQ Compound Gain Percent  cList

DebugS10List = 1   // Show $Top10 Current
DebugGDList  = 0   // Printout Buys Sell Gain
DebugHRList  = 0   // History returm


// ================================================
// ================================================
// START HERE
  
Func YearlyReturns()


    StockCount    = 1   // Restore so Stk-Next starts at 1 again
	
    // --- TOGGLE Debug the Array Outputs - TOGGLE Settings 0-> 1 or 1->0 ---

    DebugValue = comboDebugSet.currentText()
	if DebugValue = "Array-Data"      if DebugAlist   = 1   DebugAlist   = 0  else  DebugAlist   = 1 ok  ok
	if DebugValue = "Performance"     if DebugPlist   = 1   DebugPlist   = 0  else  DebugPlist   = 1 ok  ok
	if DebugValue = "Sort"            if DebugSlist   = 1   DebugSlist   = 0  else  DebugSlist   = 1 ok  ok
	if DebugValue = "Sort-Name"       if DebugNlist   = 1   DebugNlist   = 0  else  DebugNlist   = 1 ok  ok
	if DebugValue = "Rank"            if DebugRlist   = 1   DebugRlist   = 0  else  DebugRlist   = 1 ok  ok
	if DebugValue = "Buy-Price"       if DebugBlist   = 1   DebugBlist   = 0  else  DebugBlist   = 1 ok  ok
	if DebugValue = "Gain"            if DebugGlist   = 1   DebugGlist   = 0  else  DebugGlist   = 1 ok  ok
	if DebugValue = "Monthly-Perf"    if DebugMlist   = 1   DebugMlist   = 0  else  DebugMlist   = 1 ok  ok
	if DebugValue = "Compound"        if DebugClist   = 1   DebugClist   = 0  else  DebugClist   = 1 ok  ok
	if DebugValue = "Summary-Stock"   if DebugSClist  = 1   DebugSClist  = 0  else  DebugSClist  = 1 ok  ok
	if DebugValue = "Summary-Total"   if DebugTClist  = 1   DebugTClist  = 0  else  DebugTClist  = 1 ok  ok
	if DebugValue = "Show-Top10"      if DebugS10List = 1   DebugS10List = 0  else  DebugS10List = 1 ok  ok
	if DebugValue = "Gain-Details"    if DebugGDList  = 1   DebugGDList  = 0  else  DebugGDList  = 1 ok  ok
	if DebugValue = "HistoryRet"      if DebugHRList  = 1   DebugHRList  = 0  else  DebugHRList  = 1 ok  ok
	
	// See nl+"<===== DEBUG SETTING =====> "+nl
	// See "Array-Data   "+  DebugAlist   +nl
	// See "Performance  "+  DebugPlist   +nl
	// See "Sort         "+  DebugSlist   +nl     
	// See "Sort-Name    "+  DebugNlist   +nl
	// See "Rank         "+  DebugRlist   +nl     
	// See "Buy-Price    "+  DebugBlist   +nl
	// See "Gain         "+  DebugGlist   +nl     
	// See "Monthly-Perf "+  DebugMlist   +nl
	// See "Compound     "+  DebugClist   +nl 
	// See "Summary-Stock"+  DebugSClist  +nl
	// See "Summary-Total"+  DebugTClist  +nl
	// See "Show-Top10   "+  DebugS10List +nl
	// See "Gain-Details "+  DebugGDList  +nl
    // See "HistoryRet   "+  DebugHRList  +nl
	// See "<===== End Debug Setting =====> "+nl+nl
	

    //--- Reapeat from GetHistory
    cInterval   = comboInterval.currentText()
    cRange      = comboRange.currentText()
	cTopTen     = comboTopTen.currentText()
    cFile       = txtTickerFile.text()
	cInFileName = txtTickerFile.text()  // Picked File QuotesXXX.ini    
	cRangeMth   = comboRangeMth.currentText()
    
		
$Interval =    cInterval	// Curl GetQuotes
$Range    =    cRange	    // Curl GetQuores
$Top10    = 0+ cTopTen      // YearlyReturns
$RangeMth = 0+ cRangeMth    // YearlyReturns  "$RangeMth" is Month Range | NOT $Range for Curl	
	

See "$RangeMth: "+ $RangeMth +" $Top10: "+ $Top10 +" Quotes: "+ cInFileName  +nl
See "cInterval: "+ cInterval +" cRange: "+ cRange  +" cFile: "+ cFile +nl

//--- NOW READY TO GO ---------------------------

// for $RangeMth = 6 to 9
//    for $Top10 =  6 to 10 

        ReadCSVFile()       // aList = csvfile
        CreateLists()       // tList with Symbol
        CalcPerformance()   // pList
        SortPerformance()   // sList => nList Name
        GenerateRank()      // rList
        BuyRank()           // bList = Price in nCol if Rank <= $Top10 
        CalcGain()          // gList = Gain = Buy at nCol See at nCol +1 
        MonthlyGain()       // mList = Avg Gain for each nCol 
        Compounding()       // cList = Compoud gains by Periods 
        SummaryStock()      // Stock Compunded
        SummaryTotal()      // Total $Top10 Compounded vs QQQ
        ShowTop10()         // Show last $Top10 Symbols
		
		// aSumTotal: Row-1 =Nbr |  Row-2 =QQQ | Row-3 =Tot |
		
		
		Del(aSumTotal[1], len(aSumTotal[1]) )    // Remove last price 0 ?
		Del(aSumTotal[1],1)                      // Remove 1st Numbers 1..60

		Del(aSumTotal[2], len(aSumTotal[2]) )    // Remove last price 0 ?
		Del(aSumTotal[2],1)                      // Remove Name:  QQQ 1..60

 		Del(aSumTotal[3], len(aSumTotal[3]) )    // Remove last price 0 ?
		Del(aSumTotal[3],1)		                 // Remove Name:  TOT or performance 1..60
		Del(aSumTotal[3], len(aSumTotal[3]) )    // Shift right 1 to align with QQQ  and TOTon Chart
		
		oChartWidget.setData(aSumTotal)  // Use Azzeddine Chart

  
        // DrawChartQT(aSumTotal)        // Use QT Chart 
	
	//---------------------------------
	
       
//     next
//   See "<==========>"+nl
// next
 

// =================================================
// =================================================
// Use aList for CSV read in

Func ReadCSVFile()

    cFile = Read(csvFile)
    aList = CSV2List( Read(csvfile) )     // Create 2D array
	
	DataLength = len(aList[1])            // Cols
	See "DataLength: "+ DataLength +nl
	
	for i = 1 to len(alist)               // Rows
	    if len(aList[i]) < DataLength
		
		    HowMuch = DataLength - len(aList[i])
		    for h = 1 to HowMuch
		       Insert( aList[i], 2, aList[i][2] )   // Fill LEFT List Index Value ..Col		   
		       //See "Insert: "+ h +" "+ aList[i][1] +" "+ aList[i][2] +" "+  aList[i][3] +" "+  aList[i][5]  +nl
			next   
	    ok
	next
 
if DebugAList = 1 
    See nl+"<----- Debug CSV to aList 2D Display ----->"+nl
    DebugArray(aList)
ok  
    
    
Return

// =================================== 
// Create Lists based on aList size
// Add Symbols to Col-1
// QQQ     103.86 

Func CreateLists()

    tList = List( len(aList), len(aList[1]) )
    for i = 1 to len(aList)
        tList[i][1] = aList[i][1]                 // Symbol 
    next

if DebugTList = 1   
    See nl+"<----- Debug tList ----->"+nl
    DebugArray(tList)
ok  
    
        
Return

// =================================== 
// =================================== 

Func DebugArray(arrayList)

    nRow = 0  
	nCol = 0  
    nRow = len(arrayList)  

    if ! islist(arraylist[1])                  // 2D has nCol
        See "1D: "+ nRow +"x"+ nCol +nl  
            for i = 1 to nRow                  // 1D has No Col
                See ""+ arrayList[i] +" "  
            next
        Return  
    ok
       
    nCol = len(arraylist[1])  
    See "2D: "+ nRow +"x"+ nCol +nl  
    for subList in arrayList
       for i = 1 to len(subList)
           See ""+ subList[i] +" "  
       next
       See nl
    next  
Return 

// =================================
// ================================================
// Global: $RangeMth = 12  Use pList
// MMC 207.13	211.16	null	null	null


Func CalcPerformance()

    pList = tList  // Performance
    
    k = 1
    for Row in aList                              // Row array data 

	
###	See "Row[1] "+ Row[1] +nl
	    if subStr( Row[1], "Date" )
	        See "CalcPerf Row[1]: " + Row[1] +nl
		
	    else

        for i = $RangeMth +2 to len(Row)
            
                if Row[i -$RangeMth] = 0
                   Row[i -$RangeMth] = 1
                   See "aList: k: "+ k +" i: "+ i +nl
                ok
				
			//------------------------------------------
			// FIX " null" in price detected from Yahoo
			
			if Row[i] = " null" OR  Row[i -$RangeMth] = " null"
			    Perf = 1
				//See "Row[i]: "+ i +" "+ Row[1] +" BAD Data: |"+ Row[i] +"|"+ nl
		    else
			
                Perf        = Row[i] / Row[i -$RangeMth]  // EndCol div StartC 			
                pList[k][i] = (Perf)                      // *** test result
            
                //See "Row: "+ Row[1] +" "+i +" End: "+ Row[i] +" Srt: "+ Row[i -$RangeMth] +" Perf: "+ Perf +nl 
			ok	

        next
        k++
        ok		

    next
    
See nl  

if DebugpList = 1
    See nl+"<----- Debug Performance pList: $RangeMth: "+ $RangeMth +" ----->"+nl
    DebugArray(pList)
ok  
 
Return

// ===============================================
// sList --- Sort(pList, nColumn, cAttribute)

Func SortPerformance()

    nList  = tList   // Name List sorted by Rank
    
    for nCol = $RangeMth +2 to len(pList[1])     // Performance List
        sList = Reverse( Sort(pList, nCol) )     // High to Low Sort List
        
        
            //--- Debug aList 2D Display ------
            //See "<=====> nCol: "+ nCol +nl

            k = 1                                // k nList Row 
            nList[k][1] = aList[k][1]
            
            for subList in sList
                //See ""+ subList[1] +tab+ subList[nCol] +"   "  
                nList[k][1]    = aList[k][1]                  // Name in Col-1
                nList[k][nCol] = subList[1]                   // Sorted Name in Rest of Cols
                
                //See "nList: k: "+ k +" nCol: "+ nCol +" "+ nList[k][nCol] +nl
                k++
            next
            
    next

if DebugnList = 1    
    See nl+"<----- Debug Name nList ----->"+nl
    DebugArray(nList)
ok

Return

// ================================================
// Fill in Rank 1..10.. .. 100 based on nList position of Symbol
// Find(List,ItemValue,nColumn,cAttribute) ---> Item Index

Func GenerateRank()

    rList  = tList  // Rank List
  
    k = 1
    for Row in rList
        for nCol = 2 to len(Row)

            itemName = rList[k][1]
            pos = Find( nList, itemName, nCol)
     
            rList[k][nCol] = pos       // Rank number
            
        next
        k++
    next
    
if DebugrList = 1   
    See nl+"<----- Debug Rank rList  ----->"+nl
    DebugArray(rList)
ok   
    
Return

// ================================================
// Buy stock in rList  if Rank  <= $Top10

Func BuyRank()

    bList = tList    // Buy List with Price
  
    Vert = len(bList)     // Row
    Horz = len(bList[1])  // Col
    
    //--- Do by Col in each Row -------
    for nCol = $RangeMth +2 to Horz
    
        //See nl+"<----- nCol "+ nCol +" ----->"+nl
        for nRow = 1 to Vert 
        

            Rank = rList[nRow][nCol] 
            if  Rank <= $Top10                  // <= 10
              
                BuyStock = rList[nRow][1]     // Col-1 = Name
                BuyPrice = aList[nRow][nCol]
                BuyWeek  = nCol
                
                bList[nRow][nCol] = BuyPrice
              
                //See "Buy: "+ BuyStock +tab+ BuyPrice +tab+ nCol +nl             
            ok
        
        next
    next


if DebugbList = 1   
    See nl+"<----- Debug BuyPrice bList  ----->"+nl
    DebugArray(bList)   
ok  

Return

// ================================================
// Gain = bList -- Buy at nCol See at nCol +1
 
Func CalcGain()

    gList = tList    // Gain List %gain

    Vert = len(gList)     // Row gList Gains
    Horz = len(gList[1])  // Col gList Gains
    
    //--- Do by Col in each Row -------
    for nCol = $RangeMth +2 to Horz -1         // Stop short Horz -1
    
        //See nl+"<----- nCol "+ nCol +" ----->"+nl
        for nRow = 1 to Vert 
        

            if  bList[nRow][nCol] > 0        // Has a Buy Price
       
               //See "Debug: Sym: "+ bList[nRow][1] +" nRow: "+ nRow +" nCol: "+ nCol +nl 
      
                stock     = bList[nRow][1]
                buyPrice  = bList[nRow][nCol]
                sellPrice = aList[nRow][nCol+1]
                Gain      = sellPrice / buyPrice
                
                gList[nRow][nCol] = gain
              
			    //--- Gain Details Printout --
				if DebugGDList  = 1
                    See "Gain: "+ Stock +tab+ nRow +tab+ nCol +tab+ buyPrice +tab+ sellPrice +tab+ Gain  +nl  
				ok	
            ok
        
        next
    next    

if DebugGList = 1   
    See nl+"<----- Debug Gain Percent gList  ----->"+nl
    DebugArray(gList)   
ok  
 
 
// ================================================ 
// Avg Gain for each nCol -- mList from gList
// mList 1 Row and 1 Col Bigger for Summation

Func MonthlyGain() 
 
    //--- Bigger by 1 Summation Add Symbol-----
    mList = List( len(aList) +1, len(aList[1] +1) )    
    
    k = 1
    for Row in aList
        mList[k][1] = aList[k][1]     // Copy Symbols
        k++
    next
        mList[k][1] = "TOT"           // ADD tp Last Row
    
    //--- Compound Calc same size as Monthly Gain ------
    
    cList = mList

    //==============================    

    Vert = len(gList)     // Row GAINS gList = 6
    Horz = len(gList[1])  // Col GAINS gList = 11
    
   //--- Do SUM Col in each Row -------
   for nCol = $RangeMth +2 to Horz          
   
       //See nl+"<----- nCol "+ nCol +" ----->"+nl
       sumCol = 0
       for nRow = 1 to Vert 
              sumCol += gList[nRow][nCol]  
       next
           
       mList[nRow][nCol] = sumCol / $Top10  
   next    
    

    //--- Do by SUM Row in each col -------
    for nRow = 1 to Vert          
    
        //See nl+"<----- nRow "+ nRow +" ----->"+nl
        sumRow = 1       // Mutiply 
        countEntry = 0
        
        for nCol = $RangeMth +2 to Horz 
            if gList[nRow][nCol] != 0           
                sumRow *= gList[nRow][nCol]  // MULTIPLY Compound on Row for this Stock
                countEntry++
                
            ok              
        next
            if countEntry = 0  countEntry = 1  ok
            if sumRow = 1      sumRow = 0      ok
            mList[nRow][nCol] = sumRow            
    next



    //-------------------------------------
    
    Vert = len(mList)     // Last Row 7
    Horz = len(mList[1])  // Last Col 12    

    nRow = Vert           
    nCol = Horz           
    
    //--------------------------------------
    
    //--- SUM Bottom Row -----
    RowTotal = 0
    for k = 2 to nCol                         // Skip $Symbol col-1
        RowTotal += mList[nRow][k] 
    next
    
    //--- SUM Last Col -----
    ColTotal = 0
    for k = 1 to nRow
        ColTotal += mList[k][nCol]  
    next

    //--------------------------------------    
    mList[nRow][nCol] = RowTotal   //  Total of Each Period
    
    //--------------------------------------

if DebugMList = 1   
    See nl+"<----- Debug Average Gain Percent COL, Compount for Row Stock  mList  ----->"+nl
    DebugArray(mList)
        
    See "Avg Stock: Row: "+ RowTotal +nl
    See "Sum Indiv: Col: "+ ColTotal +nl
ok  
    
    //--------------------------------------
       
Return

// ===============================================
// ================================================ 
// cList = Compoud gains by Periods by Col and Row
//         Col = Period All Stocks, Row = by One Stock

Func  Compounding()  

    // cList = mList from   MontlyGain()    
    //-----------------------------
    
    Vert = len(cList)     // Last Row 7
    Horz = len(cList[1])  // Last Col 12    

    nRow = Vert           
    nCol = Horz
    
    cList[nRow][1] ="TOT"
    
    //--------------------------------------
    
    //--- COMPOUND Bottom Row multiply -----
    CompoundRow = 1
    for k = $RangeMth +2 to nCol-1
    
        if mList[nRow][k] != 0
           CompoundRow   *= mList[nRow][k]   // MULTIPLy
           cList[nRow][k] = CompoundRow
        ok
    next
                
    
    //--- COMPOUND Last Col multiply -----
    CompoundCol = 1
    for k = 1 to nRow-1
    
        if mList[k][nCol] != 0
            CompoundCol    = mList[k][nCol]  // ADD PLUS stock already compounded
            cList[k][nCol] = CompoundCol
        ok          
    next    

    //---------------------------------
    
    cList[nRow][nCol] = CompoundRow          // TOT
        
    //--------------------------------------

if DebugCList = 1   
    See nl+"<----- Debug Compound Gain Percent cList  ----->"+nl
    DebugArray(cList)
ok  


    
    //--------------------------------------
    
    CompoundQQQ =   aList[1][nCol-2]  / aList[1][$RangeMth+2]
    
    See "RangeMth: "+ $RangeMth +" Top: "+ $Top10 +" QQQ " + CompoundQQQ +"  "+ CompoundRow +nl
            
    //--------------------------------------        
        
Return


// ================================================
// ================================================  
// Summary Stock compounded        Compount for Row-last  mList

Func SummaryStock()  

    //See "<===== Summary Stock Compounded =====>"+nl

    nRow = len(mList)         
    nCol = len(mList[1])   

    aSumStock = list(3, len(mList) )       // Col = nRow ex: 1 QQQ   6.29


    for k = 1 to nRow   
        //See ""+ k +" "+ mList[k][1] +tab+ mList[k][nCol] +nl

        aSumStock[1][k] = k                // Position
        aSumStock[2][k] = mList[k][1]      // Symbol
        aSumStock[3][k] = mList[k][nCol]   // Value-compound
        
    next

    if DebugSCList = 1   
        See nl+"<----- Debug Summary Stock - Compounded  ----->"+nl
        DebugArray(aSumStock)
    ok 

Return


// ================================================
// ================================================ 
// Show Last $Top10 for last 10 Periods nList


Func ShowTop10() 

    nRow = len(nList)        // 62
    nCol = len(nList[1])     // 122
	
	// $Top10 = Rows = 10
	// $Top10 = Cols = 10
	// nCol-9 to nCol
	
	$TopColWidth = 13                         // Cols in $Top10 RxC = 10x10
	$TopColStart = nCol - $TopColWidth +1
    
       
	//--- 2 More Rows for QQQ and SPY reference -------
    //See "$Top10 rows: "+ $Top10 +nl
	
    aShowTop10 = List($Top10, $TopColWidth)   // Rows x Cols MAKE LIST SIZE Row=NbrStocks  Col=Cells
    
	//--- COPY Last 10 entried from Name nList -------------
	//--- LAST Entry is Today, 2nd Last is Start of Month
	
    k =1 m =1                                // Small Array Cells
    for v = 1 to $Top10                      // k= Rows in Small Array Rows
        for h = $TopColStart to nCol         // m= Cols in Small Array Rows 
		
            aShowTop10[k][m] = nList[v][h]   // 
		
            m++
        next
        k++
        m =1   // Reset
    next
	
//See "$Top10: k:"+k +" m:"+m +" v:"+v +" h:"+h +nl	
//DebugArray(aShowTop10)
	

	
	//---------------------------------------------------------------
	// Buy Prices for Top10 in 2nd Last nCol = Prev Month
	// NOTE: If Symbol was Not Bought Prev Month -- Use aList Prices shows 0
	//       USE aList to get price no matter what
	// Use 2nd LAST  sCols=last	|| Except 01/mm/yyyy aTimeStamp
	 
	sRows = len(aShowTop10)
	sCols = len(aShowTop10[1])
	bRows = len(bList)
	bCols = len(bList[1])

	cRows = len(aClosedPrices)
	cCols = len(aClosedPrices[1])	
	
	alastDate = split(lastDate,"/")     // 15/03/2026 global
	See "aLastDate: "+ alastDate[3] +"-"+ alastDate[2] +"-"+ alastDate[1] +"  "+ Time() +nl

	See "Sym:      PreMOp:   CurMOp:   NowCl:    $ChgNow:   Pct%     Shares" +nl
	txtLog.append(" ")+tab+
	txtLog.append("Sym:" +tab+ "CurMOp:" +tab+ "NowCl:" +tab+ "ChgNow:" +tab+ "Pct%")
	
	AvgSum     = 1
	TotalValue = 0  // Shares * CurPrice
	AvgValue   = 1  // Avg Stock Value
	
	for s = 1 to sRows                          // Each Symbol
	
	    itemName =  aShowTop10[s][sCols-1]      // Use 2nd LAST  sCols=last	|| Except 01/mm/yyyy aTimeStamp
		
		if alastDate[1] = "01"
		   itemName =  aShowTop10[s][sCols-1]
		ok
		  
		
        posA     =  FIND( aList, itemName, 1)           // aList         Search Col-1
		posC     =  FIND( aClosedPrices, itemName, 1)   // aClosedPrices Search    
		
		if posA = 0 OR posC = 0
		   See "FIND(): "+ itemName +" NOT Found: PosA= "+ posA +" PosC= "+ posC  +nl
		   
		else
		    //---Chg since start of 01-Month -----------------------
            //--- Use Current AdjClose Price from aClosedPrices ----------
		   
		    ChgPr1    = aClosedPrices[posC][cCols] - aList[posA][bCols-1]    
		    ChgPct1   = aClosedPrices[posC][cCols] / aList[posA][bCols-1] * 100 -100
		    NowPrice  = aClosedPrices[posC][cCols]
		    NbrShares = ceil( $Dollars / aList[posA][bCols-1] )   // $10,000 investment
		   
		   	TotalValue += NbrShares * NowPrice 
            AvgValue    = TotalValue / sRows			
		    AvgSum     += ChgPct1 
			
		   
            See ""+ PadR( 7, itemName)             +" "    // itemName in bList BuyList
		    See ""+ PadL( 9, aList[posA][bCols-2]) +" "    // PrevMonth
			See ""+ PadL( 9, aList[posA][bCols-1]) +" "    // CurMonth
			See ""+ PadL( 9, NowPrice)             +" "    // Now Price				   				   
			See ""+ PadL( 9, ChgPr1)               +" "    // Change Price
			See ""+ PadL( 9, ChgPct1)              +" "    // Pct%		
			See "  ("+ PadL( 4,NbrShares) +")"     +nl     // Nbr Shares
					
			txtLog.append(itemName +tab+ aList[posA][bCols-1] +tab+ NowPrice +tab+ ChgPr1 +tab+ ChgPct1)
					
	    ok
	next
	
	See nl+"TotalValue: "+ TotalValue +" AvgValue: "+ AvgValue +" AvgPct: "+ (AvgSum / sRows) +nl
	
	AvgValue = AvgSum / sRows
	See nl+"Average Result: NbrStock: "+ sRows +" AvgValue:  "+ AvgValue +nl
	
	txtLog.append(" ")
	txtLog.append("AVG Pct:" +tab+ AvgValue)
	
	// -----------------------------------------
	// -----------------------------------------
	    itemName = "QQQ"
        pos      =  FIND( aList, itemName, 1)   // aList Search Col-1, Pos = Row Nbr 
		
		if pos = 0 
		   See "FIND(): "+ itemName +" NOT Found: "+ " Pos= "+ pos +nl
		   
		else
		   ChgPr1  = aList[pos][bCols] - aList[pos][bCols-1]        // Chg since start of 01-Month
		   ChgPct1 = aList[pos][bCols] / aList[pos][bCols-1] * 100 -100		   
		   
           See ""+ itemName +tab+ 
		           aList[pos][bCols-2] +tab+    // bList
				   aList[pos][bCols-1] +tab+ 
				   aList[pos][bCols]   +tab+ 
				   ChgPr1  +tab+ 
				   ChgPct1 +nl
				   
				   txtLog.append("QQQ Pct:" +tab+ ChgPct1)
	    ok

	// -----------------------------------------
	// -----------------------------------------
	
	    itemName = "SPY"
        pos      =  FIND( aList, itemName, 1)   // aList Search Col-1, Pos = Row Nbr 
		
		if pos = 0 
		   See "FIND(): "+ itemName +" NOT Found: "+ " Pos= "+ pos +nl
		   
		else
		   ChgPr1  = aList[pos][bCols] - aList[pos][bCols-1]        // Chg since start of 01-Month
		   ChgPct1 = aList[pos][bCols] / aList[pos][bCols-1] * 100 -100		   
		   
           See ""+ itemName +tab+ 
		           aList[pos][bCols-2] +tab+    // bList
				   aList[pos][bCols-1] +tab+ 
				   aList[pos][bCols]   +tab+ 
				   ChgPr1  +tab+ 
				   ChgPct1 +nl
				   
				   txtLog.append("SPY Pct:" +tab+ ChgPct1)
	    ok		

	//--------------------------------------
	
	
cellNbr  = len(aSumTotal[3]) -1         //  FIX -1
$maxQQQ  =     aSumTotal[2][cellNbr]
$maxTOT  =     aSumTotal[3][cellNbr]
$Ratio   = ($maxTot -1) / ($MaxQQQ -1)   // Multi-Bagger to Percent Ratio

	    // ---------------------------------
	    // EpochSecs  = aTimeStamp[len(aTimeStamp)]
	    // DateHuman  = EpochToDate(EpochSecs)
	    // aDateRead  = [""]

        //---------------------------------
		// Add Dates for Cols | 
		
		aDateRead = []
		
		if len(aTimeStamp) > 10
		
		    R = len(aTimeStamp)
		    for S = 1 to  sCols                               // 10 nbr col in aShowTop10	
		        EpochTime  = aTimeStamp[ R -sCols +S ]        // -10 +S ]      // 160 159 158 ...
		    	DateHuman  = EpochToDate(EpochTime)      // 19/07/2025
		    	
				dateDDMM   =  subStr(DateHuman, 1, 6)    // str,pos,count
				
                Add (aDateRead , dateDDMM)               // DateHuman)
		    next
		else
		    //------------------------------------------
		    // Fake the Dates, GetQuotes was Not Run

            //aDateRead = ["01/03/","01/04/","01/05/","01/06/","01/07/",
	        //             "01/08/","01/09/","01/10/","01/11/","01/12/","    Today"]		
		ok	

        //---------------


    if DebugS10List = 1   
        See nl+"<----- Show $Top10 Vertical: Old to New  ----->"+nl
		
	
	    //--- Dates 01/MM ----------------
		for d = 1 to len(aDateRead) - 1          
		    See ""+aDateRead[d] +"  "
		next
		See Date() +nl
		
	
	    //--- Nbrs 12 11 .. 2 1 ------------
		for d = len(aDateRead) - 1 to 1 step -1  
		    See ""+d +tab
		next
		See "Today" +nl		
		
		
		//-----------------------------------------
        // --- SYMBOLS -- DebugArray(aShowTop10) 
		
        for subList in aShowTop10          // Vert
            for i = 1 to len(subList)      // Horz
               See "" + subList[i] +tab    // DO NOT Call DebugArray(), Insert TAB
            next
            See nl
        next	
		
    ok
	
	//---------------------------
	// Months 01/MM Append
	
	txtLog.append(" " )
	txtLog.append("<===== TopTen >>> OLD >>> NEW Periods =====>" )
	
	    monthInfo = ""
		for d = (len(aDateRead) - 4) to (len(aDateRead) - 1)          // Dates 01/MM
		    monthInfo += aDateRead[d] +tab
		next
		    monthInfo += Date() 
	    txtLog.append(monthInfo)


    //------------------------------
	// Symbols matrix Append

    for v = 1 to $Top10 
	
        symInfo = ""
		for d = (len(aShowTop10[1]) - 4) to (len(aShowTop10[1]) - 0)         
		    symInfo += aShowTop10[v][d] +tab
		next
	    txtLog.append(symInfo)	

	next
	
	//-------------------------------

	txtLog.append(" " )	
	txtLog.append( "QQQ: "+ $maxQQQ +" TOT: "+ $maxTOT +" Ratio: "+ $Ratio )
	txtLog.append(">===== TopTen =====<" )	

	
	//=================================
	// Debug HISTORY MONTHLY RESULTS
	
    if DebugHRList  = 1	
		CalcMonthlyRet(aShowTop10)
	ok
	
	//---------------------------------

Return

//=================================================
// CALC RETURNS PER MONTH 
//
// TOP TEN - HORZ and VERT Tickers
// if DebugGDList  = 1   ===>>>      // History Buy Sell Percent Average


Func CalcMonthlyRet(aShowTop10)

    //See nl+nl+"History Tickers Buy Sell Profit:"+nl+nl

	
	nRow  = len(aShowTop10)                    // 10                   
	nCol  = len(aShowTop10[1])                 // 10		
	month = len(aList[1]) - nCol               // 64 -10 = 54  <<<===
     
	aPercent   = list(nRow,nCol)                    // Nbr of Cols
	sumPercent = 0
	
        for Horz = 1 to nCol -1 
		    See nl+"<----- Month " + month +" ----->"+nl
			
			SumPercent = 0.01           // all stocks this month, to find average
			DrawUp     = 0.01
			DrawDown   = 0.01
			
            for Vert = 1 to nRow  
			
		        Ticker =  aShowTop10[Vert][Horz]
						   
		        # ---------------------------------------------------
		        # Last 10 Months -- Get Prices for Start End Month - Gain and Percent
		   			       
		   		posRow   =  FIND( aList, Ticker, 1)        // Search Ticker -- Find Row with data prices
			  
			  
			    if posRow > 0            // Must be a Ticket and not a "0" for 7 out of 12 montds
		            PriceS   =  PadL(8, aList[posRow][month ] 	)   
		            PriceE   =  PadL(8, aList[posRow][month +1] )
				    Diff     =  PadL(8, PriceE - PriceS                 )
				    Percent  =  PadL(8, PriceE / PriceS * 100 -100      )
				    
                    SumPercent += Percent
				    if Percent > DrawUp    DrawUp   = Percent  ok
				    if Percent < DrawDown  Drawdown = Percent  ok
				    
				    //if DebugHList = 1			   
		                See ""+ Horz +"-"+ Vert +" "+ PadR(6,Ticker) +" "+ PriceS +" "+ PriceE +" " +" "+ Diff + Percent  +nl
				    //ok 
				     
				    aPercent[Vert][Horz] = Percent
				ok	
				
		    # --------------------------------
            next
			
			AvgPercent = SumPercent / nRow
			See "Month: "+ month +" AvgPct: "+ AvgPercent +" DrawUp: "+ DrawUp +" DrawDown: "+ DrawDown +nl
							
		    month++
            
        next

        See nl
        DebugArray(aPercent)     // 2D Matrix of Percent for Month for TopTen Stocks
		
		//-------------------------------------------
		// Multiple Months Return 2D: 10x13
		
		aSum    = List(nCol)        // <== Create Horz list for AvgPct for each Month
		aDrawUp = List(nCol)
		aDrawDn = List(nCol)
		
		for Horz = 1 to nCol
		    Sum    = 0.01
			DrawUp = 0.01
			DrawDn = 0.01
			
            for Vert = 1 to nRow
				Sum += aPercent[Vert][Horz]
				  if aPercent[Vert][Horz] > DrawUp  DrawUp = aPercent[Vert][Horz]  ok
				  if aPercent[Vert][Horz] < DrawDn  DrawDn = aPercent[Vert][Horz]  ok
            next
			
			AvgSum     = Sum / nRow
			
			aSum[Horz]    = AvgSum   // Horz list of Sum per Month
			aDrawUp[Horz] = DrawUp    
			aDrawDn[Horz] = DrawDn
		next
		
		See nl		
        //DebugArray(aSum)          // 1D of Avg Perecent by Month
		//DebugArray(aDrawUp)
		//DebugArray(aDrawDown)
		
		//------------------
		See "AvgPct: "
		for i = 1 to nCol
		   See PadR(9,aSum[i]) 
		next
		   See nl
		
		
		// See "DrawUp: "
		// for i = 1 to nCol
		//    See PadR(9,aDrawUp[i]) 
		// next
		//    See nl
		// 
		// See "DrawDn: "
		// for i = 1 to nCol
		//    See PadR(9,aDrawDn[i]) 
		// next		
		//    See nl
		//---------------
		
		TotalSum = 0.01
		for i = 1 to len(aSum)
		    TotalSum += aSum[i]		
		next
		See nl+"Total Sum.: "+ TotalSum +nl
		
		//--------------------------------		
		DrawUpMth = Max(aSum)
		DrawDnMth = Min(aSum)
		
		See "DrawUpMth.: "+ DrawUpMth +nl 
		See "DrawDnMth.: "+ DrawDnMth +nl
		
		//--------------------------------

		Compound = 1
		for i = 1 to nCol -1                      // Last Col = 0		
		    nbr = (aSum[i] + 100 ) / 100          // 10.79 => 110.79 => 1.1079						
		    Compound *= nbr	                     			
		next		
		Compound = (Compound -1 ) *100
		See "Final Cmp.: "+ Compound +nl
		
		//--------------------------------------
	    // Find SPY Results for same Time period	

        itemName = "SPY"
        pos      =  FIND( aList, itemName, 1)   // aList Search Col-1, Pos = Row Nbr 
		
        if pos = 0
            See "SPY pos Not Found"+ nl
        Ok
		
		
		lenSPY = len( aList[pos] )
		oldSPY = aList[pos][ lenSPY - nCol +1]       // 9 ]  nCols ago
		newSPY = aList[pos][ lenSPY ]
		chgSPY = newSpy - OldSPY
		perSPY = newSpy / OldSpy * 100 - 100
		

		See "..SPY Pct.: "+ perSpy  +nl //  +" Old: "+ oldSpy +" New: "+ newSPY +" Chg: "+ chgSPY  +nl
		
		
	    

Return

// ================================================
// ================================================  

// ================================================
// ================================================  
// Summary Total compounded vs QQQ Compound Gain Percent  cList

Func SummaryTotal   
  
    //See "<===== Summary Total Compounded =====>"+nl

    nRow = len(cList)                            // cList = Compound
    nCol = len(cList[1])    
    
    aSumTotal       = list(3, len(cList[1]) )    // CREATE List 3 x NbrStocks -- Nbr::QQQ::TOT each period
    aSumTotal[1][1] = 1                           
    aSumTotal[2][1] = "QQQ"
    aSumTotal[3][1] = "TOT"
        

    //--- TOT Compounded from cList[nRow][k] -----

    TCmp = 1
    QInit = aList[1][$RangeMth +2]                   // QQQ  row 1
	
    //See "QInit: "+ QInit +nl

    for k = $RangeMth+ 2 to nCol -1    // FIX  -1 
        QChg = aList[1][k] / QInit               // QQQ  row 1      
        TCmp = cList[nRow][k]                    // TOT  row last
                
        //See ""+ k +" TOT: "+ TCmp  +"  QQQ: "+ QChg  +nl

        aSumTotal[1][k] = k                // Position
        aSumTotal[2][k] = QChg             // QQQ   cmp
        aSumTotal[3][k] = TCmp             // Total cmp
    
    next
        aSumTotal[3][nCol-1] = aSumTotal[3][nCol-2] // Force last entry to match QQQ

    if DebugTCList = 1   
        See nl+"<----- Debug Total - Compounded  ----->"+nl
        DebugArray(aSumTotal)
    ok 

Return


// ================================================
// PADL() = Pad Left -- Add spaces on Left Side

Func PadL( padn, item )         

    padn     = 0+  Padn        // to number
    item     = ""+ item        // to string   
    lenItem  = len(item)          
    fillNbr  = padn - lenItem       
    if fillNbr <= 0 
       See nl+"Err: PadL Nbr <=0: "+ fillnbr +nl
	   return item
    ok
  
    newItem  = Space(fillNbr) + item

Return newItem


// ================================================
// PADR() = Pad Right -- Add spaces on Right Side

Func PadR( padn, item )         

    padn     = 0+  Padn         // to number
    item     = ""+ item         // to string   
    lenItem  = len(item)          
    fillNbr  = padn - lenItem    
	
    if fillNbr <= 0 
       See nl+"Err PadR Nbr <=0: "+ fillnbr +nl
	   return item
    ok
  
    newItem  = item + Space(fillNbr) 

Return newItem

// ================================================


// ================================================
// ================================================
// ================================================
//
// DrawChartQT()
//    aSumTotal[1][1] = 1                           
//    aSumTotal[2][1] = "QQQ"
//    aSumTotal[3][1] = "TOT"
//
# 2. Generate QML file content dynamically
# -------------------------------------------------
		
Func DrawChartQT(aSumTotal)		

cellNbr  = len(aSumTotal[3]) -1
$maxQQQ  =     aSumTotal[2][cellNbr]
$maxTOT  =    (aSumTotal[3][cellNbr]) * 1.50  // Vertical Bigger by 10%
$realTot = ($maxTOT * 10 / 15.0 )
$nameTot = "TOT:"+ $realTot 

$Ratio   = ($realTot -1)  / ($MaxQQQ -1)   // Multi-Bagger to Percent Ratio

See nl+"QQQ: "+ $maxQQQ +"  TOT: "+ $realTot +" Ratio: "+ $Ratio +nl		
		
cQMLContent = '
    import QtQuick 2.0
    import QtCharts 2.0

ChartView {
    id: chart
    width:               900
    height:              700
    theme:               ChartView.ChartThemeLight
    antialiasing:        true
    backgroundColor:    "white"
    title:              "Performance Comparison: Index (QQQ) vs Portfolio (TOT)"
    titleFont.pixelSize: 22
    titleFont.bold:      true
    legend.alignment:    Qt.AlignBottom
    
        // X-axis (Days) ------------------			
        ValueAxis {
        id:                   axisX
        min:                  0
        max:                  ' + (len(aSumTotal[2]) - 1) + ' 
        titleText:           "Months"
        titleFont.pixelSize:  14
        labelsFont.pixelSize: 12
        gridVisible:          true
        minorGridVisible:     true
        color:               "#333333"
        }

        // Y-axis (Cumulative Return %) ----------------
        ValueAxis {
        id:                   axisY
        min:                  0                     
        max:                  ' + $maxTOT + '      
        titleText:           "Cumulative Return (%)"
        titleFont.pixelSize:  14
        labelsFont.pixelSize: 12
        gridVisible:          true
        minorGridVisible:     true
        color:               "#333333"
        }

        // First series: QQQ (Blue) ---------------
        LineSeries {
        name:  "QQQ"
        axisX:  axisX
        axisY:  axisY
        width:  3
        color: "#4A90E2"
'
        # Add QQQ points dynamically  aSumTotal[2][1] = "QQQ"
        # Start from 2 because element 1 is the name "QQQ"
		
        for i=2 to len(aSumTotal[2]) -2          
            xVal         = i-2
            yVal         = aSumTotal[2][i]    
            cQMLContent += ' XYPoint { x: ' + xVal + '; y: ' + yVal + ' }' + nl
        next

        cQMLContent += '    
		}

        // Second series: TOT (Orange) --------------
        LineSeries {
        name:  "$TOT"
        axisX:  axisX
        axisY:  axisY
        width:  3
        color: "#FF6B35"
'

        # Add TOT points dynamically aSumTotal[3][1] = "TOT"
        for i=2 to  len(aSumTotal[3]) -2          // len(aLineTOT)
            xVal         = i-2
            yVal         = aSumTotal[3][i]        // aLineTOT[i]
            cQMLContent += ' XYPoint { x: ' + xVal + '; y: ' + yVal + ' }' + nl
        next

        cQMLContent += '    
		}
		
       // Third series:(Black Base Line) ---------------
        LineSeries {
        name:  "Base=1"
        axisX:  axisX
        axisY:  axisY
        width:  1
        color: "#0000FF"
'
        # Add Base=1 points dynamically  aSumTotal[2][1] = "QQQ"
        # Start from 2 because element 1 is the name "QQQ"
		
        for i=2 to len(aSumTotal[2]) -2          
            xVal         = i-2
            yVal         = 1        // FIXed Value:  aSumTotal[2][i]    
            cQMLContent += ' XYPoint { x: ' + xVal + '; y: ' + yVal + ' }' + nl
        next

        cQMLContent += '    
		}		
		
		
}
'

# 3. Save generated QML file
# -----------------------------------------------------

        write("stock_chart.qml", cQMLContent)


# 4. Run the application and display the chart
# -----------------------------------------------------

new qApp {
    w = new qWidget() {
        setWindowTitle("Stock Analysis Result") 
        resize(800, 600) 
          move(100, 100)
        
        oQuick = new qQuickWidget(w) {
            engine().AddImportPath(exefolder()+"qml")
			
            # Set the source to the file we just generated
            setSource(AppURL("stock_chart.qml"))
            setResizeMode(1) # QQuickWidget::SizeRootObjectToView
        }
        
        oLayout = new qVBoxlayout() {
            AddWidget(oQuick)
        }
        
        setlayout(oLayout)
        show()
    }
    exec()
}

        
// ================================================  
// ================================================  
/*
<=====> 
MONTHLY SHORT-List-6

<----- Debug CSV to aList 2D Display ----->
QQQ     103.86  96.98   95.46   101.7   98.75   103.06  100.45  107.92  109.05  111.19
ASML    80.28   83.06   82.32   90.79   87.36   90.42   90.79   100.32  97.51   100.28
ADBE    93.94   89.13   85.15   93.8    94.22   99.47   95.79   97.86   102.31  108.54
AMD     2.87    2.2     2.14    2.85    3.55    4.57    5.14    6.86    7.4     6.91
GOOGL   38.63   37.81   35.62   37.88   35.15   37.19   34.94   39.3    39.22   39.93
AMZN    33.79   29.35   27.63   29.68   32.98   36.14   35.78   37.94   38.46   41.87

<----- Debug Performance List: $RangeMth: 5 ----->
QQQ     0       0       0       0       0       0.99    1.04    1.13    1.07    1.13
ASML    0       0       0       0       0       1.13    1.09    1.22    1.07    1.15
ADBE    0       0       0       0       0       1.06    1.07    1.15    1.09    1.15
AMD     0       0       0       0       0       1.59    2.34    3.21    2.60    1.95
GOOGL   0       0       0       0       0       0.96    0.92    1.10    1.04    1.14
AMZN    0       0       0       0       0       1.07    1.22    1.37    1.30    1.27

<----- Debug Name List ----->
QQQ     0       0       0       0       0       AMD     AMD     AMD     AMD     AMD
ASML    0       0       0       0       0       ASML    AMZN    AMZN    AMZN    AMZN
ADBE    0       0       0       0       0       AMZN    ASML    ASML    ADBE    ADBE
AMD     0       0       0       0       0       ADBE    ADBE    ADBE    ASML    ASML
GOOGL   0       0       0       0       0       QQQ     QQQ     QQQ     QQQ     GOOGL
AMZN    0       0       0       0       0       GOOGL   GOOGL   GOOGL   GOOGL   QQQ

<----- Debug Rank List  ----->
QQQ     0       0       0       0       0       5       5       5       5       6
ASML    0       0       0       0       0       2       3       3       4       4
ADBE    0       0       0       0       0       4       4       4       3       3
AMD     0       0       0       0       0       1       1       1       1       1
GOOGL   0       0       0       0       0       6       6       6       6       5
AMZN    0       0       0       0       0       3       2       2       2       2
3
$Top10 <= 3
<----- nCol 7 ----->
Buy: ASML       90.42   7
Buy: AMD        4.57    7
Buy: AMZN       36.14   7

<----- nCol 8 ----->
Buy: ASML       90.79   8
Buy: AMD        5.14    8
Buy: AMZN       35.78   8

*/
