import 'dart:developer';

import 'package:dio/dio.dart';

abstract class IStyleTransferClient {
  Future<Response?> getStylizers();
  Future<Response?> selectStylizer(String selectedStylizerFileName, String contentImageBase64);
}

class DioClient implements IStyleTransferClient {
  static DioClient? _instance;
  late final Dio _dio;

  final baseUrl = 'http://10.0.2.2:8080';

  DioClient._(Dio dio) : _dio = dio;

  factory DioClient({required Dio dio}) {
    return _instance ??= DioClient._(dio);
  }

  @override
  Future<Response?> getStylizers() async {
    try {
      return _dio.get<Map<String, dynamic>>('$baseUrl/getStylizers');
    } catch (e) {
      log(e.toString(), error: e);
      return null;
    }
  }

  @override
  Future<Response?> selectStylizer(String selectedStylizerFileName, String contentImageBase64) async {
    try {
      return _dio.post('$baseUrl/postStylizer', data: {
        'selected_stylizer': selectedStylizerFileName,
        'content_image_base64': contentImageBase64,
      });
    } catch (e) {
      log(e.toString(), error: e);
      return null;
    }
  }
}
