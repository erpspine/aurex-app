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

Future<AurexHttpResponse> aurexPutJson(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
}) async {
  final client = HttpClient();

  try {
    final request = await client.putUrl(uri);
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

Future<AurexHttpResponse> aurexUploadFile(
  Uri uri, {
  required Map<String, String> headers,
  required String fieldName,
  required String filePath,
}) async {
  final client = HttpClient();

  try {
    final file = File(filePath);
    final boundary = 'aurex-${DateTime.now().microsecondsSinceEpoch}';
    final request = await client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'profile-photo.jpg';
    final header =
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="$fieldName"; filename="$fileName"\r\n'
        'Content-Type: image/jpeg\r\n\r\n';

    request.add(utf8.encode(header));
    await request.addStream(file.openRead());
    request.add(utf8.encode('\r\n--$boundary--\r\n'));

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
