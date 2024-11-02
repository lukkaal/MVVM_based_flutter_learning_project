import 'dart:convert';
import 'dart:io';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'home_repository.g.dart';

@riverpod
HomeRepository homeRepository(HomeRepositoryRef ref) {
  return HomeRepository();
}

class HomeRepository {
  Future<Either<AppFailure, String>> uploadSong({
    required File selectedAudio,
    required File selectedThumbnail,
    required String songName,
    required String artist,
    required String hexCode,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest( // 使用 http 库的 MultipartRequest 创建一个支持多部分上传的 POST 请求
        'POST',
        Uri.parse('${ServerConstant.serverURL}/song/upload'),
      );

      request
        ..files.addAll( // 用于添加要上传的文件 每个文件都被编码为多部分文件内容（multipart/form-data）适合发送文件数据 比如音频文件 图片文件等
          [ // 对应到 fastapi 当中的 File(...)
            await http.MultipartFile.fromPath('song', selectedAudio.path), // fromPath 方法使用文件路径创建 MultipartFile 实例
            await http.MultipartFile.fromPath(
                'thumbnail', selectedThumbnail.path), // 调用 File 对象的 .path 属性 返回路径
          ],
        )
        ..fields.addAll( // 用于添加普通的表单字段 每个字段都以文本格式发送 适用于需要发送简单的文本数据或元数据
          { // 对应到 fastapi 当中的 Form(...)
            'artist': artist,
            'song_name': songName,
            'hex_code': hexCode,
          },
        )
        ..headers.addAll(
          {
            'x-auth-token': token,
          },
        );

      final res = await request.send(); // 返回类型是 http.StreamedResponse

      if (res.statusCode != 201) {
        return Left(AppFailure(await res.stream.bytesToString())); // Future<String> 类型 await 是因为将这些字节转换成字符串 这一过程可能需要一些时间
      }

      return Right(await res.stream.bytesToString());
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> getAllSongs({ // 和 UserModel 类似 SongModel 是一个数据类 getAllSongs 返回的是一个列表
    required String token,
  }) async {
    try {
      final res = await http
          .get(Uri.parse('${ServerConstant.serverURL}/song/list'), headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      });
      var resBodyMap = jsonDecode(res.body); // 定义 resBodyMap 是 var 类型的变量 
      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>; // 如果不是正常的返回值 那么将 resBodyMap 强制转换 Map<String, dynamic> 返回键 'detail' 对应的信息
        return Left(AppFailure(resBodyMap['detail'])); 
      }
      resBodyMap = resBodyMap as List; // 如果是正常的返回值 那么将 resBodyMap 强制转换c List

      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, bool>> favSong({
    required String token,
    required String songId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ServerConstant.serverURL}/song/favorite'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(
          {
            "song_id": songId,
          },
        ),
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }

      return Right(resBodyMap['message']);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> getFavSongs({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/song/list/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }
      resBodyMap = resBodyMap as List;

      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map['song']));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
