#!/bin/bash

while true
do
    Date=$(date '+%D Minute: %M Seconds: %S')
    SITE=$(curl -s https://rate.am/)

    # Full site html code
    DataLine=$(echo $SITE | egrep -o 'ameriabank.>[0-9]{1,4}</a></td> <td class="date">.{10,20}</td> <td>[0-9]{2,4}</td> <td>[0-9]{2,4}</td>')


    # Get updated date / buy / sell   rates
    DateTag=$(echo $DataLine | awk '{print $2 " " $3 "  " $4 " " $5}')
    BuyTag=$(echo $DataLine | awk '{print $6}')
    SellTag=$(echo $DataLine | awk '{print $7}')

    echo "<html>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport'
              content='width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'>
        <meta http-equiv='X-UA-Compatible' content='ie=edge'>
        <meta http-equiv='refresh' content='30' />
        <title>Ameria change rate</title>
    <title>Title of the document</title>
    <style>
        td,th,table { border: 1px solid grey; }
    </style>
    </head>
    <body>
    <h1> $Date </h1>
    <table>
        <tr>
        <th>Updated date</th>
        <th>Buy</th>
        <th>Sell</th>
        </tr>
        <tr>
        $DateTag
        $BuyTag
        $SellTag
        </tr>
    </table>
    </body>
    </html>" | sudo tee -i /myS3Bucket/Project_X/index.html

sleep 60
done
