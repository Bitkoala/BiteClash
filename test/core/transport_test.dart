import 'package:fl_clash/common/constant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows Core pipe uses a 128-bit random suffix', () {
    expect(
      windowsPipeName,
      matches(RegExp(r'^\\\\\.\\pipe\\(FlClash|BiteClash)Core_[0-9a-f]{32}$')),
    );
  });
}
