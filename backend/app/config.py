from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # These match the environment_variables Terraform injects into the EB
    # environment (see main.tf) — no dummy/placeholder values here, this
    # reads whatever the real deployed infra actually is.
    aws_region: str = "ap-south-1"
    s3_documents_bucket: str
    sqs_processing_queue_url: str
    sns_apns_platform_app_arn: str = ""
    db_secret_arn: str = ""
    cognito_user_pool_id: str = ""
    cognito_app_client_id: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
