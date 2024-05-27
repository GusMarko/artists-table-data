import json
import requests
import os
import boto3
import io
import csv
import uuid
import urllib.parse


def lambda_handler(event, context):

    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(
        event["Records"][0]["s3"]["object"]["key"], encoding="utf-8"
    )

    response = s3.get_object(Bucket=bucket, Key=key)
    body = response["Body"].read().decode("utf-8")

    artist_names = body.splitlines()

    for artist in artist_names:
        print(artist)

    return {"statusCode": 200, "body": json.dumps("Processed file: " + key)}


## yea
