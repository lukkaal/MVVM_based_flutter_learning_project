import uuid
from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session
from database import get_db
from middleware.auth_middleware import auth_middleware
import cloudinary
import cloudinary.uploader
from models.favorite import Favorite
from models.song import Song
from pydantic_schemas.favorite_song import FavoriteSong
from sqlalchemy.orm import joinedload

router = APIRouter()

cloudinary.config( 
    cloud_name = "dsomyc4hv", 
    api_key = "433823972159394",
    api_secret = "i7gUk6UOSuARwXHRe6Wz-6Uu7uo",
    secure=True
)

@router.post('/upload', status_code=201)
def upload_song(song: UploadFile = File(...), # File(...) 指定该参数来自客户端上传的文件数据 并可以获取文件内容及其相关信息
                thumbnail: UploadFile = File(...), 
                artist: str = Form(...), # Form(...) 告诉框架将该参数的数据从表单请求体中提取出来  
                song_name: str = Form(...), 
                hex_code: str = Form(...),
                db: Session = Depends(get_db),
                auth_dict = Depends(auth_middleware)):
    song_id = str(uuid.uuid4())
    song_res = cloudinary.uploader.upload(song.file, resource_type='auto', folder=f'songs/{song_id}') # song_res 的类型是 dict 返回的字典包括文件上传后的 URL/ 文件的公共 ID/ 版本信息/ 资源类型等信息
    thumbnail_res = cloudinary.uploader.upload(thumbnail.file, resource_type='image', folder=f'songs/{song_id}')
    
    new_song = Song( # 新建 Song 类的实例对象
        id=song_id,
        song_name=song_name,
        artist=artist,
        hex_code=hex_code,
        song_url=song_res['url'], # 因为文件太大 所以选择存储 url 到 postgres 当中
        thumbnail_url = thumbnail_res['url'],
    )

    db.add(new_song) # Song 是 Base 类的拓展 将实例对象存到对应的表当中
    db.commit()
    db.refresh(new_song)
    return new_song

@router.get('/list')
def list_songs(db: Session=Depends(get_db), 
               auth_details=Depends(auth_middleware)):
    songs = db.query(Song).all()
    return songs # 返回值会在报文的 body 当中

@router.post('/favorite')
def favorite_song(song: FavoriteSong, 
                  db: Session=Depends(get_db), 
                  auth_details=Depends(auth_middleware)):
    # song is already favorited by the user
    user_id = auth_details['uid']

    fav_song = db.query(Favorite).filter(Favorite.song_id == song.song_id, Favorite.user_id == user_id).first()

    if fav_song:
        db.delete(fav_song)
        db.commit()
        return {'message': False}
    else:
        new_fav = Favorite(id=str(uuid.uuid4()), song_id=song.song_id, user_id=user_id)
        db.add(new_fav)
        db.commit()
        return {'message': True}
    
@router.get('/list/favorites')
def list_fav_songs(db: Session=Depends(get_db), 
               auth_details=Depends(auth_middleware)):
    user_id = auth_details['uid']
    fav_songs = db.query(Favorite).filter(Favorite.user_id == user_id).options(
        joinedload(Favorite.song),
    ).all()
    
    return fav_songs