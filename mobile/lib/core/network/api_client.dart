import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../errors/failures.dart';

/// Centralized API HTTP client wrapper around Dio.
class ApiClient {
  late final Dio _dio;
  String _baseUrl;

  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? AppConfig.defaultBaseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logging interceptor for debugging (strictly redacts sensitive credentials)
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[HTTP Request] ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('[HTTP Response] ${response.statusCode} from ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            debugPrint('[HTTP Error] ${e.type} for ${e.requestOptions.uri}: ${e.message}');
            return handler.next(e);
          },
        ),
      );
    }
  }

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  void setAuthToken(String? token) {
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          'Request timed out connecting to ${_dio.options.baseUrl}. Please check network or backend.',
        );
      case DioExceptionType.connectionError:
        return NetworkFailure(
          'Cannot connect to backend at ${_dio.options.baseUrl}. Ensure server is running.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String errorMessage = 'Server error ($statusCode)';

        if (data is Map && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String) {
            errorMessage = detail;
          } else if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            errorMessage = first['msg'] ?? detail.toString();
          }
        } else if (data is String) {
          errorMessage = data;
        }

        return ServerFailure(
          errorMessage,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const NetworkFailure('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('SSL certificate validation failed.');
      case DioExceptionType.unknown:
      default:
        return NetworkFailure(
          error.message ?? 'Unknown network communication error.',
        );
    }
  }
}
