# Coverage Guided Greybox Fuzzing of ROHD Hardware
This project uses a modified version of Dust, a coverage guided Dart fuzzer, to verify hardware designs implemented in Dart with Intel's ROHD framework.

## Generate the DUTSeqItem

Create a Dart script to create the DUTSequenceItem that extends ROHD-VF's SequenceItem class.

This script will call overwriteDUTSeqItem() from gen_dut_seq_item.dart which has the following arguments:

Interface intf: An instantiated interface component for the DUT. The DUTSeqItem is built entirely on this.
String fileName: Path to file to be generated or overwritten. This file path will need to be included in the testbench.
optional List<String> imports: Any additional imports

```
import '/path/to/DUTInterface.dart';
import '/path/to/DUT.dart'; // omit if DUT and Interface are in the same file

import '/path/to/gen_dut_seq_item.dart';

void main(){
    final fileName = 'path/to/generated_dutsi.dart';
    overwriteDUTSeqItem(DUT(DUTInterface()).intf, fileName);
}
```

Then execute with ```dart run path/to/script.dart```

Dependencies: package:rohd/rohd.dart

Make sure that the name of this class matches the name of the SeqItem class used in extending the Monitor, Sequencer and Driver components.

## Testbench Setup
Begin constructing the testbench for the DUT as instructed in the [ROHD-VF docs](https://github.com/intel/rohd-vf)

### Initialization and main
Include imports to the DUTSeqItem file and `/path/to/bin/format_fuzzed_input.dart`

Ensure main() accepts a List<String> argument as this is how the fuzzer will pass inputs into the fuzzer.

Create a global List<List<int>> object. 

In main, call formatFuzzedInput() with the testbench's TopTB instantiated interface **after** it has been built.

For example:  

``` 
List<List<int>> fuzzedInputs = [];

void main(List<String> inputs){

    var tb = TopTB();
    await tb.dut.build(); // assume the instance of the DUT within TopTB is dut

    ...
    
    // this must be called **after** build()
    fuzzedInputs = formatFuzzedInput(tb.dut.intf, inputs[0]); 

}
```

### Driver
In the testbench component that inherits from ROHD-VF's Driver, use the following drive function:

```
void drive(DUTSeqItem? item) {
    if (item == null) {
      // set all inputs to 0
      intf.getPorts().forEach((portName, port) => port.inject(0));
    } else {
      // directly feed each input from the SequenceItem to the DUT Interface Ports
      item.ports.forEach((portName, val) => intf.port(portName).inject(val));
    }
  }
```

The Driver's run() method which controls when the Sequences are fed to the interface can be customized by the user.


### Sequence 
Use this simple Sequence Component:
```
class DUTSequence extends Sequence {

  DUTSequence({String name = 'dutSequence'}) : super(name);

  @override
  Future<void> body(Sequencer sequencer) async {
    var dutSequencer = sequencer as DUTSequencer;
    for (var i = 0; i < fuzzedInputs.length; i++) {
      dutSequencer.add(DUTSeqItem(fuzzedInputs[i]));
    }
  }
}
```

### Scoreboard

Follow ROHD-VF's documentation for creating a Scoreboard component. Ensure that any invariant violations or test case failures **throws an error**. If an error is not thrown, then the fuzzer will not know that it has found a crashing or failing input.

### Sanity Checks
Ensure that Monitor, Sequencer and Driver components use DUTSeqItem or the DUTSeqItem class has been renamed to user's desire. 

## Fuzzing with Dust

Naivgate to the [Dust directory](https://github.com/clincoln8/dust) that has been modified for ROHD fuzzing.

Run the following in `/dust/` dir:

```dart run dust -y 0,1 -f path/to/failure_dir -c path/to/corpus_dir -i 30 path/to/testbench-vf.dart```

-y indicates comma separated list of valid chars used to generate new inputs. 

-i indicates the interval in secondsto print progess updates

-f indicates the directory for storing uniquely failing inputs.

-c indicates the directory for storing inputs that explore interesting paths through execution

For further information, see the [Dust docs](https://github.com/clincoln8/dust).

## Caveats

### Avoiding Automation
The above optional automation of generating the DUTSeqItem. This can be hardcoded directly in the testbench or manually modified, however there are a few mandatory requirements:
1. The constructor must take a List<int> where each input corresponds to a single port on the DUT.
2. The Map<String, int> ports must be maintained where the key is the name of the port and value is the value from fuzzed inputs.
3. All getters must be consistent with the name of the port.