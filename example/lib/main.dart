import 'package:flutter/material.dart';
import 'package:autocomplete_tag_editor/autocomplete_tag_editor.dart';
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Tag Editor Demo')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // String example
              AutoCompleteTagEditor<String>(
                tags: ['Flutter', 'Dart', 'Firebase'],
                initialData: ['Flutter'],
                displayStringForOption: (option) => option,
                allowCustomTags: true,
                onCustomTagAdded: (value) => print('Custom tag: $value'),
              ),

              const SizedBox(height: 40),

              // Custom type example
              AutoCompleteTagEditor<TagData>(
                tags: [TagData('1', 'Mobile'), TagData('2', 'Web')],
                initialData: [],
                displayStringForOption: (option) => option.name,
                onCreateCustomTag: (input) => TagData(Uuid().v4(), input),
                allowCustomTags: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
