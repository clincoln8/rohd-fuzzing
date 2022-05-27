import 'package:rohd/rohd.dart';
import 'package:rohd_vf/rohd_vf.dart';
class DUTSeqItem extends SequenceItem {
final Map<String, int> ports = <String, int>{};
final int in1;
final int in2;
DUTSeqItem(List<int> inputs) : in1 = inputs[0],
in2 = inputs[1] {
ports["in1"] = inputs[0];
ports["in2"] = inputs[1];
}
}