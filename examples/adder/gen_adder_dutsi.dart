import 'adder.dart';

import '../../bin/gen_dut_seq_item.dart';

void main() {
  final fileName = 'generated_dutsi.dart';
  overwriteDUTSeqItem(Adder(AdderInterface()).intf, fileName);
}
