import json
import os
import boto3
from PIL import Image
from io import BytesIO

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

DEST_BUCKET = os.environ["DEST_BUCKET"]
TABLE_NAME = os.environ["TABLE_NAME"]

def lambda_handler(event, context):
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]

    response = s3.get_object(Bucket=bucket, Key=key)
    image = Image.open(BytesIO(response["Body"].read()))

    image.thumbnail((256, 256))

    buffer = BytesIO()
    image.save(buffer, "JPEG")
    buffer.seek(0)

    s3.put_object(
        Bucket=DEST_BUCKET,
        Key=key,
        Body=buffer,
        ContentType="image/jpeg"
    )

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            "image_name": key,
            "source_bucket": bucket,
            "destination_bucket": DEST_BUCKET
        }
    )

    return {
        "statusCode": 200,
        "body": json.dumps("Image processed successfully")
    }
