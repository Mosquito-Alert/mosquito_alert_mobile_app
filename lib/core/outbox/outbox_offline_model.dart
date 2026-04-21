abstract class OfflineModel {
  /// Locally generated UUID for pending/offline reports
  final String? localId;

  /// True if synced with the server
  bool get isOffline => localId != null;

  OfflineModel({this.localId});
}
