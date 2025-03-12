// Copyright 2023 https://github.com/muneebahmad0600. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A comprehensive tag input widget with autocomplete suggestions and custom tag creation capabilities.
///
/// Features:
/// - Supports both String and custom object types for tags
/// - Automatic suggestions filtering as users type
/// - Customizable tag chips and suggestion items
/// - Dynamic overlay positioning
/// - Custom tag creation with validation
/// - Responsive layout with tag wrapping
///
/// Usage:
/// - For String tags: Provide [suggestions] and set [allowCustomTags] as needed
/// - For custom types: Implement [displayValueBuilder] and [onCreateCustomTag]
/// - Customize appearance using [tagBuilder] and [suggestionItemBuilder]

// region: Type Definitions
/// Converts a [T] instance to its display string representation
typedef DisplayValueBuilder<T> = String Function(T option);

/// Creates a [T] instance from raw string input for custom tags
typedef CreateCustomTag<T> = T Function(String input);

/// Builds custom tag chip widgets
typedef TagBuilder<T> =
    Widget Function(BuildContext context, T tag, VoidCallback onDeleted);

/// Builds custom suggestion list items
typedef SuggestionItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T suggestion,
      VoidCallback onSelected,
    );

/// Custom filter function for suggestions
typedef SuggestionFilter<T> = bool Function(T suggestion, String query);
// endregion

// region: Main Widget
/// A versatile tag input widget with autocomplete capabilities
class AutoCompleteTagEditor<T> extends StatefulWidget {
  /// Available suggestions for autocompletion
  final List<T> suggestions;

  /// Initially selected tags when widget is first rendered
  final List<T> value;

  /// Decoration for the underlying input field
  final InputDecoration inputDecoration;

  /// Callback when the selected tags list changes
  final ValueChanged<List<T>>? onTagsChanged;

  /// Converts [T] to display string (required for non-String types)
  final DisplayValueBuilder<T>? displayValueBuilder;

  /// Enables creation of tags not present in [suggestions]
  final bool allowCustomTags;

  /// Creates [T] from raw string input (required for non-String custom tags)
  final CreateCustomTag<T>? onCreateCustomTag;

  /// Custom builder for tag chips
  final TagBuilder<T>? tagBuilder;

  /// Custom builder for suggestion list items
  final SuggestionItemBuilder<T>? suggestionItemBuilder;

  /// Custom filter logic for suggestions
  final SuggestionFilter<T>? suggestionFilter;

  const AutoCompleteTagEditor({
    super.key,
    this.suggestions = const [],
    this.value = const [],
    this.displayValueBuilder,
    this.inputDecoration = const InputDecoration(),
    this.allowCustomTags = false,
    this.onTagsChanged,
    this.onCreateCustomTag,
    this.tagBuilder,
    this.suggestionItemBuilder,
    this.suggestionFilter,
  }) : assert(
         !allowCustomTags || T == String || onCreateCustomTag != null,
         'When using custom types with allowCustomTags=true, '
         'you must provide the onCreateCustomTag callback',
       ),
       assert(
         T == String || displayValueBuilder != null,
         'displayValueBuilder must be provided for non-String types',
       );

  @override
  AutoCompleteTagEditorState<T> createState() =>
      AutoCompleteTagEditorState<T>();
}
// endregion

// region: Widget State
class AutoCompleteTagEditorState<T> extends State<AutoCompleteTagEditor<T>> {
  /// Key for tracking the widget's position in the layout
  final GlobalKey _compositedKey = GlobalKey();

  /// Controller for the text input field
  final TextEditingController _controller = TextEditingController();

  /// Focus node for managing input focus state
  final FocusNode _focusNode = FocusNode();

  /// Layer link for connecting the widget to the overlay
  final LayerLink _layerLink = LayerLink();

  /// List of currently selected tags
  final List<T> _selectedTags = [];

  /// Duration for overlay animations
  final Duration _animationDuration = const Duration(milliseconds: 200);

  /// Overlay entry for the suggestions list
  OverlayEntry? _overlayEntry;

  /// Current text input value
  String _currentInput = '';

  @override
  void initState() {
    super.initState();
    _selectedTags.addAll(widget.value);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(AutoCompleteTagEditor<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestions != widget.suggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  /// Handles focus changes to show/hide suggestions overlay
  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _controller.clear();
      _hideOverlay();
    }
    if (mounted) setState(() {});
  }

  /// Displays the suggestions overlay
  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hides the suggestions overlay
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Creates the overlay entry with dynamic positioning
  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final renderBox =
            _compositedKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return Container();

        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);

        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4,
          width: size.width,
          child: _buildSuggestions(),
        );
      },
    );
  }

  /// Builds the suggestions list widget
  Widget _buildSuggestions() {
    final suggestions = _getFilteredSuggestions();

    return AnimatedSize(
      duration: _animationDuration,
      child: Material(
        elevation: 4,
        child:
            _shouldShowEmptyState(suggestions)
                ? _buildEmptyState()
                : _buildSuggestionList(suggestions),
      ),
    );
  }

  /// Determines if empty state should be shown
  bool _shouldShowEmptyState(List<T> suggestions) {
    return _controller.text.isNotEmpty && suggestions.isEmpty;
  }

  /// Builds the empty state widget
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Create new tag: ${_controller.text}'),
    );
  }

  /// Builds the list of suggestion items
  Widget _buildSuggestionList(List<T> suggestions) {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: suggestions.map(_buildSuggestionTile).toList(),
    );
  }

  /// Builds individual suggestion list items
  Widget _buildSuggestionTile(T option) {
    return widget.suggestionItemBuilder?.call(
          context,
          option,
          () => _addTag(option),
        ) ??
        ListTile(
          dense: true,
          title: Text(
            widget.displayValueBuilder?.call(option) ?? option.toString(),
          ),
          onTap: () => _addTag(option),
        );
  }

  /// Filters suggestions based on current input and selection
  List<T> _getFilteredSuggestions() {
    return widget.suggestions.where((tag) {
      if (_selectedTags.contains(tag)) return false;

      return widget.suggestionFilter?.call(tag, _currentInput) ??
          _defaultFilter(tag);
    }).toList();
  }

  /// Default filter using display values
  bool _defaultFilter(T tag) {
    final displayValue =
        widget.displayValueBuilder?.call(tag) ?? tag.toString();
    return displayValue.toLowerCase().contains(_currentInput.toLowerCase());
  }

  /// Adds a tag to the selection
  void _addTag(T tag) {
    setState(() {
      _selectedTags.add(tag);
      _currentInput = '';
      _controller.clear();
    });
    _notifyTagsChanged();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  /// Handles text input changes
  void _handleTextInput(String text) {
    setState(() => _currentInput = text);
    _overlayEntry?.markNeedsBuild();

    if (text.endsWith(' ')) {
      _handleTagCreation(text.trim());
    }
  }

  /// Processes tag creation from text input
  void _handleTagCreation(String text) {
    if (text.isEmpty) return;

    final existing = _findExistingTag(text);
    if (existing != null) {
      _addTag(existing);
    } else if (widget.allowCustomTags) {
      _createCustomTag(text);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  /// Finds existing tag matching input text
  T? _findExistingTag(String text) {
    try {
      return widget.suggestions.firstWhere((tag) {
        final displayValue =
            widget.displayValueBuilder?.call(tag) ?? tag.toString();
        return displayValue == text;
      });
    } on StateError {
      return null;
    }
  }

  /// Creates custom tag from input text
  void _createCustomTag(String text) {
    final tag =
        widget.onCreateCustomTag != null
            ? widget.onCreateCustomTag!(text)
            : text as T;

    _addTag(tag);
  }

  /// Notifies parent widget about tag changes
  void _notifyTagsChanged() {
    widget.onTagsChanged?.call(List<T>.from(_selectedTags));
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      key: _compositedKey,
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: InputDecorator(
          isFocused: _focusNode.hasFocus,
          isEmpty: _selectedTags.isEmpty && !_focusNode.hasFocus,
          decoration: widget.inputDecoration.copyWith(
            constraints: const BoxConstraints(minHeight: 50),
          ),
          child: Wrap(
            spacing: 4,
            children: [..._selectedTags.map(_buildChip), _buildInputField()],
          ),
        ),
      ),
    );
  }

  /// Handles tap events to focus the input
  void _handleTap() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  /// Builds individual tag chips
  Widget _buildChip(T tag) {
    return widget.tagBuilder?.call(context, tag, () => _removeTag(tag)) ??
        Chip(
          label: Text(widget.displayValueBuilder!(tag)),
          onDeleted: () => _removeTag(tag),
        );
  }

  /// Removes a tag from selection
  void _removeTag(T tag) {
    setState(() => _selectedTags.remove(tag));
    _notifyTagsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  /// Builds the input field widget
  Widget _buildInputField() {
    return Visibility(
      maintainState: true,
      maintainSize: false,
      maintainAnimation: true,
      visible: _focusNode.hasFocus,
      child: AnimatedSize(
        duration: _animationDuration,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 50,
              maxWidth: 120,
              minHeight: 25,
              maxHeight: 40,
            ),
            child: EditableText(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _handleTextInput,
              backgroundCursorColor: Colors.grey,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              cursorColor:
                  widget.inputDecoration.focusedBorder?.borderSide.color ??
                  Theme.of(context).colorScheme.primary,
              minLines: 1,
              maxLines: 1,
              autofocus: false,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ),
        ),
      ),
    );
  }
}
// endregion