import uuid
from functools import lru_cache

import boto3
from fastapi import APIRouter
from pydantic import BaseModel

from app.config import settings

router = APIRouter(prefix="/documents", tags=["documents"])


@lru_cache
def get_s3_client():
    # No access keys here on purpose — boto3's default credential chain
    # picks up the EB EC2 instance profile's role in deployment, or your
    # local AWS CLI profile when running this locally. Built lazily (not
    # at import time) so the app can still start before credentials are
    # configured.
    return boto3.client("s3", region_name=settings.aws_region)


class UploadUrlRequest(BaseModel):
    user_id: str
    filename: str


class UploadUrlResponse(BaseModel):
    upload_url: str
    key: str


@router.post("/upload-url", response_model=UploadUrlResponse)
def create_upload_url(req: UploadUrlRequest) -> UploadUrlResponse:
    key = f"{req.user_id}/{uuid.uuid4()}-{req.filename}"

    upload_url = get_s3_client().generate_presigned_url(
        "put_object",
        Params={"Bucket": settings.s3_documents_bucket, "Key": key},
        ExpiresIn=300,
    )

    return UploadUrlResponse(upload_url=upload_url, key=key)
