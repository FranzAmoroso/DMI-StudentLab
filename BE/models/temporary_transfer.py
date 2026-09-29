from datetime import datetime, timedelta
from uuid import uuid4
from sqlalchemy import Column, String, Integer, BigInteger, DateTime, Boolean, JSON
from core.database import Base

class TemporaryTransfer(Base):
    __tablename__ = 'temporary_storage_transfers'
    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    actor_id = Column(Integer, nullable=False, index=True)
    filename = Column(String(180), nullable=False)
    mime_type = Column(String(150), nullable=False)
    size = Column(BigInteger, nullable=False)
    sha256 = Column(String(64), nullable=False)
    destination = Column(String(10), nullable=False)
    path_segments = Column(JSON, nullable=False)
    blob_path = Column(String(500), nullable=False, unique=True)
    state = Column(String(20), nullable=False, default='uploading', index=True)
    attempts = Column(Integer, nullable=False, default=0)
    upload_until = Column(DateTime)
    lease_id = Column(String(36))
    lease_until = Column(DateTime)
    result_id = Column(String(150))
    error = Column(String(300))
    cleaned = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False, default=lambda: datetime.utcnow()+timedelta(days=7))
