from fastapi import HTTPException, Header
import jwt

def auth_middleware(x_auth_token = Header()): # Header() 用于从 HTTP 请求的头部获取数据
    try:
        # get the user token from the headers
        if not x_auth_token:
            raise HTTPException(401, 'No auth token, access denied!')
        # decode the token
        verified_token = jwt.decode(x_auth_token, 'password_key', ['HS256']) # 返回的类型是 Dict
        # jwt.encode({'id': user_db.id}, 'password_key') 那么解码之后是 verified_token = {'id': user_db.id}

        if not verified_token:
            raise HTTPException(401, 'Token verification failed, authorization denied!')
        # get the id from the token
        uid = verified_token.get('id') # 使用 .get() 方法之后可以有效避免 不存在的情况 (返回 null)
        return {'uid': uid, 'token': x_auth_token} 
        # postgres database get the user info
    except jwt.PyJWTError:
        raise HTTPException(401, 'Token is not valid, authorization failed.') # 针对 token 不匹配的时候会造成整个app崩溃的情况 使用 try-except 处理