from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from .config import settings


DATABASE_URL = settings.database_url


engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    echo=True,
)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


Base = declarative_base()


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def create_tables():
    Base.metadata.create_all(
        bind=engine,
    )


print("\n\033[34m\\_+_/\033[0m\n")