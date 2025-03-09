import 'package:autocomplete_tag_editor/autocomplete_tag_editor.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TagData {
  final String id;
  final String name;

  TagData(this.id, this.name);
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const OutlineInputBorder kInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(
        color: Color.fromARGB(255, 127, 205, 144),
        width: 0.8,
      ),
    );

    const OutlineInputBorder kEnabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: Colors.grey, width: 0.8),
    );

    const OutlineInputBorder kFocusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(
        color: Color.fromARGB(255, 127, 205, 144),
        width: 0.8,
      ),
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Tag Editor Demo')),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // String example
                AutoCompleteTagEditor<String?>(
                  suggestions: ['Flutter', 'Dart', 'Firebase'],
                  inputDecoration: InputDecoration(
                    border: kInputBorder,
                    focusedBorder: kFocusedBorder,
                    enabledBorder: kEnabledBorder,
                    labelStyle: TextStyle(fontSize: 16.0),
                    hintStyle: TextStyle(fontSize: 10.0),
                    label: Text('Tags'),
                  ),
                  value: ['Flutter'],
                  displayValueBuilder: (option) => option ?? '',
                  allowCustomTags: true,
                  onCreateCustomTag: (input) => input,
                  onTagsChanged: (value) => print('Custom tag: $value'),
                ),
                const SizedBox(height: 40),

                // Custom type example
                // AutoCompleteTagEditor<TagData?>(
                //   tags: [TagData('1', 'Mobile'), TagData('2', 'Web')],
                //   initialData: [],
                //   displayStringForOption: (option) => option?.name ?? '',
                //   onCreateCustomTag: (input) => TagData(Uuid().v4(), input),
                //   allowCustomTags: true,
                // ),
                TextField(
                  decoration: InputDecoration(
                    border: kInputBorder,
                    focusedBorder: kFocusedBorder,
                    enabledBorder: kEnabledBorder,
                    labelStyle: TextStyle(fontSize: 16.0),
                    hintStyle: TextStyle(fontSize: 10.0),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
