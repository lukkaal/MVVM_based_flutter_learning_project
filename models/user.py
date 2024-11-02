from sqlalchemy import TEXT, VARCHAR, Column, LargeBinary
from models.base import Base
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = 'users' # 在名字为 'user' 的表当中存储 User 的实例对象

    id = Column(TEXT, primary_key=True) # 适合存储长描述
    name = Column(VARCHAR(100)) # 适合存储短文本
    email = Column(VARCHAR(100))
    password = Column(LargeBinary)

    favorites = relationship('Favorite', back_populates='user')