import 'counter.dart';

import '../../bin/gen_dut_seq_item.dart';

void main() {
  final fileName = 'examples/counter/generated_counter_dutsi.dart';
  overwriteDUTSeqItem(Counter(CounterInterface()).intf, fileName);
}
