
from datetime import datetime, timezone

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from core.database import Base


def utc_now():
    return datetime.now(timezone.utc)


class TeacherMaterialRequest(Base):
    __tablename__ = "teacher_material_requests"

    id = Column(Integer, primary_key=True, index=True)
    student_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    teacher_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    topic = Column(String(255), nullable=True)
    message = Column(Text, nullable=False)
    status = Column(String(30), nullable=False, default="pending", server_default="pending", index=True)
    fulfilled_material_id = Column(Integer, ForeignKey("teacher_materials.id", ondelete="SET NULL"), nullable=True, index=True)
    resolved_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, index=True)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now, index=True)

    student = relationship("User", foreign_keys=[student_user_id])
    teacher = relationship("User", foreign_keys=[teacher_user_id])
    resolver = relationship("User", foreign_keys=[resolved_by])
    subject = relationship("Subject")
    fulfilled_material = relationship("TeacherMaterial")

    __table_args__ = (
        CheckConstraint("status IN ('pending','fulfilled','rejected','cancelled')", name="chk_teacher_material_request_status"),
    )
