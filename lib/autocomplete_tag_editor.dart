import 'package:flutter/material.dart';

/// Signature for building display strings from generic type [T]
typedef DisplayValueBuilder<T> = String Function(T option);

/// Signature for creating custom tags of type [T] from string input
typedef CreateCustomTag<T> = T Function(String input);

class AutoCompleteTagEditor<T> extends StatefulWidget {
  /// List of available suggestions for autocomplete
  final List<T> suggestions;

  /// Initially selected tags
  final List<T> value;

  /// Decoration for the input field
  final InputDecoration inputDecoration;

  /// Called when the list of selected tags changes
  final ValueChanged<List<T>>? onTagsChanged;

  /// Converts [T] item to display string
  final DisplayValueBuilder<T> displayValueBuilder;

  /// Whether to allow creating tags not in suggestions
  final bool allowCustomTags;

  /// Creates [T] from custom string input. Required when [T] is not String
  /// and [allowCustomTags] is true
  final CreateCustomTag<T>? onCreateCustomTag;

  const AutoCompleteTagEditor({
    super.key,
    required this.suggestions,
    required this.value,
    required this.displayValueBuilder,
    this.inputDecoration = const InputDecoration(),
    this.allowCustomTags = false,
    this.onTagsChanged,
    this.onCreateCustomTag,
  }) : assert(
         !allowCustomTags || T == String || onCreateCustomTag != null,
         'When using custom types with allowCustomTags=true, '
         'you must provide the onCreateCustomTag callback',
       ),
       assert(
         T == String || onCreateCustomTag == null || allowCustomTags,
         'onCreateCustomTag should only be provided when allowCustomTags=true',
       );

  @override
  AutoCompleteTagEditorState<T> createState() =>
      AutoCompleteTagEditorState<T>();
}

class AutoCompleteTagEditorState<T> extends State<AutoCompleteTagEditor<T>> {
  // Add a key for tracking the composited target
  final GlobalKey _compositedKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final List<T> _selectedTags = [];
  final Duration _animationDuration = const Duration(milliseconds: 200);

  OverlayEntry? _overlayEntry;
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

  /// Handles focus changes and overlay visibility
  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _controller.clear();
      _hideOverlay();
    }
    if (mounted) setState(() {});
  }

  /// Shows suggestions overlay
  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hides suggestions overlay
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Creates overlay entry for suggestions list
  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        // Get current render box position
        final renderBox =
            _compositedKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return Container();

        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);

        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4, // 4px margin
          width: size.width,
          child: _buildSuggestions(),
        );
      },
    );
  }

  /// Builds suggestions list widget
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

  /// Determines if we should show the empty state prompting for new tag creation
  bool _shouldShowEmptyState(List<T> suggestions) {
    return _controller.text.isNotEmpty && suggestions.isEmpty;
  }

  /// Builds empty state widget when no suggestions match
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Create new tag: ${_controller.text}'),
    );
  }

  /// Builds list of suggestion tiles
  Widget _buildSuggestionList(List<T> suggestions) {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: suggestions.map(_buildSuggestionTile).toList(),
    );
  }

  /// Builds individual suggestion list tile
  Widget _buildSuggestionTile(T option) {
    return ListTile(
      dense: true,
      title: Text(widget.displayValueBuilder(option)),
      onTap: () => _addTag(option),
    );
  }

  /// Filters suggestions based on current input and selected tags
  List<T> _getFilteredSuggestions() {
    return widget.suggestions.where((tag) {
      final tagText = widget.displayValueBuilder(tag).toLowerCase();
      return !_selectedTags.contains(tag) &&
          tagText.contains(_currentInput.toLowerCase());
    }).toList();
  }

  /// Adds tag to selection and updates state
  void _addTag(T tag) {
    setState(() {
      _selectedTags.add(tag);
      _currentInput = '';
      _controller.clear();
    });
    _notifyTagsChanged();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild(); // Force overlay reposition
    });
  }

  /// Handles text input changes and automatic tag creation
  void _handleTextInput(String text) {
    setState(() => _currentInput = text);
    _overlayEntry?.markNeedsBuild();

    if (text.endsWith(' ')) {
      _handleTagCreation(text.trim());
    }
  }

  /// Attempts to create tag from current input
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
      return widget.suggestions.firstWhere(
        (tag) => widget.displayValueBuilder(tag) == text,
      );
    } on StateError {
      return null;
    }
  }

  /// Handles custom tag creation logic
  void _createCustomTag(String text) {
    final tag =
        widget.onCreateCustomTag != null
            ? widget.onCreateCustomTag!(text)
            : text as T;

    _addTag(tag);
  }

  /// Notifies parent of tag changes
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

  /// Handles tap gesture for focus management
  void _handleTap() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  /// Builds individual tag chip
  Widget _buildChip(T tag) {
    return Chip(
      label: Text(widget.displayValueBuilder(tag)),
      onDeleted: () => _removeTag(tag),
    );
  }

  /// Removes tag from selection
  void _removeTag(T tag) {
    setState(() => _selectedTags.remove(tag));
    _notifyTagsChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild(); // Force overlay reposition
    });
  }

  /// Builds input field with visibility management
  Widget _buildInputField() {
    return Visibility(
      maintainState: true,
      maintainSize: false,
      maintainAnimation: true,
      visible: _focusNode.hasFocus,
      child: AnimatedSize(
        duration: _animationDuration,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 70,
            maxWidth: 150,
            minHeight: 30,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
