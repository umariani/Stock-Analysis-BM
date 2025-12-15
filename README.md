To RUN the App
     -  Start  Stock-Analysis-BM.ring    
     -  Click "Get Quotes"     fetches the historical data for the list of Tickers
     -  Click "Run Analysis"  invokes the algorithm to select the top stocks

Theory
     Based on Current Month  minus Month-7 prices
     Calc the Performance of each Stock
     Sort the Performance for every Month moving forward
     Buy the Stocks that are Ranked as the Top10  List  next month
     Sell if the Stock is Below the Top10
     Repeat Once a Month.

Analysis
     Showed that Buy the Top-7 stocks based on the
      Performance over a Period of 7 Month gives balanced results.

Caveat:
     Past Performance does NOT imply Future Performance.

Playing With Parms
     First - Download data  with  "Get Quotes"  button
     Second - Analyses data with  "Run Analysis" button

     The Parameters for TopTen (7)  and RangeMth (7) can be changed
      And the "Run Analysis" button will show the Results.

Debugging  flag can be Toggled using the "DEBUG"  drop down
     "Array-Data"    
    "Performance"  
     "Sort"          
     "Sort-Name"    
     "Rank"          
     "Buy-Price"    
      "Gain"          
      "Monthly-Perf"  
     "Compound"      
     "Summary-Stock"
     "Summary-Total"
     "Show-Top10"    
      "Gain-Details"  

TRUST BUT VERIFY !!!
