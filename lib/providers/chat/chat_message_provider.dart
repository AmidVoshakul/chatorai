import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageCacheProvider = Provider.family<Uint8List, String>((
  ref,
  base64Data,
) {
  return base64Decode(base64Data);
});
