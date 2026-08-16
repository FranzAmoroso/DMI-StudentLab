import os

from dotenv import load_dotenv


load_dotenv()


class Settings:
    def __init__(self):
        self.database_url = (
            os.getenv("StudentLab_DATABASE_URL")
            or os.getenv("DATABASE_URL")
            or "postgresql://postgres:postgres@localhost:5432/studentlab"
        )


settings = Settings()