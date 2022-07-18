#!/bin/bash

while true
do
buy=$(curl http://rate.am | grep -A 6 Ameria | tail -2 | tr -d '</td>' | head -1)
sell=$(curl http://rate.am | grep -A 6 Ameria | tail -2 | tr -d '</td>' | tail -1)
date=$(date +"%T %D")
echo -e " <!DOCTYPE html>
<html>
<head>
<title>Title of the document</title>
</head>

<body>
<h1 style='text-align: center;'>AmeriaBank $ Exchange Rate</h1>
<p style='text-align: left;'>&nbsp;</p>
<p style='text-align: left;'>$date</p>
<table style='border-collapse: collapse; width: 100%;' border='1'>
<tbody>
<tr>
<td style='width: 50%;'><span style='color: #00ff00;'>BUY</span></td>
<td style='width: 50%;'>$buy</td>
</tr>
<tr>
<td style='width: 50%;'><span style='color: #0000ff;'>SELL</span></td>
<td style='width: 50%;'>$sell</td>
</tr>
</tbody>
</table>
</body>
</html> " > /home/ubuntu/s3Volume/index.html

sleep 60 
done 
