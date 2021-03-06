#!/bin/bash

# This script fetches USD/AMD rate from rate.am and updates it every minute
# It requires web server path as argument

webServerPath=$1

while true; do

usdBuy=$(curl -s https://rate.am | grep -A 3 "ameriabank" | tail -2 | grep -o '[0-9]*' | head -1)
usdSell=$(curl -s https://rate.am | grep -A 3 "ameriabank" | tail -2 | grep -o '[0-9]*' | tail -1)
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
</head>
<body>
<div>
<h3>Ameriabank</h3>
<h4>Purchase: 1 USD = '$usdBuy' AMD</h4>
<h4>Sale: 1 USD = '$usdSell' AMD</h4>
<h5>'$currentDate'</h5>
</div>
</body>
</html>' > ${webServerPath}/index.html

sleep 60

done
