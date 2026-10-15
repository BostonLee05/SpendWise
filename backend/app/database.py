from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.config import DATABASE_URL
from app.models import Base

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db() -> None:
    Base.metadata.create_all(bind=engine)

    if DATABASE_URL.startswith("sqlite"):
        with engine.begin() as connection:
            columns = connection.exec_driver_sql("PRAGMA table_info(users)").fetchall()
            has_monthly_budget = any(column[1] == "monthly_budget" for column in columns)
            if not has_monthly_budget:
                connection.exec_driver_sql("ALTER TABLE users ADD COLUMN monthly_budget FLOAT DEFAULT 0.0")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
