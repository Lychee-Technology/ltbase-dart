// Portions Copyright 2019-2020 Gohilla.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'ed25519_impl.dart';

/// Minimal Ed25519 implementation extracted from package:cryptography.
class Ed25519Signer {
  const Ed25519Signer();

  /// Returns a 64-byte signature for [message] using the 32-byte [seed].
  Uint8List sign({
    required List<int> seed,
    required List<int> message,
  }) {
    final seedBytes = Uint8List.fromList(seed);
    if (seedBytes.length != 32) {
      throw ArgumentError('Seed must have 32 bytes');
    }

    final messageBytes = Uint8List.fromList(message);
    final privateKeyHash = _sha512(seedBytes);
    final privateKeyHashFixed =
        Uint8List.fromList(privateKeyHash.sublist(0, 32));
    _setPrivateKeyFixedBits(privateKeyHashFixed);

    final publicKeyBytes = _pointCompress(
      _pointMul(
        Register25519()..setBytes(privateKeyHashFixed),
        Ed25519Point.base,
      ),
    );

    final mhSalt = privateKeyHash.sublist(32);
    final mhBytes = _join([mhSalt, messageBytes]);
    final mh = _sha512(mhBytes);
    final mhL = RegisterL()..readBytes(mh);

    final pointR = _pointMul(mhL.toRegister25519(), Ed25519Point.base);
    final pointRCompressed = _pointCompress(pointR);

    final shBytes = _join([pointRCompressed, publicKeyBytes, messageBytes]);
    final sh = _sha512(shBytes);

    final s = RegisterL()..readBytes(sh);
    final privateScalar = RegisterL()..readBytes(privateKeyHashFixed);
    s.mul(s, privateScalar);
    s.add(s, mhL);

    final sBytes = s.toBytes();
    return Uint8List.fromList([
      ...pointRCompressed,
      ...sBytes,
    ]);
  }

  /// Returns the 32-byte Ed25519 public key for the given [seed].
  Uint8List derivePublicKey(List<int> seed) {
    if (seed.length != 32) {
      throw ArgumentError('Seed must have 32 bytes');
    }

    final hashOfPrivateKey = _sha512(seed);
    final tmp = Uint8List.fromList(hashOfPrivateKey.sublist(0, 32));
    _setPrivateKeyFixedBits(tmp);

    return Uint8List.fromList(_pointCompress(
      _pointMul(
        Register25519()..setBytes(tmp),
        Ed25519Point.base,
      ),
    ));
  }

  static Uint8List _sha512(List<int> input) {
    final digest = crypto.sha512.convert(input);
    return Uint8List.fromList(digest.bytes);
  }

  static Uint8List _join(List<List<int>> parts) {
    final totalLength = parts.fold<int>(0, (a, b) => a + b.length);
    final buffer = Uint8List(totalLength);
    var i = 0;
    for (var part in parts) {
      buffer.setAll(i, part);
      i += part.length;
    }
    return buffer;
  }

  static void _pointAdd(
    Ed25519Point r,
    Ed25519Point p,
    Ed25519Point q, {
    Ed25519Point? tmp,
  }) {
    tmp ??= Ed25519Point.zero();

    final a = r.x;
    final b = r.y;
    final c = r.z;
    final d = r.w;

    final e = tmp.x;
    final f = tmp.y;
    final g = tmp.z;
    final h = tmp.w;

    a.sub(p.y, p.x);
    b.sub(q.y, q.x);
    a.mul(a, b);

    b.add(p.y, p.x);
    c.add(q.y, q.x);
    b.mul(b, c);

    c.mul(Register25519.two, p.w);
    c.mul(c, q.w);
    c.mul(c, Register25519.D);

    d.mul(Register25519.two, p.z);
    d.mul(d, q.z);

    e.sub(b, a);
    f.sub(d, c);
    g.add(d, c);
    h.add(b, a);

    a.mul(e, f);
    b.mul(g, h);
    c.mul(f, g);
    d.mul(e, h);
  }

  static List<int> _pointCompress(Ed25519Point p) {
    final zInv = Register25519();
    final x = Register25519();
    final y = Register25519();

    zInv.pow(p.z, Register25519.PMinusTwo);
    x.mul(p.x, zInv);
    y.mul(p.y, zInv);

    assert(0x8000 & y.data[15] == 0);
    y.data[15] |= (0x1 & x.data[0]) << 15;

    return y.toBytes(Uint8List(32));
  }

  static Ed25519Point _pointMul(
    Register25519 s,
    Ed25519Point pointP,
  ) {
    var q = Ed25519Point.zero();
    q.y.data[0] = 1;
    q.z.data[0] = 1;

    pointP = Ed25519Point(
      Register25519.from(pointP.x),
      Register25519.from(pointP.y),
      Register25519.from(pointP.z),
      Register25519.from(pointP.w),
    );

    var tmp0 = Ed25519Point.zero();
    final tmp1 = Ed25519Point.zero();

    for (var i = 0; i < 256; i++) {
      final b = 0x1 & (s.data[i ~/ 16] >> (i % 16));

      if (b == 1) {
        _pointAdd(tmp0, q, pointP, tmp: tmp1);
        final oldQ = q;
        q = tmp0;
        tmp0 = oldQ;
      }

      _pointAdd(tmp0, pointP, pointP, tmp: tmp1);
      final oldP = pointP;
      pointP = tmp0;
      tmp0 = oldP;
    }
    return q;
  }

  static void _setPrivateKeyFixedBits(List<int> list) {
    list[0] &= 0xF8;
    list[31] &= 0x7F;
    list[31] |= 0x40;
  }
}
