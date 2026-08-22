import json
import logging
from functools import lru_cache

import boto3

from app.config import settings

logger = logging.getLogger(__name__)


@lru_cache
def get_sqs_client():
    return boto3.client("sqs", region_name=settings.aws_region)


@lru_cache
def get_textract_client():
    return boto3.client("textract", region_name=settings.aws_region)


def process_document(bucket: str, key: str) -> str:
    result = get_textract_client().detect_document_text(
        Document={"S3Object": {"Bucket": bucket, "Name": key}}
    )
    lines = [
        block["Text"]
        for block in result["Blocks"]
        if block["BlockType"] == "LINE"
    ]
    return "\n".join(lines)


def handle_message(body: dict) -> None:
    for record in body.get("Records", []):
        s3_info = record.get("s3")
        if not s3_info:
            continue

        bucket = s3_info["bucket"]["name"]
        key = s3_info["object"]["key"]
        logger.info("processing s3://%s/%s", bucket, key)

        text = process_document(bucket, key)
        logger.info("extracted %d chars from %s", len(text), key)

        # Publishing the result requires the recipient's SNS platform
        # endpoint ARN, which comes from wherever device tokens get
        # registered (not built yet) — so this step is intentionally a
        # stub until that registration exists.
        # sns.publish(TargetArn=<endpoint_arn>, Message=text)


def run() -> None:
    logger.info("starting SQS consumer on %s", settings.sqs_processing_queue_url)
    sqs = get_sqs_client()
    while True:
        response = sqs.receive_message(
            QueueUrl=settings.sqs_processing_queue_url,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=20,
        )

        for message in response.get("Messages", []):
            try:
                handle_message(json.loads(message["Body"]))
            except Exception:
                logger.exception("failed processing message %s", message["MessageId"])
                continue

            sqs.delete_message(
                QueueUrl=settings.sqs_processing_queue_url,
                ReceiptHandle=message["ReceiptHandle"],
            )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    run()
