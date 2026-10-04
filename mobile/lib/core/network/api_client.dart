import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../errors/failures.dart';

/// Centralized API HTTP client wrapper around Dio with single-shared session token management.
class ApiClient {
  static ApiClient? _sharedInstance;

  /// Returns the global shared ApiClient instance to guarantee session token continuity across all features.
  static ApiClient get instance => _sharedInstance ??= ApiClient();

  /// Sets or overrides the global shared instance (useful for testing or custom configuration).
  static void setSharedInstance(ApiClient client) {
    _sharedInstance = client;
  }

  late final Dio _dio;
  String _baseUrl;
  String? _authToken;

  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? AppConfig.defaultBaseUrl {
    _authToken = _sharedInstance?._authToken;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_authToken != null && _authToken!.isNotEmpty)
            'Authorization': 'Bearer $_authToken',
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
  String? get authToken => _authToken;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }

    // Sync with singleton if this instance is distinct
    if (_sharedInstance != null && _sharedInstance != this) {
      _sharedInstance!._authToken = token;
      if (token != null && token.isNotEmpty) {
        _sharedInstance!._dio.options.headers['Authorization'] = 'Bearer $token';
      } else {
        _sharedInstance!._dio.options.headers.remove('Authorization');
      }
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

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
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

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
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
          'Request timed out connecting to ${_dio.options.baseUrl}. Please check your connection or backend server.',
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
            if (first is Map && first.containsKey('msg')) {
              errorMessage = first['msg'].toString();
            } else {
              errorMessage = detail.toString();
            }
          }
        } else if (data is String) {
          errorMessage = data;
        }

        // Semantic error messaging
        if (statusCode == 401) {
          if (errorMessage == 'Invalid or expired access token.') {
            errorMessage = 'Session expired. Please sign in again.';
          }
        } else if (statusCode == 403) {
          if (errorMessage == 'Not authenticated') {
            errorMessage = 'Authentication required. Please sign in to access this feature.';
          }
        } else if (statusCode == 404) {
          if (errorMessage.startsWith('Server error')) {
            errorMessage = 'The requested healthcare record was not found.';
          }
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
