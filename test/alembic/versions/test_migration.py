"""Test migration

Revision ID: test123
Revises:
Create Date: 2025-03-16

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "test123"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "test_table",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade():
    op.drop_table("test_table")
