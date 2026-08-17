import os

from dotenv import load_dotenv


load_dotenv()


class Settings:
    def __init__(self):
        self.database_url = (
            os.getenv(
                "StudentLab_DATABASE_URL",
            )
            or os.getenv(
                "DATABASE_URL",
            )
            or (
                "postgresql://"
                "postgres:postgres@"
                "localhost:5432/"
                "studentlab"
            )
        )

        self.blob_read_write_token = (
            os.getenv(
                "StudentLab_READ_WRITE_TOKEN",
            )
            or os.getenv(
                "BLOB_READ_WRITE_TOKEN",
            )
        )

        self.secret_key = (
            os.getenv(
                "StudentLab_SECRET_KEY",
            )
            or os.getenv(
                "SECRET_KEY",
            )
        )

        if not self.secret_key:
            raise RuntimeError(
                "StudentLab_SECRET_KEY "
                "non configurata."
            )

        self.current_policy_version = (
            os.getenv(
                "StudentLab_POLICY_VERSION",
            )
            or "1.0"
        )

        self.minimum_registration_age = int(
            os.getenv(
                "StudentLab_MINIMUM_AGE",
            )
            or "14"
        )


settings = Settings()