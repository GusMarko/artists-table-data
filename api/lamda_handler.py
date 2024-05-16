import json
import requests
import os
import boto3
import io
import csv
import uuid
import urllib.parse


def lambda_handler(event, context):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("ARTISTS_TABLE")

    print(json.dumps(event, indent=2))

    for record in event["Records"]:
        log_new_artists(record)


def log_new_artists(record):
    if record["eventName"] == "INSERT":
        new_image = record["dynamodb"]["NewImage"]
        artist_name = new_image.get("ArtistName", {}).get("S")

        if artist_name:
            # Print the artist's name
            print(f"New artist added: {artist_name}")
        else:
            print("Artist name not found in the new image")
    # aa
