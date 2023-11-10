# ruby-schwab
This is a plugin library aimed to interact with Charles Schwab's API.  
In the meanwhile, I'm working on perfecting it for CSV.  

## Usage examples  
```
b = Schwab.new("XXXXXXXXX.csv")
b.sort_attribute_by(:deposit, :type, true)
b.sort_attribute_by(:withdrawal, :description)
b.filter_transactions_by_dates(Date.new(2023, 11, 1))
b.filter_transactions_by_dates(Date.new(2023, 11, 1)).sort_attribute_by(:withdrawal, :
description)
```
