// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class AurexHttpResponse {
  const AurexHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class AurexNetworkException implements Exception {
  const AurexNetworkException();
}

Future<AurexHttpResponse> aurexPostJson(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
}) async {
  return _request(
    uri,
    method: 'POST',
    headers: {...headers, 'Content-Type': 'application/json'},
    body: body,
  );
}

Future<AurexHttpResponse> aurexGet(
  Uri uri, {
  required Map<String, String> headers,
}) {
  return _request(uri, method: 'GET', headers: headers);
}

Future<AurexHttpResponse> aurexPutJson(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
}) {
  return _request(
    uri,
    method: 'PUT',
    headers: {...headers, 'Content-Type': 'application/json'},
    body: body,
  );
}

Future<AurexHttpResponse> aurexUploadFile(
  Uri uri, {
  required Map<String, String> headers,
  required String fieldName,
  required String filePath,
}) {
  throw const AurexNetworkException();
}

Future<AurexHttpResponse> _request(
  Uri uri, {
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  try {
    final response = await html.HttpRequest.request(
      uri.toString(),
      method: method,
      requestHeaders: headers,
      sendData: body,
    );

    return AurexHttpResponse(
      statusCode: response.status ?? 0,
      body: response.responseText ?? '',
    );
  } catch (_) {
    throw const AurexNetworkException();
  }
}
