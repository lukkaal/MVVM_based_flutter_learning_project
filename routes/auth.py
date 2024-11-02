import uuid
import bcrypt
from fastapi import Depends, HTTPException, Header
from database import get_db
from middleware.auth_middleware import auth_middleware
from models.user import User
from pydantic_schemas.user_create import UserCreate
from fastapi import APIRouter
from sqlalchemy.orm import Session
from pydantic_schemas.user_login import UserLogin
import jwt
from sqlalchemy.orm import joinedload
router = APIRouter()

# 当你在路由函数中定义一个参数为 Pydantic 模型时 FastAPI 会自动解析请求体中的 JSON 数据 并将其转换为该模型的实例 ( UserCreate/UserLogin-BaseModel)

@router.post('/signup', status_code=201)
def signup_user(user: UserCreate, db: Session=Depends(get_db)):
    # check if the user already exists in db
    user_db = db.query(User).filter(User.email == user.email).first()

    if user_db:
        raise HTTPException(400, 'User with the same email already exists!')
    
    hashed_pw = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt())
    user_db = User(id=str(uuid.uuid4()), email=user.email, password=hashed_pw, name=user.name)
    
    # add the user to the db
    db.add(user_db)
    db.commit()
    db.refresh(user_db)

    return user_db # 返回类的实例对象

@router.post('/login') # 封装了调用数据库的代码在 db
def login_user(user: UserLogin, db: Session = Depends(get_db)): # UserLogin 是一个 Pydantic 模型 定义了 email 和 password 字段 然后 FastAPI 会根据这个模型自动验证和解析请求体的内容
    #FastAPI 会自动读取请求的 body 部分 它会将 JSON 数据解析为一个 Python 字典 然后尝试将这个字典转换为在路由函数中定义的 Pydantic 模型的实例
    # check if a user with same email already exist
    user_db = db.query(User).filter(User.email == user.email).first() # user_db 是 User 类的实例 

    if not user_db:
        raise HTTPException(400, 'User with this email does not exist!') # fastapi 会返回这段代码作为 body
    
    # password matching or not
    is_match = bcrypt.checkpw(user.password.encode(), user_db.password)
    
    if not is_match:
        raise HTTPException(400, 'Incorrect password!')
    
    # token 是 str 类型的变量 
    token = jwt.encode({'id': user_db.id}, 'password_key') # 创建一个 JWT 之后会使用到 token 对用户的信息进行 verify
    
    return {'token': token, 'user': user_db} # 返回 Map 类型

@router.get('/')
def current_user_data(db: Session=Depends(get_db), 
                      user_dict = Depends(auth_middleware)):
    user = db.query(User).filter(User.id == user_dict['uid']).options(
        joinedload(User.favorites)
    ).first()

    if not user:
        raise HTTPException(404, 'User not found!')
    
    return user