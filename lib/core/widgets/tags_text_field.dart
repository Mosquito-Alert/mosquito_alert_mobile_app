import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:textfield_tags/textfield_tags.dart';

class TagsTextField extends StatefulWidget {
  final List<String> initialTags;
  final void Function(List<String>)? onTagsChanged;

  TagsTextField({super.key, this.onTagsChanged, this.initialTags = const []});

  @override
  State<TagsTextField> createState() => _TagsTextFieldState();
}

class _TagsTextFieldState extends State<TagsTextField> {
  late double _distanceToField;
  late StringTagController _stringTagController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void initState() {
    super.initState();
    _stringTagController = StringTagController();

    _stringTagController.addListener(() {
      if (widget.onTagsChanged != null) {
        widget.onTagsChanged!(_stringTagController.getTags ?? []);
      }
    });
  }

  @override
  void dispose() {
    _stringTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldTags<String>(
      textfieldTagsController: _stringTagController,
      initialTags: widget.initialTags,
      textSeparators: const [' ', ','],
      letterCase: LetterCase.normal,
      validator: (tag) => tag.contains('#') ? '# not allowed' : null,
      inputFieldBuilder: (context, inputFieldValues) {
        return TextField(
          onTap: () {
            _stringTagController.getFocusNode?.requestFocus();
          },
          controller: inputFieldValues.textEditingController,
          focusNode: inputFieldValues.focusNode,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Style.colorPrimary, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Style.colorPrimary, width: 2.0),
            ),
            hintText: inputFieldValues.tags.isNotEmpty
                ? ''
                : MyLocalizations.of(
                    context,
                    'auto_tagging_settings_placeholder',
                  ),
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
            errorText: inputFieldValues.error,
            prefixIconConstraints: BoxConstraints(
              maxWidth: _distanceToField * 0.8,
            ),
            prefixIcon: inputFieldValues.tags.isEmpty
                ? null
                : SingleChildScrollView(
                    controller: inputFieldValues.tagScrollController,
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: 8,
                      ),
                      child: Wrap(
                        runSpacing: 4.0,
                        spacing: 4.0,
                        children: inputFieldValues.tags.map((String tag) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                              color: Style.colorPrimary,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 5.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                InkWell(
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 14.0,
                                    color: Colors.white,
                                  ),
                                  onTap: () {
                                    inputFieldValues.onTagRemoved(tag);
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          onChanged: inputFieldValues.onTagChanged,
          onSubmitted: inputFieldValues.onTagSubmitted,
        );
      },
    );
  }
}
