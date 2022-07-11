#!/bin/bash

# This script fetches USD/AMD rate from rate.am and updates it every minute
# It requires web server path as argument

webServerPath=$1

function getRate () {
  bank=$2
  if [[ $1 = buy ]]; then
    curl -s https://rate.am | \
    grep -A 3 $bank | \
    grep -o '[0-9]*' | \
    tail -2 | head -1
  elif [[ $1 = sell ]]; then
    curl -s https://rate.am | \
    grep -A 3 $bank | \
    grep -o '[0-9]*' | \
    tail -1
  fi
}

while true; do

usdBuyAmeria=$(getRate buy ameriabank)
usdSellAmeria=$(getRate sell ameriabank)
usdBuyArarat=$(getRate buy araratbank)
usdSellArarat=$(getRate sell araratbank)
usdBuyAcba=$(getRate buy acba)
usdSellAcba=$(getRate sell acba)
usdBuyUni=$(getRate buy yunibank)
usdSellUni=$(getRate sell yunibank)
usdBuyAeb=$(getRate buy hayekonombank)
usdSellAeb=$(getRate sell hayekonombank)
usdBuyVtb=$(getRate buy vtbhayastan-bank)
usdSellVtb=$(getRate sell vtbhayastan-bank)

currentDate=$(date +"%A %B %d %Y | %H:%M")

echo -e '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="30;url=index.html">
<title>USD/AMD Rate</title>
<script type="text/javascript">
    window.onload = setupRefresh;

    function setupRefresh() {
      setTimeout("refreshPage();", 60000);
    }
    function refreshPage() {
       window.location = location.href;
    }
</script>
<style>
  body {background-color: black;}
  .content {
    text-align: center;
    color: white;
    font-family: "Tahoma";
    font-style: normal;
  }
</style>
</head>
<body>
<div class="content">
<h2>'$currentDate'</h2>
<h3>Ameria Bank</h3>
<h4>Buy: 1 USD = '$usdBuyAmeria' AMD</h4>
<h4>Sell: 1 USD = '$usdSellAmeria' AMD</h4>
<h3>Ararat Bank</h3>
<h4>Buy: 1 USD = '$usdBuyArarat' AMD</h4>
<h4>Sell: 1 USD = '$usdSellArarat' AMD</h4>
<h3>ACBA Bank</h3>
<h4>Buy: 1 USD = '$usdBuyAcba' AMD</h4>
<h4>Sell: 1 USD = '$usdSellAcba' AMD</h4>
<h3>Unibank</h3>
<h4>Buy: 1 USD = '$usdBuyUni' AMD</h4>
<h4>Sell: 1 USD = '$usdSellUni' AMD</h4>
<h3>Arm Econom Bank</h3>
<h4>Buy: 1 USD = '$usdBuyAeb' AMD</h4>
<h4>Sell: 1 USD = '$usdSellAeb' AMD</h4>
<h3>VTB Bank</h3>
<h4>Buy: 1 USD = '$usdBuyVtb' AMD</h4>
<h4>Sell: 1 USD = '$usdSellVtb' AMD</h4>
</div>
</body>
</html>' > ${webServerPath}/index.html

sleep 60

done