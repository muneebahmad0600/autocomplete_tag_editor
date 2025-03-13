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
  static const List<String> suggestions = ['Flutter', 'Dart', 'Firebase'];
  static const decoration = InputDecoration(border: OutlineInputBorder());
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Tag Editor Demo')),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Title(title: 'Basic Usage'),
                // String example
                AutoCompleteTagEditor<String>(
                  suggestions: suggestions,
                  value: const ['Flutter'],
                  displayValueBuilder: (option) => option,
                  allowCustomTags: true,
                  onTagsChanged: (tags) => debugPrint('Selected tags: $tags'),
                  inputDecoration: decoration,
                ),
                const SizedBox(height: 40),

                // Custom type example
                Title(title: 'Custom Type'),
                AutoCompleteTagEditor<TagData>(
                  suggestions: [TagData('1', 'Mobile'), TagData('2', 'Web')],
                  value: const [],
                  displayValueBuilder: (option) => option.name,
                  allowCustomTags: true,
                  onCreateCustomTag: (input) => TagData(Uuid().v4(), input),
                  inputDecoration: decoration,
                ),
                const SizedBox(height: 40),

                // Custom Tag Design
                Title(title: 'Custom Tag Design'),
                AutoCompleteTagEditor<String>(
                  suggestions: suggestions,
                  value: const ['Flutter', 'Dart'],
                  allowCustomTags: true,
                  inputDecoration: decoration,
                  tagBuilder:
                      (context, tag, onDeleted) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: onDeleted,
                            ),
                          ],
                        ),
                      ),
                ),
                const SizedBox(height: 40),

                // Custom Suggestion Design
                Title(title: 'Custom Suggestion Design'),
                AutoCompleteTagEditor<String>(
                  inputDecoration: decoration,
                  suggestions: suggestions,
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
                Title(title: 'Custom Filter Logic'),
                AutoCompleteTagEditor<String>(
                  inputDecoration: decoration,
                  suggestions: suggestions,
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

class Title extends StatelessWidget {
  final String title;
  const Title({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
