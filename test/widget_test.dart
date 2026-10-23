import 'package:bayan_ai/core/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app info constants are set', () {
    expect(kAppName, isNotEmpty);
    expect(kAppVersion, matches(RegExp(r'^\d+\.\d+\.\d+')));
  });
}
