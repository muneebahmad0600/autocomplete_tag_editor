# AutoCompleteTagEditor

[![Pub Version](https://img.shields.io/pub/v/autocomplete_tag_editor)](https://pub.dev/packages/autocomplete_tag_editor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A versatile Flutter tag input widget with autocomplete suggestions and custom tag creation capabilities.

<!-- Add screenshot here -->
<!-- ![Demo Screenshot](screenshot.png) -->

## Features

- 🏷️ **Generic Type Support** - Works with String or any custom object type
- 🔍 **Smart Autocomplete** - Filter suggestions as you type
- ✨ **Custom Tag Creation** - Allow new tags not in suggestions
- 📱 **Responsive Layout** - Automatic line wrapping for tags
- 🎨 **Customizable UI** - Match your app's theme
- 🧩 **Overlay Suggestions** - Position-aware dropdown list
- ✅ **Validation Support** - Built-in input validation

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  autocomplete_tag_editor: ^<latest-version>
```

## Basic Usage

### String Tags

```dart
AutoCompleteTagEditor<String>(
  suggestions: ['Flutter', 'Dart', 'Firebase'],
  value: const ['Flutter'],
  displayValueBuilder: (option) => option,
  allowCustomTags: true,
  onTagsChanged: (tags) => print('Selected tags: $tags'),
)
```

### Custom Type Tags

```dart
class TagData {
  final String id;
  final String name;

  TagData(this.id, this.name);
}

AutoCompleteTagEditor<TagData>(
  suggestions: [
    TagData('1', 'Mobile'),
    TagData('2', 'Web'),
  ],
  value: const [],
  displayValueBuilder: (option) => option.name,
  allowCustomTags: true,
  onCreateCustomTag: (input) => TagData(Uuid().v4(), input),
  onTagsChanged: (tags) => print('Custom tags: $tags'),
)
```

## Parameters

| Parameter             | Type                     | Required | Description                                                                |
|-----------------------|--------------------------|----------|----------------------------------------------------------------------------|
| suggestions           | List<T>                  | Yes      | Available options for autocomplete                                         |
| value                 | List<T>                  | Yes      | Initially selected tags                                                    |
| displayValueBuilder   | DisplayValueBuilder<T>   | Yes      | Converts T instance to display string                                      |
| inputDecoration       | InputDecoration          | No       | Decoration for the input field                                             |
| allowCustomTags       | bool                     | No       | Enable creation of tags not in suggestions (default: false)                |
| onCreateCustomTag     | CreateCustomTag<T>       | No       | Required when using non-String types with allowCustomTags=true             |
| onTagsChanged         | ValueChanged<List<T>>    | No       | Callback when tags change                                                  |

### Important Notes
⚠️ Type Safety Requirements

- When using custom types (T != String) with allowCustomTags: true,
you must provide onCreateCustomTag
- `displayValueBuilder` must be provided for all types

### 💡 UI Considerations

- The widget uses Flutter's overlay system for suggestions
- Input field automatically expands with content
- Suggestions list positions dynamically based on input field size

### 🔧 State Management

- Parent widgets should manage the selected tags state if needed
- Use onTagsChanged to track tag additions/removals

## Example App
See the `/example` directory for a complete implementation. The example demonstrates:

- String tag implementation
- Custom object type tags
- Custom styling
- Validation scenarios
- Error handling

<!-- Add video demo here --><!-- ![Demo Video](demo.mp4) -->

## Contributing
Contributions are welcome! Please follow these steps:

- Fork the repository
- Create your feature branch
- Commit your changes
- Push to the branch
- Create a new Pull Request
