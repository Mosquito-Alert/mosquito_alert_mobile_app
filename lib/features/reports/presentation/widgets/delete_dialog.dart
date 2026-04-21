import 'package:flutter/material.dart';

import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class DeleteDialog extends StatelessWidget {
  final Future<void> Function() onDelete;

  const DeleteDialog({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(MyLocalizations.of(context, 'delete_report_title')),
      content: Text(MyLocalizations.of(context, 'delete_report_txt')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            MyLocalizations.of(context, 'cancel'),
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        TextButton(
          onPressed: () async => await onDelete(),
          child: Text(
            MyLocalizations.of(context, 'delete'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
