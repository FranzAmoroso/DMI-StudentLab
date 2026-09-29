"""Durable temporary Blob transfer jobs. No changes to existing materials or user data."""
from alembic import op
import sqlalchemy as sa
revision='slt01blob_transfers'
down_revision='b948notice_listing_source'
branch_labels=None
depends_on=None

def upgrade():
    op.create_table('temporary_storage_transfers',
        sa.Column('id',sa.String(36),primary_key=True),sa.Column('actor_id',sa.Integer(),nullable=False),
        sa.Column('filename',sa.String(180),nullable=False),sa.Column('mime_type',sa.String(150),nullable=False),
        sa.Column('size',sa.BigInteger(),nullable=False),sa.Column('sha256',sa.String(64),nullable=False),
        sa.Column('destination',sa.String(10),nullable=False),sa.Column('path_segments',sa.JSON(),nullable=False),
        sa.Column('blob_path',sa.String(500),nullable=False,unique=True),sa.Column('state',sa.String(20),nullable=False),
        sa.Column('upload_until',sa.DateTime()),sa.Column('attempts',sa.Integer(),nullable=False),sa.Column('lease_id',sa.String(36)),sa.Column('lease_until',sa.DateTime()),
        sa.Column('result_id',sa.String(150)),sa.Column('error',sa.String(300)),sa.Column('cleaned',sa.Boolean(),nullable=False),
        sa.Column('created_at',sa.DateTime(),nullable=False),sa.Column('expires_at',sa.DateTime(),nullable=False))
    op.create_index('ix_temporary_storage_transfers_actor_id','temporary_storage_transfers',['actor_id'])
    op.create_index('ix_temporary_storage_transfers_state','temporary_storage_transfers',['state'])

def downgrade():
    op.drop_table('temporary_storage_transfers')
