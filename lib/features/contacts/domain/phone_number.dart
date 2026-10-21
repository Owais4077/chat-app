class PhoneNumber {
  const PhoneNumber._(this.value);

  final String value;

  static final _e164 = RegExp(r'^\+[1-9][0-9]{7,14}$');

  factory PhoneNumber.parse(String input) {
    final normalized = input.trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (!_e164.hasMatch(normalized)) {
      throw const FormatException(
        'Use an international number, for example +923001234567.',
      );
    }
    return PhoneNumber._(normalized);
  }
}
