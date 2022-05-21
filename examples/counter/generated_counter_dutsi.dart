import 'package:rohd/rohd.dart';
import 'package:rohd_vf/rohd_vf.dart';
class DUTSeqItem extends SequenceItem {
final Map<String, int> ports = <String, int>{};
final int en;
DUTSeqItem(List<int> inputs) : en = inputs[0] {
ports["en"] = inputs[0];
}
}