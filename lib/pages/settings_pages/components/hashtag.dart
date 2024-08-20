import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:textfield_tags/textfield_tags.dart';


class StringMultilineTags extends StatefulWidget {
  const StringMultilineTags({Key? key, required this.updateTagsNum}) : super(key: key);
  final void Function(int) updateTagsNum;

  @override
  State<StringMultilineTags> createState() => _StringMultilineTagsState();
}

class _StringMultilineTagsState extends State<StringMultilineTags> {
  late double _distanceToField;
  late StringTagController _stringTagController;
  late List<String> hashtags;
  bool isLoading = true;
  String currentWord = '';

  void getHashtags() async {
    hashtags = await UserManager.getHashtags() ?? [];
    setState(() {
      isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void initState() {
    super.initState();
    _stringTagController = StringTagController();
    getHashtags();
  }

  @override
  void dispose() {
    super.dispose();
    _stringTagController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (value) {
        if (value.logicalKey.keyLabel == 'Backspace' && value is KeyDownEvent && currentWord == ''){
          onBackspace();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            if (isLoading)
              CircularProgressIndicator()
            else
              TextFieldTags<String>(
                textfieldTagsController: _stringTagController,
                initialTags: hashtags,
                textSeparators: const [' ', ','],
                letterCase: LetterCase.normal,
                inputFieldBuilder: (context, inputFieldValues) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      onTap: () {
                        _stringTagController.getFocusNode?.requestFocus();
                      },
                      controller: inputFieldValues.textEditingController,
                      focusNode: inputFieldValues.focusNode,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 74, 137, 92),
                            width: 3.0,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 3.0,
                          ),
                        ),
                        hintText: inputFieldValues.tags.isNotEmpty ? '' : MyLocalizations.of(context, 'auto_tagging_settings_placeholder'),
                        errorText: inputFieldValues.error,
                        prefixIconConstraints: BoxConstraints(maxWidth: _distanceToField * 0.8),
                        prefixIcon: inputFieldValues.tags.isEmpty ? null :
                          SingleChildScrollView(
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
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(20.0),
                                      ),
                                      color: Colors.orange,
                                    ),
                                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
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
                                            hashtags.remove(tag);
                                            UserManager.setHashtags(hashtags);
                                            widget.updateTagsNum(hashtags.length);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                }).toList()
                              ),
                            ),
                          )
                      ),
                      onChanged: (String change){
                        currentWord = change;
                        if (change.endsWith(' ')){
                          // Space was pressed                        
                          addNewHashtag(change, inputFieldValues);
                        }
                        inputFieldValues.onTagChanged(change);
                      },
                      onSubmitted: (String newTag){
                        addNewHashtag(newTag, inputFieldValues);
                      }
                    ),
                  );
                },
              ),
          ],
        ),
      )
    );
  }

  void addNewHashtag(String newTag, InputFieldValues<String> inputFieldValues){
    newTag = newTag.replaceAll('#', '');

    if (!hashtags.contains(newTag)) {
      inputFieldValues.onTagSubmitted(newTag);
      hashtags.add(newTag);
      UserManager.setHashtags(hashtags);
      widget.updateTagsNum(hashtags.length);
      currentWord = '';
    }
  }

  void onBackspace(){
    // Delete last hashtag
    if (hashtags.isEmpty) { return; }

    hashtags.removeLast();
    UserManager.setHashtags(hashtags);
    widget.updateTagsNum(hashtags.length);
  }
}
