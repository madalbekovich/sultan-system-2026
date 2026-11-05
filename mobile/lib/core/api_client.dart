import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../routes/app_routes.dart';
import 'config.dart';
import 'connectivity_service.dart';
import 'storage.dart';

/// Which "stale data" message a failed request should surface. A failed
/// request alone can't tell these apart (a timeout looks the same whether
/// the phone has no signal or the backend is just slow) — that's why this
/// combines the Dio error type with the device's actual radio status from
/// [ConnectivityService] rather than guessing from the exception alone.
enum ApiFailureKind { network, server }

/// Thrown for any non-2xx API response; carries the server's detail message
/// so screens can show something more useful than "DioException".
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, this.kind);

  final int? statusCode;
  final String message;
  final ApiFailureKind kind;

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
    return ApiException(statusCode, detail, _classify(error));
  }

  // A response (even a 4xx/5xx one) proves the device reached the server,
  // so that's always a server-side problem. Otherwise trust the device's
  // actual radio status over the exception type — a connectionError can
  // also mean a captive portal or a dead DNS entry while Wi-Fi still
  // reads "connected", and a timeout can just as easily be a slow backend
  // as no signal at all.
  ApiFailureKind _classify(DioException error) {
    if (error.response != null) return ApiFailureKind.server;
    final online = Get.isRegistered<ConnectivityService>()
        ? Get.find<ConnectivityService>().isOnline.value
        : true;
    if (!online) return ApiFailureKind.network;
    return error.type == DioExceptionType.connectionError
        ? ApiFailureKind.network
        : ApiFailureKind.server;
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

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await dio.delete<T>(path);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }
}
