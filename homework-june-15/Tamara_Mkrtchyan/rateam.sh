#!/bin/bash

bankUrl="https://rate.am/en/armenian-dram-exchange-rates/banks/cash"
fileName="test.html"
htmlFile="index.html"

while true; do
	wget --output-document $fileName $bankUrl

	usdBuy=$(cat $fileName | grep -A 3 ameriabank | tail -2 | grep -o '[0-9]*' | head -1)
	usdSell=$(cat $fileName | grep -A 3 ameriabank | tail -2 | grep -o '[0-9]*' | tail -1)

	echo "<!DOCTYPE html>
<html lang=en>
<head>
	<meta charset=UTF-8>
	<meta http-equiv=X-UA-Compatible content=IE=edge>
	<meta name=viewport content=width=device-width, initial-scale=1.0>
	<title>USD Rate</title>
</head>
<body>
	<p style=\"text-align:center\"><span style=\"font-size:26px\"><strong>Exchange Rates</strong></span></p>
	<p style=\"text-align:center\"><span style=\"color:\#0a3325\"><span style=\"font-size:20px\">Ameria bank</span></span></p>
	<hr />
	<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\" style=\"width:500px\" align=\"center\">
		<thead>
			<tr>
				<th scope=\"col\">BUY</th>
				<th scope=\"col\">SELL</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td style=\"text-align:center\">$usdBuy</td>
				<td style=\"text-align:center\">$usdSell</td>
			</tr>
		</tbody>
	</table>
</body>
</html>" > $htmlFile
	rm -f $fileName

	sleep 60
done