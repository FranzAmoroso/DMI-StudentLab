from datetime import datetime

from pydantic import (
    BaseModel,
    ConfigDict,
)


class GroupMaterialResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    group_id: int

    uploaded_by: int

    original_name: str

    mime_type: str

    size: int

    created_at: datetime