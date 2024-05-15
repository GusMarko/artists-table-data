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
    table = dynamodb.Table(os.getenv("ARTISTS_TABLE"))
