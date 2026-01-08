extension StringUtils on String? {
  /// True when the string is non-null and contains non-whitespace characters.
  bool get hasValue {
    final value = this;
    if (value == null) return false;

    String trimValue = value.trim();
    return trimValue.isNotEmpty;
  }

  /// Collapse consecutive blank lines into a single newline.
  String get newLineSterilize {
    String value = this ?? '';
    while (value.contains('\n\n')) {
      value = value.replaceAll('\n\n', '\n');
    }
    return value;
  }

  /// Collapse consecutive spaces into a single space.
  String get spaceSterilize {
    String value = this ?? '';
    while (value.contains('  ')) {
      value = value.replaceAll('  ', ' ');
    }
    return value;
  }
}
