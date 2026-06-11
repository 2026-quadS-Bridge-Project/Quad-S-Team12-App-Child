import 'package:bridge_k/core/auth/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'saveLogin clears optional profile values missing from a fresh login',
    () async {
      await AuthSession.saveLogin(
        username: 'child-a',
        memberId: '11',
        name: 'Child A',
        childCode: 'CODE-A',
      );

      await AuthSession.saveLogin(username: 'child-b');

      expect(await AuthSession.username(), 'child-b');
      expect(await AuthSession.memberId(), isNull);
      expect(await AuthSession.name(), isNull);
      expect(await AuthSession.childCode(), isNull);
    },
  );

  test(
    'saveProfile preserves existing optional values when refresh omits them',
    () async {
      await AuthSession.saveLogin(
        username: 'child-a',
        memberId: '11',
        name: 'Child A',
        childCode: 'CODE-A',
      );

      await AuthSession.saveProfile();

      expect(await AuthSession.memberId(), '11');
      expect(await AuthSession.name(), 'Child A');
      expect(await AuthSession.childCode(), 'CODE-A');
    },
  );
}
