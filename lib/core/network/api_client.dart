import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _uuid = Uuid();
  late final Dio _dio = _initDio();

  /// Session state
  String? authToken;
  String currentUserId = '2c124cb1-5d9c-4860-934c-6d8174548000'; // Default Dev R&D User ID

  Dio get client => _dio;

  Dio _initDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.gatewayBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Always ensure the base URL matches the current configuration
          options.baseUrl = AppConfig.gatewayBaseUrl;

          // Inject User Identity
          options.headers['X-User-Id'] = currentUserId;

          // Inject Bearer token if present
          if (authToken != null && authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }

          // Inject Idempotency-Key for all mutating requests (POST, PUT, PATCH, DELETE)
          final method = options.method.toUpperCase();
          if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
            if (!options.headers.containsKey('Idempotency-Key')) {
              options.headers['Idempotency-Key'] = _uuid.v4();
            }
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Log or format standard HTTP status codes
          // 400: Validation error
          // 401: Unauthorized
          // 409: Concurrency conflict (RowVersion mismatch or duplicate key)
          // 410: Draft expired (30m TTL)
          // 422: Recipe version locked (Approved/Archived)
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
