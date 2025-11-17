import 'dart:convert';
import 'dart:io';
import 'package:ltbase_client/auth/signer.dart';

class ApiClient {
  final String baseUrl;
  final AuthSigner signer;
  final bool verbose;

  ApiClient({
    required this.baseUrl,
    required this.signer,
    this.verbose = false,
  });

  /// Make HTTP request with authentication
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String>? queryParams,
    Object? body,
  }) async {
    // Build full URL
    final uri = Uri.parse(baseUrl + path);
    final urlWithoutQuery = uri.toString();
    // Build query string (sorted by key)
    final sortedQueryString = _buildQueryString(queryParams);
    final fullUri = queryParams != null && queryParams.isNotEmpty
        ? uri.replace(queryParameters: queryParams)
        : uri;

    // Encode body
    final bodyString = body != null ? jsonEncode(body) : '';

    print('bodyString: $bodyString\n');

    // Generate authorization header
    final authHeader = await signer.generateAuthorizationHeader(
      method: method,
      url: urlWithoutQuery,
      queryString: sortedQueryString,
      body: bodyString,
    );

    if (verbose) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Request: $method $fullUri');
      print('Authorization: $authHeader');
      if (urlWithoutQuery.isNotEmpty) {
        print('URL: $urlWithoutQuery');
      }
      if (bodyString.isNotEmpty) {
        print('Body: $bodyString');
      }
      if (sortedQueryString.isNotEmpty) {
        print('Query: $sortedQueryString');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // Make HTTP request using dart:io
    final client = HttpClient();
    try {
      HttpClientRequest request;

      switch (method.toUpperCase()) {
        case 'GET':
          request = await client.getUrl(fullUri);
          break;
        case 'POST':
          request = await client.postUrl(fullUri);
          break;
        case 'PUT':
          request = await client.putUrl(fullUri);
          break;
        case 'DELETE':
          request = await client.deleteUrl(fullUri);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      // Set headers
      request.headers.set('Authorization', authHeader);
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      // Write body if present
      if (bodyString.isNotEmpty) {
        request.add(utf8.encode(bodyString));
      }

      // Send request and get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (verbose) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: $responseBody');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      return ApiResponse(
        statusCode: response.statusCode,
        body: responseBody,
        headers: response.headers,
      );
    } catch (e, stackTrace) {
      // 打印异常信息
      print('Exception: $e');
      print('Stack trace:\n$stackTrace');

      // 重新抛出原始异常（保留原始堆栈）
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Build query string sorted by key
  String _buildQueryString(Map<String, String>? params) {
    if (params == null || params.isEmpty) {
      return '';
    }

    // Sort keys and build query string
    final sortedKeys = params.keys.toList()..sort();
    final parts = <String>[];

    for (final key in sortedKeys) {
      final value = params[key];
      if (value != null) {
        parts.add(
            '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}');
      }
    }

    return parts.join('&');
  }

  /// GET request
  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) {
    return request(method: 'GET', path: path, queryParams: queryParams);
  }

  /// POST request
  Future<ApiResponse> post(String path, {Object? body}) {
    return request(method: 'POST', path: path, body: body);
  }

  /// PUT request
  Future<ApiResponse> put(String path, {Object? body}) {
    return request(method: 'PUT', path: path, body: body);
  }

  /// DELETE request
  Future<ApiResponse> delete(String path) {
    return request(method: 'DELETE', path: path);
  }
}

class ApiResponse {
  final int statusCode;
  final String body;
  final HttpHeaders headers;

  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic>? get json {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'ApiResponse(status: $statusCode, body: $body)';
  }
}
