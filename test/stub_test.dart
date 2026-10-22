@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:web_address_bar/web_address_bar.dart';

void main() {
  test('is a no-op off the web', () {
    WebAddressBar.enable();
    expect(WebAddressBar.isActive, isFalse);
    expect(WebAddressBar.collapsedExtent.value, 0);
    WebAddressBar.disable();
    expect(WebAddressBar.isActive, isFalse);
  });
}
