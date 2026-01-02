extension StringUtils on String? {
  bool get hasValue {
    final value = this;
    if (value == null) return false;

    String trimValue = value.trim();
    return trimValue.isNotEmpty;
  }

  String get newLineSterilize {
    String value = this ?? '';
    while (value.contains('\n\n')) {
      value = value.replaceAll('\n\n', '\n');
    }
    return value;
  }
}
