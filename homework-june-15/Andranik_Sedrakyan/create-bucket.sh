#!/bin/bash

function createIndex() {
    echo -e "
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
      <head>
        <meta charset="utf-8">
        <title></title>
      </head>
      <body>
        <p>Hello World!</p>
      </body>
    </html>
    ">index.html
}

function deleteBucket() {
  aws s3api delete-bucket \
  --bucket  "${resource_name}-aca-bootcamp-bucket"\
  --region us-east-1
}

function emptyBucket() {
  aws s3 rm s3://"${resource_name}-aca-bootcamp-bucket"/ \
  --recursive \
  --output text > /dev/null
}

function createBucket() {
  aws s3api create-bucket \
    --bucket "${resource_name}-aca-bootcamp-bucket" \
    --region us-east-1 \
    --acl public-read \
    --output text > /dev/null

    if [[ $? != 0 ]]; then
      deleteBucket
    fi
}

function upload() {
  aws s3 cp ./index.html s3://"${resource_name}-aca-bootcamp-bucket" \
  --acl public-read \
  --output text > /dev/null

  if [[ $? != 0 ]]; then
    echo "Something went wrong when uploading file to s3 bucket"
  fi
}
