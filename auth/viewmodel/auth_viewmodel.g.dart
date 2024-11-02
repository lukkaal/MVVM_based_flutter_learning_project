// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authViewModelHash() => r'd1cc6ede5346ce9360df21bde8fd5f77eea918f0';

/// See also [AuthViewModel].
@ProviderFor(AuthViewModel)
final authViewModelProvider = // 如果 authViewModelProvider 使用了 autoDispose，那么在每次 ref.watch 或 ref.read 时都会创建新的实例 实例会在离开当前 scope 后自动销毁
    AutoDisposeNotifierProvider<AuthViewModel, AsyncValue<UserModel>?>.internal(
  AuthViewModel.new,
  name: r'authViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthViewModel = AutoDisposeNotifier<AsyncValue<UserModel>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
