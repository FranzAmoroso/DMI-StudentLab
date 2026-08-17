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

        self.access_token_expire_minutes = int(
            os.getenv(
                "StudentLab_ACCESS_TOKEN_EXPIRE_MINUTES",
            )
            or os.getenv(
                "ACCESS_TOKEN_EXPIRE_MINUTES",
            )
            or "1440"
        )

        self.email_verification_secret = (
            os.getenv(
                "StudentLab_EMAIL_VERIFICATION_SECRET",
            )
            or os.getenv(
                "EMAIL_VERIFICATION_SECRET",
            )
            or self.secret_key
        )

        self.email_verification_expire_minutes = int(
            os.getenv(
                "StudentLab_EMAIL_VERIFICATION_EXPIRE_MINUTES",
            )
            or os.getenv(
                "EMAIL_VERIFICATION_EXPIRE_MINUTES",
            )
            or "10"
        )

        self.email_verification_max_attempts = int(
            os.getenv(
                "StudentLab_EMAIL_VERIFICATION_MAX_ATTEMPTS",
            )
            or os.getenv(
                "EMAIL_VERIFICATION_MAX_ATTEMPTS",
            )
            or "5"
        )

        self.email_verification_resend_cooldown_seconds = int(
            os.getenv(
                "StudentLab_EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS",
            )
            or os.getenv(
                "EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS",
            )
            or "60"
        )

        self.email_verification_max_resends = int(
            os.getenv(
                "StudentLab_EMAIL_VERIFICATION_MAX_RESENDS",
            )
            or os.getenv(
                "EMAIL_VERIFICATION_MAX_RESENDS",
            )
            or "5"
        )

        self.smtp_host = (
            os.getenv(
                "StudentLab_SMTP_HOST",
            )
            or os.getenv(
                "SMTP_HOST",
            )
            or ""
        ).strip()

        self.smtp_port = int(
            os.getenv(
                "StudentLab_SMTP_PORT",
            )
            or os.getenv(
                "SMTP_PORT",
            )
            or "587"
        )

        self.smtp_username = (
            os.getenv(
                "StudentLab_SMTP_USERNAME",
            )
            or os.getenv(
                "SMTP_USERNAME",
            )
            or ""
        ).strip()

        self.smtp_password = (
            os.getenv(
                "StudentLab_SMTP_PASSWORD",
            )
            or os.getenv(
                "SMTP_PASSWORD",
            )
            or ""
        )

        self.smtp_from_email = (
            os.getenv(
                "StudentLab_SMTP_FROM_EMAIL",
            )
            or os.getenv(
                "SMTP_FROM_EMAIL",
            )
            or self.smtp_username
        ).strip()

        self.smtp_from_name = (
            os.getenv(
                "StudentLab_SMTP_FROM_NAME",
            )
            or os.getenv(
                "SMTP_FROM_NAME",
            )
            or "StudentLab"
        ).strip()

        self.smtp_use_tls = self._env_bool(
            (
                os.getenv(
                    "StudentLab_SMTP_USE_TLS",
                )
                or os.getenv(
                    "SMTP_USE_TLS",
                )
            ),
            default=True,
        )

        self.smtp_use_ssl = self._env_bool(
            (
                os.getenv(
                    "StudentLab_SMTP_USE_SSL",
                )
                or os.getenv(
                    "SMTP_USE_SSL",
                )
            ),
            default=False,
        )

    @staticmethod
    def _env_bool(
        value: str | None,
        *,
        default: bool,
    ) -> bool:
        if value is None:
            return default

        return (
            value
            .strip()
            .lower()
            in {
                "1",
                "true",
                "yes",
                "on",
            }
        )


settings = Settings()