import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../routes/app_routes.dart';
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
      ),
    );
  }

  final Dio dio;
  final LocalStorage _storage;

  ApiException _toApiException(DioException error) {
    final data = error.response?.data;
    final detail = data is Map && data['detail'] != null
        ? data['detail'].toString()
        : error.message ?? 'Ошибка сети';
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      _handleSessionExpired();
    }
    return ApiException(statusCode, detail);
  }

  // A 401 used to fail every auth-required action (status changes, weight
  // entry, catalog edits) with zero feedback — the screen just did nothing.
  // Surface it and bounce back to login instead of failing silently. The
  // token-null check also de-dupes bursts of parallel requests failing
  // together (e.g. Future.wait) — only the first clears it.
  void _handleSessionExpired() {
    if (_storage.token == null) return;
    _storage.clearToken();
    Get.offAllNamed(AppRoutes.modeSelect);
    Get.snackbar(
      'Сессия истекла',
      'Войдите снова, чтобы продолжить.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      return await dio.get<T>(path, queryParameters: query);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<List<int>> getBytes(String path) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<T>> post<T>(String path, {Object? data}) async {
    try {
      return await dio.post<T>(path, data: data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) async {
    try {
      return await dio.patch<T>(path, data: data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }
}
