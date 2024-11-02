import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/models/user_model.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/auth/repositories/auth_remote_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel { // AutoDisposeNotifier<AsyncValue<UserModel>?> 说明这个类会用来管理一个 AsyncValue<UserModel>? 类型的状态 state
  late AuthRemoteRepository _authRemoteRepository; // 定义 AuthRemoteRepository (class) 类型的变量 
  late AuthLocalRepository _authLocalRepository; // late 允许声明变量时不立即赋值 但确保在首次使用前完成赋值
  late CurrentUserNotifier _currentUserNotifier;

  @override
  AsyncValue<UserModel>? build() { // 可不用声明直接在类内调用到 ref 方法
    _authRemoteRepository = ref.watch(authRemoteRepositoryProvider); // 每次被 authRemoteRepositoryProvider 调用的时候 返回类的实例对象
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _currentUserNotifier = ref.watch(currentUserNotifierProvider.notifier);
    return null;
  }

  Future<void> initSharedPreferences() async { // 在 main.dart 中调用该初始化 
    await _authLocalRepository.init(); // 因为存储在本地必须要调用到 SharedPreferences.getInstance() 而这个是异步过程需要调用 init 方法为 _sharedPreferences 初始化
  } // 本质是为 _authLocalRepository 实例中的变量 _sharedPreferences 初始化实例 因为下文中 _loginSuccess 调用的 _authLocalRepository 类实例中的方法当中 会用到 _sharedPreferences

  Future<void> signUpUser({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final res = await _authRemoteRepository.signup( // 在 AuthViewModel (class) 中调用 authRemoteRepository 实例对象中的函数与后端做交互
      name: name,
      email: email,
      password: password,
    );

    final val = switch (res) {
      Left(value: final l) => state = AsyncValue.error(
          l.message, // 返回值是 AppFailure 实例对象 其中的属性 this.message 包含有产生错误的信息 确定是 String 类型
          StackTrace.current,
        ), 
      Right(value: final r) => state = AsyncValue.data(r),
    };
    print(val);
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final res = await _authRemoteRepository.login(
      email: email,
      password: password,
    ); // 返回值类型是 <Either<AppFailure, UserModel>>

    final val = switch (res) {
      Left(value: final l) => state = AsyncValue.error(
          l.message, // 是 AsyncValue.error 的 error 主要属性
          StackTrace.current, // stackTrace 用于存储错误发生时的堆栈跟踪信息 可以帮助定位错误发生的代码位置
        ),
      Right(value: final r) => _loginSuccess(r), // 正确的情况下 value 是 UserModel 类型的实例对象
    };
    print(val);
  }

  AsyncValue<UserModel>? _loginSuccess(UserModel user) { // state 的类型在最开始就被定义好了是 AsyncValue<UserModel>?
    _authLocalRepository.setToken(user.token); // 调用 _authLocalRepository 实例对象中的方法 将 token 存储到本地(client) 
    _currentUserNotifier.addUser(user); // 调用实例对象的函数 .addUser() 将 UserModel 类型的实例对象 设置为 _currentUser 的 state 并且 keepAlive 会设置为单一实例进而长期有效不会 dispose
    return state = AsyncValue.data(user); // 返回值是更新 state 的状态 
  }

  Future<UserModel?> getData() async { // 在用户之后打开 app 时 不用再次 signin 而是使用 token 获取到用户信息
    state = const AsyncValue.loading();
    final token = _authLocalRepository.getToken(); // 从本地获取到 token

    if (token != null) {
      final res = await _authRemoteRepository.getCurrentUserData(token); // 使用 token 得到 UserModel 类的实例对象
      final val = switch (res) {
        Left(value: final l) => state = AsyncValue.error(
            l.message,
            StackTrace.current,
          ),
        Right(value: final r) => _getDataSuccess(r),
      };

      return val.value;
    }

    return null; // 如果使用 _authLocalRepository.getToken() 得到的值是 null 的话 说明此时本地没有存过 token 即用户是第一次使用 所以返回 null
  }

  AsyncValue<UserModel> _getDataSuccess(UserModel user) {
    _currentUserNotifier.addUser(user); // 使用 token 直接登录 更新用户信息
    return state = AsyncValue.data(user); // UI 会根据状态不同 切换不同的界面 所以返回值类型是 AsyncValue
  }
}
