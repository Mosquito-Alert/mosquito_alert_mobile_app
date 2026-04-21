import 'package:uuid/uuid.dart';

enum OutBoxOperation { create, update, delete }

class OutboxItem {
  final String id;
  final String repository;
  final OutBoxOperation operation;
  final Map<String, dynamic> payload;

  OutboxItem({
    String? id,
    required this.repository,
    required this.operation,
    required this.payload,
  }) : assert(
         operation != OutBoxOperation.create || id != null,
         'id is mandatory for create operation',
       ),
       this.id = id ?? Uuid().v4();
}

class OutboxTask {
  final OutboxItem item;
  final Future<void> Function() action;

  OutboxTask({required this.item, required this.action});

  Future<void> run() async {
    await action();
  }
}
