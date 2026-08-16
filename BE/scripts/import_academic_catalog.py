import json
import sys

from pathlib import Path

from sqlalchemy.orm import Session


BASE_DIR = Path(
    __file__,
).resolve().parent.parent

sys.path.insert(
    0,
    str(
        BASE_DIR,
    ),
)


from core.database import SessionLocal

from models.user import User

from models.subject import (
    AcademicTeacher,
    Subject,
    SubjectOffering,
    UserSubject,
)


CATALOG_PATH = (
    BASE_DIR
    / "data"
    / "dmi"
    / "academic_catalog.json"
)

def normalize_text(
    value,
):
    if value is None:
        return None

    value = str(
        value,
    ).strip()

    if not value:
        return None

    return value


def get_or_create_teacher(
    db: Session,
    name: str,
):
    normalized_name = (
        name
        .strip()
    )

    teacher = (
        db.query(
            AcademicTeacher,
        )
        .filter(
            AcademicTeacher.name
            ==
            normalized_name,
        )
        .first()
    )

    if teacher is not None:
        if not teacher.is_active:
            teacher.is_active = True

        return teacher

    teacher = AcademicTeacher(
        name=normalized_name,
        is_active=True,
    )

    db.add(
        teacher,
    )

    db.flush()

    return teacher


def get_or_create_subject(
    db: Session,
    university,
    department,
    course,
    subject_data,
):
    code = normalize_text(
        subject_data.get(
            "code",
        ),
    )

    name = normalize_text(
        subject_data.get(
            "name",
        ),
    )

    if name is None:
        raise ValueError(
            "Materia senza nome.",
        )

    query = (
        db.query(
            Subject,
        )
        .filter(
            Subject.university_code
            ==
            university["code"],
            Subject.department
            ==
            department["name"],
            Subject.course
            ==
            course["name"],
        )
    )

    subject = None

    if code is not None:
        subject = (
            query
            .filter(
                Subject.code
                ==
                code,
            )
            .first()
        )

    if subject is None:
        subject = (
            query
            .filter(
                Subject.name
                ==
                name,
            )
            .first()
        )

    if subject is None:
        subject = Subject(
            code=code,
            name=name,
            university=university["name"],
            university_code=university["code"],
            department=department["name"],
            department_code=department.get(
                "code",
            ),
            course=course["name"],
            course_code=course.get(
                "code",
            ),
            degree_type=course.get(
                "degree_type",
            ),
            study_year=subject_data.get(
                "study_year",
            ),
            is_active=True,
        )

        db.add(
            subject,
        )

        db.flush()

        return subject

    subject.code = code

    subject.name = name

    subject.university = university[
        "name"
    ]

    subject.university_code = university[
        "code"
    ]

    subject.department = department[
        "name"
    ]

    subject.department_code = (
        department.get(
            "code",
        )
    )

    subject.course = course[
        "name"
    ]

    subject.course_code = (
        course.get(
            "code",
        )
    )

    subject.degree_type = (
        course.get(
            "degree_type",
        )
    )

    subject.study_year = (
        subject_data.get(
            "study_year",
        )
    )

    subject.is_active = True

    return subject


def get_or_create_offering(
    db: Session,
    subject: Subject,
    offering_data,
):
    module = normalize_text(
        offering_data.get(
            "module",
        ),
    )

    channel = normalize_text(
        offering_data.get(
            "channel",
        ),
    )

    academic_year = normalize_text(
        offering_data.get(
            "academic_year",
        ),
    )

    source_url = normalize_text(
        offering_data.get(
            "source_url",
        ),
    )

    query = (
        db.query(
            SubjectOffering,
        )
        .filter(
            SubjectOffering.subject_id
            ==
            subject.id,
        )
    )

    if module is None:
        query = query.filter(
            SubjectOffering.module
            .is_(
                None,
            ),
        )
    else:
        query = query.filter(
            SubjectOffering.module
            ==
            module,
        )

    if channel is None:
        query = query.filter(
            SubjectOffering.channel
            .is_(
                None,
            ),
        )
    else:
        query = query.filter(
            SubjectOffering.channel
            ==
            channel,
        )

    if academic_year is None:
        query = query.filter(
            SubjectOffering.academic_year
            .is_(
                None,
            ),
        )
    else:
        query = query.filter(
            SubjectOffering.academic_year
            ==
            academic_year,
        )

    offering = query.first()

    if offering is None:
        offering = SubjectOffering(
            subject_id=subject.id,
            module=module,
            channel=channel,
            academic_year=academic_year,
            source_url=source_url,
            is_active=True,
        )

        db.add(
            offering,
        )

        db.flush()
    else:
        offering.source_url = (
            source_url
        )

        offering.is_active = True

    return offering


def import_catalog(
    db: Session,
):
    if not CATALOG_PATH.exists():
        raise FileNotFoundError(
            f"Catalogo non trovato: {CATALOG_PATH}"
        )

    with open(
        CATALOG_PATH,
        "r",
        encoding="utf-8",
    ) as file:
        catalog = json.load(
            file,
        )

    universities = catalog.get(
        "universities",
        [],
    )

    subject_count = 0

    offering_count = 0

    teacher_links_count = 0

    for university in universities:
        university_name = (
            normalize_text(
                university.get(
                    "name",
                ),
            )
        )

        university_code = (
            normalize_text(
                university.get(
                    "code",
                ),
            )
        )

        if university_name is None:
            continue

        if university_code is None:
            continue

        university["name"] = (
            university_name
        )

        university["code"] = (
            university_code
        )

        for department in university.get(
            "departments",
            [],
        ):
            department_name = (
                normalize_text(
                    department.get(
                        "name",
                    ),
                )
            )

            if department_name is None:
                continue

            department[
                "name"
            ] = department_name

            for course in department.get(
                "courses",
                [],
            ):
                course_name = normalize_text(
                    course.get(
                        "name",
                    ),
                )

                if course_name is None:
                    continue

                course[
                    "name"
                ] = course_name

                for subject_data in course.get(
                    "subjects",
                    [],
                ):
                    subject = (
                        get_or_create_subject(
                            db,
                            university,
                            department,
                            course,
                            subject_data,
                        )
                    )

                    subject_count += 1

                    for offering_data in subject_data.get(
                        "offerings",
                        [],
                    ):
                        offering = (
                            get_or_create_offering(
                                db,
                                subject,
                                offering_data,
                            )
                        )

                        offering_count += 1

                        teacher_names = (
                            offering_data.get(
                                "teachers",
                                [],
                            )
                            or []
                        )

                        for teacher_name in teacher_names:
                            teacher_name = (
                                normalize_text(
                                    teacher_name,
                                )
                            )

                            if teacher_name is None:
                                continue

                            teacher = (
                                get_or_create_teacher(
                                    db,
                                    teacher_name,
                                )
                            )

                            if (
                                teacher
                                not in offering.teachers
                            ):
                                offering.teachers.append(
                                    teacher,
                                )

                                teacher_links_count += 1

    db.commit()

    return {
        "subjects":
            subject_count,

        "offerings":
            offering_count,

        "teacher_links":
            teacher_links_count,
    }


def main():
    db = SessionLocal()

    try:
        result = import_catalog(
            db,
        )

        print(
            json.dumps(
                result,
                ensure_ascii=False,
                indent=2,
            )
        )
    except Exception:
        db.rollback()

        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()