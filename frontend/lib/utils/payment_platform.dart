import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// `razorpay_flutter` only supports Android and iOS.
bool get razorpayNativeCheckoutSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}
