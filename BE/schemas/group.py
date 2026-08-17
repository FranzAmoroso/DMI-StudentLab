from datetime import datetime

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
)


class GroupCreate(BaseModel):
    name: str

    description: str | None = None

    subject_id: int | None = None

    university: str

    department: str

    course: str

    is_private: bool = False

    created_by: int


class GroupUpdate(BaseModel):
    name: str | None = None

    description: str | None = None

    subject_id: int | None = None

    university: str | None = None

    department: str | None = None

    course: str | None = None

    is_private: bool | None = None


class GroupMemberResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    user_id: int

    role: str

    joined_at: datetime


class PublicGroupUserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    first_name: str

    last_name: str

    role: str

    university: str | None

    department: str | None

    course: str | None

    teacher_verification_status: str

    available: bool

    available_for_help: bool

    available_for_private_lessons: bool


class PublicGroupMemberResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    user_id: int

    role: str

    joined_at: datetime

    user: PublicGroupUserResponse


class GroupResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    name: str

    description: str | None

    subject_id: int | None

    university: str

    department: str

    course: str

    is_private: bool

    created_by: int

    created_at: datetime


class PublicGroupResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    name: str

    description: str | None

    subject_id: int | None

    university: str

    department: str

    course: str

    created_at: datetime


class GroupDetailResponse(
    GroupResponse,
):
    members: list[
        GroupMemberResponse
    ] = Field(
        default_factory=list,
    )


class PublicGroupDetailResponse(
    PublicGroupResponse,
):
    members: list[
        PublicGroupMemberResponse
    ] = Field(
        default_factory=list,
    )


class AddGroupMemberRequest(BaseModel):
    user_id: int

    role: str = "member"


class ChangeGroupMemberRoleRequest(BaseModel):
    role: str


class GroupJoinRequestCreate(BaseModel):
    user_id: int


class GroupJoinRequestResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    group_id: int

    user_id: int

    status: str

    created_at: datetime


class JoinGroupResponse(BaseModel):
    joined: bool

    pending: bool

    message: str