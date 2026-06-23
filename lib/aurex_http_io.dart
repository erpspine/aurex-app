import 'dart:convert';
import 'dart:io';

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
  final client = HttpClient();

  try {
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;

    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    request.write(body);

    final response = await request.close();
    return AurexHttpResponse(
      statusCode: response.statusCode,
      body: await response.transform(utf8.decoder).join(),
    );
  } on SocketException {
    throw const AurexNetworkException();
  } finally {
    client.close(force: true);
  }
}

Future<AurexHttpResponse> aurexGet(
  Uri uri, {
  required Map<String, String> headers,
}) async {
  final client = HttpClient();

  try {
    final request = await client.getUrl(uri);

    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    final response = await request.close();
    return AurexHttpResponse(
      statusCode: response.statusCode,
      body: await response.transform(utf8.decoder).join(),
    );
  } on SocketException {
    throw const AurexNetworkException();
  } finally {
    client.close(force: true);
  }
}
