"""Record the private share that fulfills a teacher material request.

Revision ID: b937teacherprivateshare
Revises: b936requestforward
"""
from alembic import op
import sqlalchemy as sa

revision = 'b937teacherprivateshare'
down_revision = 'b936requestforward'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('teacher_material_requests', sa.Column('fulfilled_share_id', sa.Integer(), nullable=True))
    op.create_index('ix_teacher_material_requests_fulfilled_share_id', 'teacher_material_requests', ['fulfilled_share_id'])
    op.create_foreign_key('fk_teacher_material_requests_fulfilled_share', 'teacher_material_requests', 'material_shares', ['fulfilled_share_id'], ['id'], ondelete='SET NULL')


def downgrade():
    op.drop_constraint('fk_teacher_material_requests_fulfilled_share', 'teacher_material_requests', type_='foreignkey')
    op.drop_index('ix_teacher_material_requests_fulfilled_share_id', table_name='teacher_material_requests')
    op.drop_column('teacher_material_requests', 'fulfilled_share_id')
