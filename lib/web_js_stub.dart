/// Stub for dart:js — used on non-web platforms where dart:js is unavailable.
/// This provides a no-op `context` so the code compiles on Android/iOS.

class JsObject {
  dynamic operator [](String key) => null;
  void operator []=(String key, dynamic value) {}
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

final JsObject context = JsObject();
