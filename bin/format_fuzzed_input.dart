import 'package:rohd/rohd.dart';
import 'package:collection/collection.dart';

List<List<int>> formatFuzzedInput(Interface intf, String fuzzedInput) {
  List<List<int>> sequence = [];

  Map<String, Logic> ports = intf.getPorts();

  List<int> portWidths = [];
  ports.forEach((portName, port) {
    if (portName == 'clk' || portName == 'clock') return;
    if (portName == 'rst' || portName == 'reset') return;
    if (port.isInput) portWidths.add(port.width);
  });
  int sumPortWidths = portWidths.sum;

  if (fuzzedInput.length < sumPortWidths) return [];

  for (int i = 0; i + sumPortWidths <= fuzzedInput.length; i += sumPortWidths) {
    List<int> seqItem = [];
    int j = 0;
    for (var portWidth in portWidths) {
      int inputVal =
          int.parse(fuzzedInput.substring(i + j, i + j + portWidth), radix: 2);
      seqItem.add(inputVal);
      j += portWidth;
    }
    sequence.add(seqItem);
  }

  return sequence;
}
