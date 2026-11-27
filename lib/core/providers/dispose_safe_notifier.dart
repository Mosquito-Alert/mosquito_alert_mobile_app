import 'package:flutter/foundation.dart';

/// Lets a [ChangeNotifier] be notified after it has been disposed without
/// throwing.
///
/// The app's state classes start network and storage work and call
/// [notifyListeners] when it finishes. If the object was disposed in the
/// meantime, because the widget tree went away while the work was in flight, a
/// plain [ChangeNotifier] throws "was used after being disposed" in debug
/// builds and in tests. Nobody is listening any more by then, so the late
/// notification is simply dropped.
mixin DisposeSafeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
