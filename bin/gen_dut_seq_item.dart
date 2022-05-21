import 'dart:io';
import 'package:rohd/rohd.dart';

List<String> importStatements = [
  "import 'package:rohd/rohd.dart';",
  "import 'package:rohd_vf/rohd_vf.dart';"
];

String constructDUTSeqItem(intf) {
// Handle DUTSequence Item
  List<String> memberVars = [];
  List<String> constructorSetters = [];
  List<String> portMapEntries = [];
  int portCount = 0;

  Map<String, Logic> ports = intf.getPorts();
  ports.forEach((portName, port) {
    // print("Port: $portName, Width: ${port.width}, isInput: ${port.isInput}");

    if (!port.isInput) return;
    if (portName == 'clk' || portName == 'clock') return;
    if (portName == 'rst' || portName == 'reset') return;

    memberVars.add('final int $portName;');
    constructorSetters.add('$portName = inputs[$portCount]');
    portMapEntries.add('ports["$portName"] = inputs[$portCount];');

    portCount++;
  });

  String dutSeqItem = [
    'class DUTSeqItem extends SequenceItem {',
    'final Map<String, int> ports = <String, int>{};',
    memberVars.join('\n'),
    'DUTSeqItem(List<int> inputs) : ${constructorSetters.join(',\n')} {',
    portMapEntries.join('\n'),
    '}',
    '}',
  ].join('\n');
  return dutSeqItem;
}

Future<bool> overwriteDUTSeqItem(Interface intf, String fileName,
    [List<String> importFiles = const []]) async {
  for (var importFile in importFiles) {
    importStatements.add("import '$importFile';");
  }
  String imports = importStatements.join('\n');

  String dutSeqItem = constructDUTSeqItem(intf);

  String vfContents = [imports, dutSeqItem].join('\n');

  var file = await File(fileName).writeAsString(vfContents);

  if (await file.length() > 0) return true;

  return false;
}
