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
                AutoCompleteTagEditor<String>(
                  suggestions: ['Flutter', 'Dart', 'Firebase'],
                  value: const ['Flutter'],
                  displayValueBuilder: (option) => option,
                  allowCustomTags: true,
                  onTagsChanged: (tags) => debugPrint('Selected tags: $tags'),
                  inputDecoration: InputDecoration(
                    labelText: 'Add Tags',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),

                // Custom type example
                AutoCompleteTagEditor<TagData>(
                  suggestions: [TagData('1', 'Mobile'), TagData('2', 'Web')],
                  value: const [],
                  displayValueBuilder: (option) => option.name,
                  allowCustomTags: true,
                  onCreateCustomTag: (input) => TagData(Uuid().v4(), input),
                ),
                const SizedBox(height: 40),

                // Custom Tag Design
                AutoCompleteTagEditor<String>(
                  tagBuilder:
                      (context, tag, onDeleted) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: onDeleted,
                            ),
                          ],
                        ),
                      ),
                ),
                const SizedBox(height: 40),

                // Custom Suggestion Design
                AutoCompleteTagEditor<String>(
                  suggestionItemBuilder:
                      (context, suggestion, onSelected) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.tag),
                          title: Text(suggestion),
                          trailing: const Icon(Icons.add_circle),
                          onTap: onSelected,
                        ),
                      ),
                ),
                const SizedBox(height: 40),

                // Custom Filter Logic
                AutoCompleteTagEditor<String>(
                  suggestionFilter: (suggestion, query) {
                    // Implement custom filtering logic
                    return suggestion.toLowerCase().startsWith(
                      query.toLowerCase(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
