abstract interface class Request<T> {
  Map<String, dynamic> toJson();
}

abstract class CreateRequest implements Request {
  String localId;

  CreateRequest({required this.localId});
}

abstract class DeleteRequest implements Request {}
