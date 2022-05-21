import 'package:test/test.dart';
import '../examples/counter/counter.dart';
import '../bin/gen_dut_seq_item.dart';

String counterSeqItem = '''class DUTSeqItem extends SequenceItem {
  final Map<String, int> ports = <String, int>{};
  final int en;
  DUTSeqItem(List<int> inputs) : en = inputs[0] {
  ports["en"] = inputs[0];
}
}''';

void main() {
  test('Test constructDUTSeqItem()', () {
    String dutSeqItem = constructDUTSeqItem(Counter(CounterInterface()).intf);
    expect(dutSeqItem, equalsIgnoringWhitespace(counterSeqItem));
  });

  test('Test overwriteDUTSeqItem()', () async {
    String fileName = 'test/generated_test_DUTSI.dart';

    bool success =
        await overwriteDUTSeqItem(Counter(CounterInterface()).intf, fileName);

    expect(success, equals(true));
  });
}
