import 'package:flutter/material.dart';

typedef AutocompleteOptionToString<T> = String Function(T option);
typedef CreateCustomTag<T> = T Function(String input);

class AutoCompleteTagEditor<T> extends StatefulWidget {
  final List<T> tags;
  final List<T> initialData;
  final InputDecoration inputDecoration;
  final bool allowCustomTags;
  final ValueChanged<String>? onCustomTagAdded;
  final AutocompleteOptionToString<T> displayStringForOption;
  final CreateCustomTag<T>? onCreateCustomTag;

  const AutoCompleteTagEditor({
    super.key,
    required this.tags,
    required this.initialData,
    required this.displayStringForOption,
    this.inputDecoration = const InputDecoration(),
    this.allowCustomTags = false,
    this.onCustomTagAdded,
    this.onCreateCustomTag,
  });

  @override
  AutoCompleteTagEditorState<T> createState() =>
      AutoCompleteTagEditorState<T>();
}

class AutoCompleteTagEditorState<T> extends State<AutoCompleteTagEditor<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<T> _selectedTags = [];
  String _currentInput = '';

  @override
  void initState() {
    super.initState();
    _selectedTags = List<T>.from(widget.initialData);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 5),
              child: _buildSuggestions(),
            ),
          ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _getSuggestions();
    if (suggestions.isEmpty) return Container();

    return Material(
      elevation: 4,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children:
            suggestions.map((T option) {
              return ListTile(
                title: Text(widget.displayStringForOption(option)),
                onTap: () => _addTag(option),
              );
            }).toList(),
      ),
    );
  }

  List<T> _getSuggestions() {
    return widget.tags.where((tag) {
      final tagText = widget.displayStringForOption(tag).toLowerCase();
      return tagText.contains(_currentInput.toLowerCase());
    }).toList();
  }

  void _addTag(T tag) {
    setState(() {
      _selectedTags.add(tag);
      _currentInput = '';
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  void _handleTextInput(String text) {
    setState(() => _currentInput = text);
    if (text.endsWith(' ')) {
      _handleTagCreation(text.trim());
    }
  }

  void _handleTagCreation(String text) {
    if (text.isEmpty) return;

    final existing = widget.tags.firstWhere(
      (tag) => widget.displayStringForOption(tag) == text,
      orElse: () => null as T,
    );

    if (existing != null) {
      _addTag(existing);
    } else if (widget.allowCustomTags) {
      _createCustomTag(text);
    }
  }

  void _createCustomTag(String text) {
    if (widget.onCreateCustomTag != null) {
      final customTag = widget.onCreateCustomTag!(text);
      _addTag(customTag);
    } else if (T == String) {
      _addTag(text as T);
    }
    widget.onCustomTagAdded?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InputDecorator(
        decoration: widget.inputDecoration,
        child: Wrap(
          spacing: 4,
          children: [
            ..._selectedTags.map(
              (tag) => Chip(
                label: Text(widget.displayStringForOption(tag)),
                onDeleted: () => setState(() => _selectedTags.remove(tag)),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 100),
              child: EditableText(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _handleTextInput,
                backgroundCursorColor: Colors.grey,
                style: TextStyle(color: Colors.black, fontSize: 16),
                cursorColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
