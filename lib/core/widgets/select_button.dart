import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class SelectButtonOptions<T> {
  final T value;
  final String title;
  final Widget icon;

  SelectButtonOptions({
    required this.value,
    required this.title,
    required this.icon,
  });
}

class SelectButton<T> extends StatefulWidget {
  final T? initialSelection;
  final List<SelectButtonOptions<T>> options;
  final Function(T value) onChanged;

  const SelectButton({
    super.key,
    required this.options,
    required this.onChanged,
    this.initialSelection,
  });

  @override
  _SelectButtonState<T> createState() => _SelectButtonState<T>();
}

class _SelectButtonState<T> extends State<SelectButton<T>> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialSelection;
  }

  void _selectValue(T value) {
    setState(() {
      _selectedValue = value;
    });
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: widget.options.map((option) {
        final bool isSelected = _selectedValue == option.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => _selectValue(option.value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Style.colorPrimary.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Style.colorPrimary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  option.icon,
                  const SizedBox(height: 8),
                  Text(
                    option.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Style.colorPrimary : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
