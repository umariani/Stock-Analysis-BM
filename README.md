
To Install App
     - Ring Language must be installed
     - c:\> ringpm install Stock-Analysis-BM from umariani

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
     First  - Download data with  "Get Quotes"   button
     Second - Analyse  data with  "Run Analysis" button

     Parameters for Get Quotes
          - Interval >> 1mo, 1wk, 1d     => Fequency of data quote
          - Range    >> 5y, 1y, 2y, 10y  => Years of data
          
     Parameters for Eun Analysis     -
          - TopTen   >> 7, 5, 10, 15           => Number of stocks to Buy
          - RangeMth >> 7, 6, 8, 9, 10, 11, 12 => Performance peropd length
    

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
