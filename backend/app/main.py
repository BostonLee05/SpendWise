from datetime import datetime

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.auth import create_access_token, get_current_user, hash_password, verify_password
from app.database import get_db, init_db
from app.models import Expense, User
from app.schemas import (
    BudgetUpdate,
    CategoryTotal,
    ExpenseCreate,
    ExpenseOut,
    ExpenseUpdate,
    Token,
    UserLogin,
    UserOut,
    UserRegister,
)

app = FastAPI(title="SpendWise API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.get("/")
def read_root():
    return {"app": "SpendWise API", "status": "running"}


@app.post("/auth/register", response_model=UserOut)
def register_user(payload: UserRegister, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=payload.name,
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        user_type=payload.user_type,
        monthly_income=payload.monthly_income,
        monthly_budget=payload.monthly_budget,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@app.post("/auth/login", response_model=Token)
def login_user(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    access_token = create_access_token({"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@app.get("/dashboard")
def dashboard(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    expenses = db.query(Expense).filter(Expense.user_id == current_user.id).all()
    total_spent = sum(item.amount for item in expenses)
    category_totals: dict[str, float] = {}
    for item in expenses:
        category_totals[item.category] = category_totals.get(item.category, 0.0) + item.amount

    return {
        "monthly_income": current_user.monthly_income,
        "monthly_budget": current_user.monthly_budget,
        "total_spent": total_spent,
        "remaining": current_user.monthly_income - total_spent,
        "budget_remaining": current_user.monthly_budget - total_spent,
        "expenses": [{
            "id": item.id,
            "amount": item.amount,
            "category": item.category,
            "description": item.description,
            "frequency": item.frequency,
            "expense_date": item.expense_date,
        } for item in expenses],
        "category_totals": [
            {"category": category, "total": total}
            for category, total in sorted(category_totals.items(), key=lambda entry: entry[1], reverse=True)
        ],
    }


@app.put("/budget", response_model=UserOut)
def update_budget(
    payload: BudgetUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.monthly_budget = payload.monthly_budget
    db.commit()
    db.refresh(current_user)
    return current_user


@app.get("/expenses", response_model=list[ExpenseOut])
def list_expenses(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Expense).filter(Expense.user_id == current_user.id).order_by(Expense.expense_date.desc()).all()


@app.post("/expenses", response_model=ExpenseOut)
def create_expense(payload: ExpenseCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    expense = Expense(
        user_id=current_user.id,
        amount=payload.amount,
        category=payload.category,
        description=payload.description,
        frequency=payload.frequency,
        expense_date=payload.expense_date or datetime.utcnow(),
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


@app.put("/expenses/{expense_id}", response_model=ExpenseOut)
def update_expense(
    expense_id: int,
    payload: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.user_id == current_user.id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    expense.amount = payload.amount
    expense.category = payload.category
    expense.description = payload.description
    expense.frequency = payload.frequency
    expense.expense_date = payload.expense_date or expense.expense_date
    db.commit()
    db.refresh(expense)
    return expense


@app.delete("/expenses/{expense_id}")
def delete_expense(expense_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.user_id == current_user.id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    db.delete(expense)
    db.commit()
    return {"message": "Expense deleted successfully"}
