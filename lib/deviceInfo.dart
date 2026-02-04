import 'dart:convert';
import 'package:crypto/crypto.dart';

class JWTCodec {
  final String key;

  JWTCodec(this.key);

  String encode(Map<String, dynamic> payload) {
    final header = json.encode({"typ": "JWT", "alg": "HS256"});
    final encodedHeader = _base64UrlEncode(utf8.encode(header));

    final encodedPayload = _base64UrlEncode(utf8.encode(json.encode(payload)));

    final hmac = Hmac(sha256, utf8.encode(key));
    final signature = hmac.convert(utf8.encode('$encodedHeader.$encodedPayload')).bytes;
    final encodedSignature = _base64UrlEncode(signature);

    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw ArgumentError('Invalid token format');
    }

    final header = parts[0];
    final payload = parts[1];
    final signature = parts[2];

    final hmac = Hmac(sha256, utf8.encode(key));
    final expectedSignature = hmac.convert(utf8.encode('$header.$payload')).bytes;
    final decodedSignature = _base64UrlDecode(signature);

    if (!_hashEquals(expectedSignature, decodedSignature)) {
      throw Exception('Invalid signature');
    }

    final decodedPayload = json.decode(utf8.decode(_base64UrlDecode(payload))) as Map<String, dynamic>;

    if (decodedPayload.containsKey('exp') && decodedPayload['exp'] < DateTime.now().millisecondsSinceEpoch / 1000) {
      throw Exception('Token expired');
    }

    return decodedPayload;
  }

  String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  List<int> _base64UrlDecode(String encoded) {
    var output = encoded.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
    }
    return base64Url.decode(output);
  }

  bool _hashEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}


