import 'package:test/test.dart';
import 'generated_test_DUTSI.dart';

void main() {
  test('Test overwriteDUTSeqItem()', () async {
    DUTSeqItem dusti1 = DUTSeqItem([0]);

    expect(dusti1.en, equals(0));

    DUTSeqItem dusti2 = DUTSeqItem([1]);
    expect(dusti2.en, equals(1));
  });
}
