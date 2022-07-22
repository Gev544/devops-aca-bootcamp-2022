#!/bin/bash
project_name=$1
  while true; do
    #getting prices from rate.am
    buy=$(curl -s  https://rate.am/ | grep -A2  "ameria" | tail -1 |grep -Eo '[0-9]{1,3}')
    sell=$(curl -s  https://rate.am/ | grep -A3  "ameria" | tail -1 |grep -Eo '[0-9]{1,3}')

    #getting current date in Armenia
    date=$(TZ=UTC-4 date -R)

    sudo echo -e "
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
      <head>
        <meta charset="utf-8">
        <title>Rate</title>
        <style>
        .main{
          margin:auto;
          width: 700px;
        }

        .header, .rate, .date{
          border: 1px solid black;
          margin: auto;
          width:400px;
        }

        .header div, .rate div{
          width: 190px;
          display: inline-block;
        }

        .header p, .rate p, .date p{
          text-align: center;
          font-family: Arial,Helvetica,sans-serif;
        }
        </style>
      </head>
      <body>
        <div class="main">
          <div class="date">
            <p>${date}</p>
          </div>
        <div class="header">
          <div><p>BUY</p></div>
          <div><p>Sell</p></div>
        </div>
        <div class="rate">
          <div><p>${buy}</p></div>
          <div><p>${sell}</p></div>
        </div>
        </div>

        <script>
          window.setInterval('refresh()', 60000);
          // (Call a function every 60 seconds).

          // Refresh or reload page.
          function refresh() {
            window .location.reload();
          }
        </script>
      </body>
    </html>
    ">/var/www/${project_name}/index.html

    sleep 1m
  done
