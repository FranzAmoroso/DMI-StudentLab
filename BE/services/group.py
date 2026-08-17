from sqlalchemy.orm import (
    Session,
    joinedload,
)

from models.group import (
    GroupJoinRequest,
    GroupMember,
    StudyGroup,
)

from models.user import (
    User,
)

from schemas.group import (
    GroupCreate,
    GroupUpdate,
)


def create_group(
    db: Session,
    data: GroupCreate,
):
    group = StudyGroup(
        name=data.name,
        description=data.description,
        subject_id=data.subject_id,
        university=data.university,
        department=data.department,
        course=data.course,
        is_private=data.is_private,
        created_by=data.created_by,
    )

    db.add(
        group,
    )

    db.flush()

    owner = GroupMember(
        group_id=group.id,
        user_id=data.created_by,
        role="owner",
    )

    db.add(
        owner,
    )

    try:
        db.commit()

        db.refresh(
            group,
        )

        return group

    except Exception:
        db.rollback()
        raise


def get_groups(
    db: Session,
):
    return (
        db.query(
            StudyGroup,
        )
        .order_by(
            StudyGroup.created_at.desc(),
        )
        .all()
    )


def get_public_groups(
    db: Session,
):
    return (
        db.query(
            StudyGroup,
        )
        .filter(
            StudyGroup.is_private.is_(
                False,
            ),
            StudyGroup.status ==
            "active",
        )
        .order_by(
            StudyGroup.created_at.desc(),
        )
        .all()
    )


def get_group_by_id(
    db: Session,
    group_id: int,
):
    return (
        db.query(
            StudyGroup,
        )
        .options(
            joinedload(
                StudyGroup.members,
            ).joinedload(
                GroupMember.user,
            )
        )
        .filter(
            StudyGroup.id ==
            group_id,
        )
        .first()
    )


def get_public_group_by_id(
    db: Session,
    group_id: int,
):
    return (
        db.query(
            StudyGroup,
        )
        .filter(
            StudyGroup.id ==
            group_id,
            StudyGroup.is_private.is_(
                False,
            ),
            StudyGroup.status ==
            "active",
        )
        .first()
    )


def get_groups_by_user(
    db: Session,
    user_id: int,
):
    return (
        db.query(
            StudyGroup,
        )
        .join(
            GroupMember,
            GroupMember.group_id ==
            StudyGroup.id,
        )
        .filter(
            GroupMember.user_id ==
            user_id,
        )
        .order_by(
            StudyGroup.created_at.desc(),
        )
        .all()
    )


def get_group_member(
    db: Session,
    group_id: int,
    user_id: int,
):
    return (
        db.query(
            GroupMember,
        )
        .filter(
            GroupMember.group_id ==
            group_id,
            GroupMember.user_id ==
            user_id,
        )
        .first()
    )


def get_group_members(
    db: Session,
    group_id: int,
):
    return (
        db.query(
            GroupMember,
        )
        .options(
            joinedload(
                GroupMember.user,
            )
        )
        .filter(
            GroupMember.group_id ==
            group_id,
        )
        .order_by(
            GroupMember.id.asc(),
        )
        .all()
    )


def get_available_group_members(
    db: Session,
    group_id: int,
):
    return (
        db.query(
            GroupMember,
        )
        .options(
            joinedload(
                GroupMember.user,
            )
        )
        .join(
            User,
            User.id ==
            GroupMember.user_id,
        )
        .filter(
            GroupMember.group_id ==
            group_id,
            User.is_active.is_(
                True,
            ),
            User.email_verified_at.is_not(
                None,
            ),
            User.available.is_(
                True,
            ),
            User.role.in_(
                [
                    "student",
                    "teacher",
                ]
            ),
        )
        .order_by(
            GroupMember.id.asc(),
        )
        .all()
    )


def get_available_public_group_members(
    db: Session,
    group_id: int,
):
    group = get_public_group_by_id(
        db,
        group_id,
    )

    if group is None:
        return None

    return get_available_group_members(
        db,
        group_id,
    )


def add_group_member(
    db: Session,
    group_id: int,
    user_id: int,
    role: str = "member",
):
    member = GroupMember(
        group_id=group_id,
        user_id=user_id,
        role=role,
    )

    try:
        db.add(
            member,
        )

        db.commit()

        db.refresh(
            member,
        )

        return member

    except Exception:
        db.rollback()
        raise


def remove_group_member(
    db: Session,
    member: GroupMember,
):
    try:
        db.delete(
            member,
        )

        db.commit()

    except Exception:
        db.rollback()
        raise


def update_group(
    db: Session,
    group: StudyGroup,
    data: GroupUpdate,
):
    values = data.model_dump(
        exclude_unset=True,
    )

    for field, value in values.items():
        setattr(
            group,
            field,
            value,
        )

    try:
        db.commit()

        db.refresh(
            group,
        )

        return group

    except Exception:
        db.rollback()
        raise


def update_group_member_role(
    db: Session,
    member: GroupMember,
    role: str,
):
    member.role = role

    try:
        db.commit()

        db.refresh(
            member,
        )

        return member

    except Exception:
        db.rollback()
        raise


def delete_group(
    db: Session,
    group: StudyGroup,
):
    try:
        db.delete(
            group,
        )

        db.commit()

    except Exception:
        db.rollback()
        raise


def is_group_public(
    db: Session,
    group_id: int,
) -> bool:
    group = (
        db.query(
            StudyGroup,
        )
        .filter(
            StudyGroup.id ==
            group_id,
            StudyGroup.is_private.is_(
                False,
            ),
            StudyGroup.status ==
            "active",
        )
        .first()
    )

    return group is not None


def is_group_admin(
    db: Session,
    group_id: int,
    user_id: int,
):
    member = get_group_member(
        db,
        group_id,
        user_id,
    )

    if member is None:
        return False

    return member.role in [
        "owner",
        "admin",
    ]


def is_group_owner(
    db: Session,
    group_id: int,
    user_id: int,
):
    member = get_group_member(
        db,
        group_id,
        user_id,
    )

    if member is None:
        return False

    return member.role == "owner"


def create_group_join_request(
    db: Session,
    group_id: int,
    user_id: int,
):
    request = GroupJoinRequest(
        group_id=group_id,
        user_id=user_id,
        status="pending",
    )

    try:
        db.add(
            request,
        )

        db.commit()

        db.refresh(
            request,
        )

        return request

    except Exception:
        db.rollback()
        raise


def get_group_join_request(
    db: Session,
    group_id: int,
    user_id: int,
):
    return (
        db.query(
            GroupJoinRequest,
        )
        .filter(
            GroupJoinRequest.group_id ==
            group_id,
            GroupJoinRequest.user_id ==
            user_id,
        )
        .first()
    )


def get_group_join_request_by_id(
    db: Session,
    request_id: int,
):
    return (
        db.query(
            GroupJoinRequest,
        )
        .filter(
            GroupJoinRequest.id ==
            request_id,
        )
        .first()
    )


def get_group_join_requests(
    db: Session,
    group_id: int,
):
    return (
        db.query(
            GroupJoinRequest,
        )
        .filter(
            GroupJoinRequest.group_id ==
            group_id,
            GroupJoinRequest.status ==
            "pending",
        )
        .order_by(
            GroupJoinRequest.created_at.asc(),
        )
        .all()
    )


def accept_group_join_request(
    db: Session,
    request: GroupJoinRequest,
):
    member = GroupMember(
        group_id=request.group_id,
        user_id=request.user_id,
        role="member",
    )

    request.status = "accepted"

    try:
        db.add(
            member,
        )

        db.commit()

        db.refresh(
            member,
        )

        return member

    except Exception:
        db.rollback()
        raise


def reject_group_join_request(
    db: Session,
    request: GroupJoinRequest,
):
    request.status = "rejected"

    try:
        db.commit()

        db.refresh(
            request,
        )

        return request

    except Exception:
        db.rollback()
        raise