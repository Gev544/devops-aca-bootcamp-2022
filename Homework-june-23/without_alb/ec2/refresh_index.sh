#!/bin/bash

while true
do
buy=$(curl https://rate.am/en/ | sed 's/<[^>]*>//g ; /^$/d' | grep -A3 Ameriabank | head -4 | tail -1)
sell=$(curl https://rate.am/en/ | sed 's/<[^>]*>//g ; /^$/d' | grep -A4 Ameriabank | head -5 | tail -1)
date=$(date +"%D %T")
echo "<!DOCTYPE html>
<html>
<head>
<title>
</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body {background-color:#ffffff;background-repeat:no-repeat;background-position:top left;background-attachment:fixed;}
h1{text-align:center;font-family:Times, serif;color:#000000;background-color:#ffffff;}
h2 {text-align:center;font-family:Times, serif;font-size:24px;font-style:italic;font-weight:bold;color:#000000;background-color:#ffffff;}
p {text-align:center;font-family:Times, serif;font-size:18px;font-style:italic;font-weight:bold;color:#000000;background-color:#ffffff;}
</style>
</head>
<body>
<h1>USD - AMD Currency</h1>
<h2>Ameriabank $date</h2>
<p>Buy 1$ - $buy dram</p>
<p>Sell 1$ - $sell dram</p>
</body>
</html>" > /home/ubuntu/s3-drive/index.html
sleep 59
done
