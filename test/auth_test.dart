import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/state.dart';

void main() {
  final app = AppState();

  test('attendant number matches in any common format', () {
    for (final number in [
      '020 000 0001',
      '0200000001',
      '+233 20 000 0001',
      '233200000001',
      '20 000 0001',
    ]) {
      expect(
        app.authenticate(number, 'attend123')?.role,
        Role.attendant,
        reason: number,
      );
    }
  });

  test('stray spaces around the password are ignored', () {
    expect(app.authenticate('024 555 0187', ' driver123 ')?.role, Role.driver);
  });

  test('wrong or differently-cased password is rejected', () {
    expect(app.authenticate('020 000 0001', 'wrong'), isNull);
    expect(app.authenticate('020 000 0001', 'Attend123'), isNull);
  });

  test('duplicate check recognises +233 format', () {
    expect(app.findDuplicate('+233 24 555 0187', ''), isNotNull);
  });
}
