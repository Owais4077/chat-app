import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/contacts/domain/phone_number.dart';

void main() {
  test('accepts a trimmed international phone number', () {
    expect(PhoneNumber.parse(' +923001234567 ').value, '+923001234567');
  });

  test('rejects a phone number without an international prefix', () {
    expect(() => PhoneNumber.parse('03001234567'), throwsFormatException);
  });
}
