import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/interceptors/base_url_interceptor.dart';
import '../../core/interceptors/header_interceptor.dart';
import '../../core/interceptors/logging_interceptor.dart';
import '../../core/managers/session_manager.dart';
import '../../models/responses/base/base_response.dart';
import '../../models/responses/base/error_response.dart';
import '../../models/responses/base/header_response.dart';
import 'response_state.dart';

class ApiClient {
  final BaseUrlInterceptor _baseUrlInterceptor;
  final HeaderInterceptor _headerInterceptor;
  final LoggingInterceptor _loggingInterceptor;
  final http.Client _httpClient;
  static const Duration _timeout = Duration(seconds: 60);

  ApiClient(
    this._baseUrlInterceptor,
    this._headerInterceptor,
    this._loggingInterceptor, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<ResponseState<T>> get<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(
      Uri.parse(path).replace(queryParameters: queryParameters),
      path,
    );
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);

    _loggingInterceptor.logRequest(
      method: 'GET',
      url: uri.toString(),
      headers: requestHeaders,
    );

    try {
      final response = await _httpClient
          .get(uri, headers: requestHeaders)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'GET',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'GET',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'GET',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  Future<ResponseState<T>> post<T>(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic)? fromJsonT,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(Uri.parse(path), path);
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    _loggingInterceptor.logRequest(
      method: 'POST',
      url: uri.toString(),
      headers: requestHeaders,
      body: encodedBody,
    );

    try {
      final response = await _httpClient
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'POST',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'POST',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'POST',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  Future<ResponseState<T>> put<T>(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic)? fromJsonT,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(Uri.parse(path), path);
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    _loggingInterceptor.logRequest(
      method: 'PUT',
      url: uri.toString(),
      headers: requestHeaders,
      body: encodedBody,
    );

    try {
      final response = await _httpClient
          .put(uri, headers: requestHeaders, body: encodedBody)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'PUT',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'PUT',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'PUT',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  Future<ResponseState<T>> patch<T>(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic)? fromJsonT,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(Uri.parse(path), path);
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    _loggingInterceptor.logRequest(
      method: 'PATCH',
      url: uri.toString(),
      headers: requestHeaders,
      body: encodedBody,
    );

    try {
      final response = await _httpClient
          .patch(uri, headers: requestHeaders, body: encodedBody)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'PATCH',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'PATCH',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'PATCH',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  Future<ResponseState<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJsonT,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(Uri.parse(path), path);
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);

    _loggingInterceptor.logRequest(
      method: 'DELETE',
      url: uri.toString(),
      headers: requestHeaders,
    );

    try {
      final response = await _httpClient
          .delete(uri, headers: requestHeaders)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'DELETE',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'DELETE',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'DELETE',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  ResponseState<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    try {
      final jsonData =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;

      // Extract header response from HTTP headers
      final headerMap = response.headers.map(
        (key, value) => MapEntry(key.toLowerCase(), value),
      );
      final authorization = headerMap[ApiParams.authorization.toLowerCase()];
      final id = headerMap['id'];

      HeaderResponse? headerResponse;
      if (authorization != null || id != null) {
        headerResponse = HeaderResponse(
          authorization: authorization,
          id: id,
        );
      }

      // Automatically save authorization token if present in response headers
      if (authorization != null && authorization.isNotEmpty) {
        _headerInterceptor.updateAuthToken(authorization);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response - parse using BaseResponse
        final baseResponse = jsonData != null
            ? BaseResponse.fromJson(jsonData, fromJsonT)
            : BaseResponse<T>();

        return Success<T>(
          responseCode: response.statusCode,
          message: baseResponse.message,
          data: baseResponse.data,
          bookingId: baseResponse.bookingId,
          header: headerResponse,
        );
      } else {
        // Error response - parse using ErrorResponse
        final errorResponse = jsonData != null
            ? ErrorResponse.fromJson(jsonData)
            : ErrorResponse(message: 'Request failed');

        // Handle token expiration (409 with "Invalid token")
        if (SessionManager.instance.isTokenExpired(
          response.statusCode,
          errorResponse.message,
        )) {
          SessionManager.instance.handleTokenExpired();
        }

        return Error<T>(
          responseCode: response.statusCode,
          error: errorResponse,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 API Response parsing error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      return Error<T>(
        error: ErrorResponse(
            message: 'Failed to parse response: ${e.toString()}'),
      );
    }
  }

  /// GET request that returns raw JSON response without BaseResponse parsing
  /// Use this for external APIs (like Google Maps) that don't follow our response structure
  Future<ResponseState<T>> getRaw<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(
      Uri.parse(path).replace(queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      )),
      path,
    );
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);

    _loggingInterceptor.logRequest(
      method: 'GET (Raw)',
      url: uri.toString(),
      headers: requestHeaders,
    );

    try {
      final response = await _httpClient
          .get(uri, headers: requestHeaders)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'GET (Raw)',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleRawResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'GET (Raw)',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'GET (Raw)',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  /// POST request that returns raw JSON response without BaseResponse parsing
  /// Use this for APIs that don't follow our response structure
  Future<ResponseState<T>> postRaw<T>(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(Uri.parse(path), path);
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    _loggingInterceptor.logRequest(
      method: 'POST (Raw)',
      url: uri.toString(),
      headers: requestHeaders,
      body: encodedBody,
    );

    try {
      final response = await _httpClient
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(_timeout);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'POST (Raw)',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleRawResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'POST (Raw)',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'POST (Raw)',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  /// Handle raw response without BaseResponse parsing
  ResponseState<T> _handleRawResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      final jsonData = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        T? data;
        if (jsonData != null && fromJson != null) {
          data = fromJson(jsonData);
        }

        return Success<T>(
          responseCode: response.statusCode,
          data: data,
        );
      } else {
        final errorMessage = jsonData?['error_message']
            ?? jsonData?['message']
            ?? 'Request failed';

        return Error<T>(
          responseCode: response.statusCode,
          error: ErrorResponse(message: errorMessage),
        );
      }
    } catch (e) {
      return Error<T>(
        error: ErrorResponse(
            message: 'Failed to parse response: ${e.toString()}'),
      );
    }
  }

  /// Multipart PUT request for file uploads
  Future<ResponseState<T>> putMultipart<T>(
    String path, {
    String? filePath,
    required String fileFieldName,
    Map<String, String>? headers,
    Map<String, String>? fields,
    T Function(dynamic)? fromJsonT,
  }) async {
    final startTime = DateTime.now();
    final uri = _baseUrlInterceptor.modifyUrl(Uri.parse(path), path);
    final requestHeaders =
        _headerInterceptor.getHeaders(additionalHeaders: headers);

    _loggingInterceptor.logRequest(
      method: 'PUT (Multipart)',
      url: uri.toString(),
      headers: requestHeaders,
      body: 'File: $filePath, Field: $fileFieldName',
    );

    try {
      final request = http.MultipartRequest('PUT', uri);

      // Add headers (excluding content-type as it will be set by MultipartRequest)
      requestHeaders.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      // Add file only if a new file was selected
      if (filePath != null && filePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath(
          fileFieldName,
          filePath,
        );
        request.files.add(file);
      }

      // Add additional fields if any
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logResponse(
        method: 'PUT (Multipart)',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'PUT (Multipart)',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: 'Failed to connect to the server'),
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _loggingInterceptor.logError(
        method: 'PUT (Multipart)',
        url: uri.toString(),
        error: e.toString(),
        duration: duration,
      );

      return Error<T>(
        error: ErrorResponse(message: e.toString()),
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
