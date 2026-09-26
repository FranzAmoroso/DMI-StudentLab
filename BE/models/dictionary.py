"""Dizionario delle materie: argomenti, termini e una versione del contenuto
per ogni anno accademico (definizioni, esempi, esercizi, domande d'esame,
collegamenti). Chi scrive (admin o docente) resta registrato con nome e data
anche quando non insegna più la materia."""
from datetime import datetime, timezone

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint

from core.database import Base


def utc_now():
    return datetime.now(timezone.utc)


class DictionaryTopic(Base):
    __tablename__ = 'dictionary_topics'

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey('subjects.id', ondelete='CASCADE'), nullable=False, index=True)
    slug = Column(String(120), nullable=False)
    title = Column(String(200), nullable=False)
    sort_order = Column(Integer, nullable=False, default=0, server_default='0')
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    __table_args__ = (UniqueConstraint('subject_id', 'slug', name='uq_dictionary_topic_slug'),)


class DictionaryEntry(Base):
    __tablename__ = 'dictionary_entries'

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey('subjects.id', ondelete='CASCADE'), nullable=False, index=True)
    topic_id = Column(Integer, ForeignKey('dictionary_topics.id', ondelete='SET NULL'), nullable=True, index=True)
    slug = Column(String(120), nullable=False)
    term = Column(String(200), nullable=False, index=True)
    aliases_json = Column(Text, nullable=False, default='[]')
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now)

    __table_args__ = (UniqueConstraint('subject_id', 'slug', name='uq_dictionary_entry_slug'),)


REVIEW_STATES = ('to_review', 'confirmed', 'same_as_previous', 'changed')


class DictionaryVersion(Base):
    __tablename__ = 'dictionary_versions'

    id = Column(Integer, primary_key=True, index=True)
    entry_id = Column(Integer, ForeignKey('dictionary_entries.id', ondelete='CASCADE'), nullable=False, index=True)
    academic_year = Column(String(9), nullable=False, index=True)
    formal_definition = Column(Text, nullable=True)
    informal_definition = Column(Text, nullable=True)
    examples_json = Column(Text, nullable=False, default='[]')
    exercises_json = Column(Text, nullable=False, default='[]')
    exam_questions_json = Column(Text, nullable=False, default='[]')
    related_json = Column(Text, nullable=False, default='[]')
    resources_json = Column(Text, nullable=False, default='[]')
    quiz_question_ids_json = Column(Text, nullable=False, default='[]')
    quiz_source = Column(String(500), nullable=True)
    teachers_json = Column(Text, nullable=False, default='[]')
    # Chi ha scritto: nome e ruolo salvati così come erano (restano anche dopo).
    author_user_id = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    author_name = Column(String(200), nullable=True)
    author_role = Column(String(20), nullable=False, default='admin', server_default='admin')
    assigned_teacher_user_id = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    assigned_teacher_name = Column(String(200), nullable=True)
    review_state = Column(String(20), nullable=False, default='to_review', server_default='to_review', index=True)
    reviewed_by = Column(Integer, ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now)

    __table_args__ = (
        UniqueConstraint('entry_id', 'academic_year', name='uq_dictionary_version_year'),
        CheckConstraint("review_state IN ('to_review','confirmed','same_as_previous','changed')",
                        name='chk_dictionary_review_state'),
        CheckConstraint("author_role IN ('admin','teacher','import')", name='chk_dictionary_author_role'),
    )
