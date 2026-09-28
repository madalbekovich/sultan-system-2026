import 'package:dio/dio.dart';

import 'config.dart';
import 'storage.dart';

/// Thrown for any non-2xx API response; carries the server's detail message
/// so screens can show something more useful than "DioException".
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._storage)
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final data = error.response?.data;
          final detail = data is Map && data['detail'] != null
              ? data['detail'].toString()
              : error.message ?? 'Network error';
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: ApiException(error.response?.statusCode, detail),
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  final Dio dio;
  final LocalStorage _storage;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return dio.get<T>(path, queryParameters: query);
  }

  Future<List<int>> getBytes(String path) async {
    final response = await dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return dio.patch<T>(path, data: data);
  }
}
