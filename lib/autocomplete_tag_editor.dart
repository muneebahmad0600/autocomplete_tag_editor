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

  /// Maximum number of suggestions to display
  /// (default: 5)
  final int maxSuggestionCount;

  /// Minimum space required below the input field to display suggestions
  /// (default: 300)
  /// This is used to determine if the suggestions should be displayed above or below the input field.
  /// If the available space below is less than this value, the suggestions will be displayed above.
  final int minimumSpaceRequiredBelow;

  /// Initially selected tags when widget is first rendered
  final List<T> value;

  /// Decoration for the inner input field
  final InputDecoration inputDecoration;

  // Text style for the innet input field
  final TextStyle? textStyle;

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
    this.maxSuggestionCount = 5,
    this.minimumSpaceRequiredBelow = 300,
    this.value = const [],
    this.displayValueBuilder,
    this.inputDecoration = const InputDecoration(),
    this.textStyle,
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
class AutoCompleteTagEditorState<T> extends State<AutoCompleteTagEditor<T>>
    with SingleTickerProviderStateMixin {
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

  /// Tracks if the suggestions overlay is currently visible
  bool _isOverlayVisible = false;

  /// Animation controller for overlay animations
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedTags.addAll(widget.value);
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _animationController.dispose();
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

  /// Displays the suggestions overlay with animation
  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOverlayVisible = true);
    _animationController.forward();
  }

  /// Hides the suggestions overlay with animation
  void _hideOverlay() {
    if (_overlayEntry == null) return;
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() => _isOverlayVisible = false);
      }
    });
  }

  /// Toggles the suggestions overlay
  void _toggleOverlay() {
    if (_isOverlayVisible) {
      _hideOverlay();
    } else {
      _focusNode.requestFocus();
      _showOverlay();
    }
  }

  /// Handles focus changes to show/hide suggestions overlay
  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _handleTagCreation(_controller.text);
      _hideOverlay();
    }
    if (mounted) setState(() {});
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
        final screenHeight = MediaQuery.of(context).size.height;

        // Calculate available space below
        final spaceBelow = screenHeight - offset.dy - size.height;
        final hasEnoughSpaceBelow =
            spaceBelow > widget.minimumSpaceRequiredBelow;

        // Calculate overlay height constraints
        final maxHeight =
            hasEnoughSpaceBelow ? spaceBelow - 16 : offset.dy - 16;

        final slideOffset = hasEnoughSpaceBelow ? 20.0 : -20.0;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              left: offset.dx,
              width: size.width,
              top:
                  hasEnoughSpaceBelow
                      ? offset.dy +
                          size.height +
                          4 +
                          (slideOffset * (1 - _animation.value))
                      : null,
              bottom:
                  hasEnoughSpaceBelow
                      ? null
                      : screenHeight -
                          offset.dy +
                          4 +
                          (slideOffset * (1 - _animation.value)),
              child: FadeTransition(
                opacity: _animation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(child: _buildSuggestions()),
                ),
              ),
            );
          },
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
      children:
          suggestions
              .take(widget.maxSuggestionCount)
              .map(_buildSuggestionTile)
              .toList(),
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
    // _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  /// Handles text input changes
  void _handleTextInput(String text) {
    setState(() => _currentInput = text);
    _overlayEntry?.markNeedsBuild();

    if (text.endsWith(',')) {
      _handleTagCreation(text.substring(0, text.length - 1));
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
            suffixIcon: IconButton(
              icon: Icon(
                _isOverlayVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color:
                    _focusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).hintColor,
              ),
              onPressed: _toggleOverlay,
            ),
          ),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [..._selectedTags.map(_buildChip), _buildInputField()],
          ),
        ),
      ),
    );
  }

  /// Handles tap events to focus the input and show suggestions
  void _handleTap() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    if (!_isOverlayVisible) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  /// Builds individual tag chips
  Widget _buildChip(T tag) {
    return widget.tagBuilder?.call(context, tag, () => _removeTag(tag)) ??
        Chip(
          label: Text(
            T == String ? tag.toString() : widget.displayValueBuilder!(tag),
          ),
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
            backgroundCursorColor: Colors.red,
            style:
                widget.textStyle ??
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
    );
  }
}

// endregion
