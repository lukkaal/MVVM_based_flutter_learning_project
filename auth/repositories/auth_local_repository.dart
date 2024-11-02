import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_local_repository.g.dart';

@Riverpod(keepAlive: true) // keepAlive 之后 每次调用到 AuthLocalRepository 都会调用同一个实例对象
AuthLocalRepository authLocalRepository(AuthLocalRepositoryRef ref) {
  return AuthLocalRepository();
}

class AuthLocalRepository { // 主要负责对 SharedPreferences 的封装 方便应用程序存储和获取用户的认证令牌（token）
  late SharedPreferences _sharedPreferences; // late 在使用前必须被初始化 SharedPreferences 用于访问本地存储

  Future<void> init() async { // 调用 SharedPreferences.getInstance() 初始化 _sharedPreferences 以便该类能够使用本地存储
    _sharedPreferences = await SharedPreferences.getInstance(); // _sharedPreferences 需要异步初始化 在类实例化时并不能直接赋值
  }

  void setToken(String? token) {
    if (token != null) { // 使用 _sharedPreferences.setString('x-auth-token', token) 将 token 值存储在本地存储中 并以 'x-auth-token' 为键保存
      _sharedPreferences.setString('x-auth-token', token);
    }
  } // 便于在用户重新打开应用时 从本地获取上次登录的令牌 维持登录状态。

  String? getToken() {
    return _sharedPreferences.getString('x-auth-token');
  }
} // 获取已存储的 token 以便在用户重新打开应用时检查登录状态
