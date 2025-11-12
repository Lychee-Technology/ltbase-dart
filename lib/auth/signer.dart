import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:ltbase_client/crypto/ed25519/ed25519.dart';

class AuthSigner {
  final String accessKeyId;
  final String accessSecret;
  static const _ed25519 = Ed25519Signer();

  AuthSigner({
    required this.accessKeyId,
    required this.accessSecret,
  });

  /// Generate authorization header for API request
  Future<String> generateAuthorizationHeader({
    required String method,
    required String url,
    required String queryString,
    required String body,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _generateNonce();

    // Construct signing string
    final signingString = _constructSigningString(
      method: method,
      url: url,
      queryString: queryString,
      body: body,
      timestamp: timestamp,
      nonce: nonce,
    );

    // Generate signature
    final signature = await _sign(signingString);
    // Construct authorization header
    return 'LtBase $accessKeyId:$signature:$timestamp:$nonce';
  }

  /// Construct signing string according to specification
  String _constructSigningString({
    required String method,
    required String url,
    required String queryString,
    required String body,
    required int timestamp,
    required String nonce,
  }) {
    // Remove trailing '/' and '?' from URL
    var cleanUrl = url;
    while (cleanUrl.endsWith('/') || cleanUrl.endsWith('?')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    // Calculate SHA256 hash of body
    final bodyBytes = utf8.encode(body);
    final bodyHash = sha256.convert(bodyBytes).toString();

    // Construct signing string with newline separators
    final dataToSign = [
      method.toUpperCase(),
      cleanUrl,
      queryString,
      bodyHash,
      timestamp.toString(),
      nonce,
    ].join('\n');
    return dataToSign;
  }

  /// Sign the signing string using Ed25519
  Future<String> _sign(String signingString) {
    // Parse access secret (format: SK_base64url(Ed25519PrivateKey))
    if (!accessSecret.startsWith('SK_')) {
      throw ArgumentError('Invalid access secret format. Must start with SK_');
    }

    final secretKeyBase64 = accessSecret.substring(3);
    final secretKeyBytes = base64Url.decode(secretKeyBase64);

    // Ed25519 private key is 32 bytes
    // The encoded private key might contain ASN.1 DER encoding overhead
    // Extract the actual 32-byte seed from the DER structure
    final seed = _extractEd25519Seed(secretKeyBytes);

    final message = utf8.encode(signingString);
    final signatureBytes = _ed25519.sign(
      seed: seed,
      message: message,
    );

    return Future.value(base64UrlEncode(signatureBytes).replaceAll(RegExp(r'=+$'), ''));
  }

  /// Extract Ed25519 32-byte seed from DER encoded private key
  List<int> _extractEd25519Seed(List<int> derBytes) {
    // For Ed25519, the DER structure is:
    // SEQUENCE {
    //   version INTEGER (0)
    //   algorithm SEQUENCE { ... }
    //   privateKey OCTET STRING containing another OCTET STRING with the 32-byte seed
    // }
    // The actual seed is typically at a fixed offset in this structure

    // Simple approach: look for the 32-byte seed
    // For the example SK_MC4CAQAwBQYDK2VwBCIEIPro6WPVBiMoFCjDT5U8NjqJeIsPcA4PNLOta8DLnjfE
    // After decoding, we need to extract the last 32 bytes which is the seed

    if (derBytes.length >= 32) {
      // Try to find the 32-byte seed
      // In typical Ed25519 DER encoding, the seed is near the end
      // Look for OCTET STRING tag (0x04) followed by length (0x20 = 32)
      for (int i = 0; i < derBytes.length - 33; i++) {
        if (derBytes[i] == 0x04 && derBytes[i + 1] == 0x20) {
          // Found it! Extract next 32 bytes
          return derBytes.sublist(i + 2, i + 34);
        }
      }

      // Fallback: if structured parsing fails, try last 32 bytes
      return derBytes.sublist(derBytes.length - 32);
    }

    throw ArgumentError('Invalid Ed25519 private key format');
  }

  /// Generate a random nonce string
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
