from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)
    user_type: str = "employed"
    monthly_income: float = 0.0
    monthly_budget: float = 0.0


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)


class UserOut(BaseModel):
    id: int
    name: str
    email: EmailStr
    user_type: str
    monthly_income: float
    monthly_budget: float
    created_at: datetime

    class Config:
        from_attributes = True


class ExpenseCreate(BaseModel):
    amount: float = Field(..., gt=0)
    category: str = Field(..., min_length=1)
    description: str = Field(..., min_length=1)
    frequency: str = "one_time"
    expense_date: Optional[datetime] = None


class ExpenseUpdate(ExpenseCreate):
    pass


class ExpenseOut(BaseModel):
    id: int
    user_id: int
    amount: float
    category: str
    description: str
    frequency: str
    expense_date: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class BudgetUpdate(BaseModel):
    monthly_budget: float = Field(..., ge=0)


class CategoryTotal(BaseModel):
    category: str
    total: float


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
