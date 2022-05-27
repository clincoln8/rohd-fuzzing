/// Copyright (C) 2021 Intel Corporation
/// SPDX-License-Identifier: BSD-3-Clause
///
/// main.dart
/// Example of a complete ROHD-VF testbench
///
/// 2021 May 11
/// Author: Max Korbel <max.korbel@intel.com>
///

// Search for 'FUZZING MOD' tag to quickly see the changes from the ROHD-VF's
// original dut_vf.dart example in order to perform coverage based fuzzing

import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd_vf/rohd_vf.dart';

import 'adder.dart'; // FUZZING MOD (import buggy version of dut)

import 'generated_dutsi.dart'; // FUZZING MOD (add import)
import '../../bin/format_fuzzed_input.dart'; // FUZZING MOD (add import)

List<List<int>> fuzzedInputs = []; // FUZZING MOD

/// Main function entry point to execute this testbench.
Future<void> main(List<String> inputs, // FUZZING MOD
    {Level loggerLevel = Level.FINEST}) async {
  // Set the logger level
  Logger.root.level = loggerLevel;

  // Create the testbench
  var tb = TopTB();

  // Build the DUT
  await tb.dut.build();

  // Attach a waveform dumper to the DUT
  WaveDumper(tb.dut);

  // Set a maximum simulation time so it doesn't run forever
  Simulator.setMaxSimTime(300);

  fuzzedInputs = formatFuzzedInput(tb.dut.intf, inputs[0]); // FUZZING MOD

  // Create and start the test!
  var test = DUTTest(tb.dut);
  await test.start();
}

// Top-level testbench to bundle the DUT with a clock generator
class TopTB {
  // Instance of the DUT
  late final Adder dut;

  TopTB() {
    // Build an instance of the interface for the DUT
    var intf = AdderInterface(inWidth: 4, outWidth: 5);

    // Connect a generated clock to the interface
    intf.clk <= SimpleClockGenerator(10).clk;

    // Create the DUT, passing it our interface
    dut = Adder(intf);
  }
}

/// A simple test that brings the [DUT] out of reset and wiggles the enable.
class DUTTest extends Test {
  /// The [DUT] device under test.
  final Adder dut;

  /// The test environment for [dut].
  late final DUTEnv env;

  /// A private, local pointer to the test environment's [Sequencer].
  late final DUTSequencer _dutSequencer;

  DUTTest(this.dut, {String name = 'dutTest'}) : super(name) {
    env = DUTEnv(dut.intf, this);
    _dutSequencer = env.agent.sequencer;
  }

  // A "time consuming" method, similar to `task` in SystemVerilog, which
  // waits for a given number of cycles before completing.
  Future<void> waitCycles(int numCycles) async {
    for (var i = 0; i < numCycles; i++) {
      await dut.clk.nextNegedge;
    }
  }

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));

    // Raise an objection at the start of the test so that the
    // simulation doesn't end before stimulus is injected
    var obj = phase.raiseObjection('dut_test');

    logger.info('Running the test...');

    // Add some simple reset behavior at specified timestamps
    Simulator.registerAction(1, () {
      dut.intf.reset.put(0);
    });
    Simulator.registerAction(3, () {
      dut.intf.reset.put(1);
    });
    Simulator.registerAction(35, () {
      dut.intf.reset.put(0);
    });

    // Add an individual SequenceItem to set enable to 0 at the start
    _dutSequencer.add(DUTSeqItem([0, 0])); // FUZZING MOD

    // Wait for the next negative edge of reset
    await dut.intf.reset.nextNegedge;

    // Wait 3 more cycles
    await waitCycles(3);

    logger.info('Adding stimulus to the sequencer');

    // Kick off a sequence on the sequencer
    await _dutSequencer
        .start(DUTSequence()); // FUZZING MOD (convert to DUTSequence)

    logger.info('Done adding stimulus to the sequencer');

    // Done adding stimulus, we can drop our objection now
    obj.drop();
  }
}

/// Environment to bundle the testbench for the [DUT].
class DUTEnv extends Env {
  /// An instance of the interface to the [DUT].
  final AdderInterface intf;

  /// The agent that communicates with the [DUT].
  late final DUTAgent agent;

  /// A scoreboard for checking functionality of the [DUT].
  late final DUTScoreboard scoreboard;

  DUTEnv(this.intf, Component parent, {String name = 'dutEnv'})
      : super(name, parent) {
    agent = DUTAgent(intf, this);
    scoreboard = DUTScoreboard(
        agent.inMonitor.stream, agent.outMonitor.stream, intf, this);
  }

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));
  }
}

/// An agent to bundle the sequencer, driver, and monitors for one [DUT].
class DUTAgent extends Agent {
  final AdderInterface intf;
  late final DUTSequencer sequencer;
  late final DUTDriver driver;
  late final DUTInMonitor inMonitor;
  late final DUTOutMonitor outMonitor;

  DUTAgent(this.intf, Component parent, {String name = 'dutAgent'})
      : super(name, parent) {
    sequencer = DUTSequencer(this);
    driver = DUTDriver(intf, sequencer, this);
    inMonitor = DUTInMonitor(intf, this);
    outMonitor = DUTOutMonitor(intf, this);
  }
}

/// A basic [Sequencer] for the [DUT].
class DUTSequencer extends Sequencer<DUTSeqItem> {
  // FUZZING MOD - convert to <DUTSeqItem>
  DUTSequencer(Component parent, {String name = 'dutSequencer'})
      : super(name, parent);
}

// A simple sequence that sends a variable number of 0->1->0 transitions
// FUZZING MOD
class DUTSequence extends Sequence {
  DUTSequence({String name = 'dutSequence'}) : super(name);

  @override
  Future<void> body(Sequencer sequencer) async {
    var dutSequencer = sequencer as DUTSequencer;
    for (var fuzzedInput in fuzzedInputs) {
      dutSequencer.add(DUTSeqItem(fuzzedInput));
    }
  }
}

/// A driver for the enable signal on the [DUT].
class DUTDriver extends Driver<DUTSeqItem> {
  // FUZZING MOD - convert to <DUTSeqItem>
  final AdderInterface intf;

  // Keep a queue of items from the sequencer to be driven when desired
  final Queue _pendingItems = Queue<DUTSeqItem>(); // FUZZING MOD (<DUTSeqItem>)

  Objection? _driverObjection;

  DUTDriver(this.intf, DUTSequencer sequencer, Component parent,
      {String name = 'dutDriver'})
      : super(name, parent, sequencer: sequencer);

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));

    logger.finest('Fuzzed inputs: $fuzzedInputs');

    // Listen to new items coming from the sequencer, and add them to a queue
    sequencer.stream.listen((newItem) {
      _driverObjection ??= phase.raiseObjection('dut_driver')
        ..dropped.then((value) => logger.fine('Driver objection dropped'));
      _pendingItems.add(newItem);
      print('adding to queue: ${newItem.in1},${newItem.in2}');
    });

    // Every clock negative edge, drive the next pending item if it exists
    intf.clk.negedge.listen((args) {
      if (_pendingItems.isNotEmpty) {
        var nextItem = _pendingItems.removeFirst();
        drive(nextItem);
      } else {
        _driverObjection?.drop();
        _driverObjection = null;
      }
    });
  }

  // Translate a SequenceItem into pin wiggles
  // FUZZING MOD
  void drive(DUTSeqItem? item) {
    if (item == null) {
      // set all inputs to 0
      intf.getPorts().forEach((portName, port) => port.inject(0));
    } else {
      // directly feed each input from the SequenceItem to the DUT Interface Ports
      item.ports.forEach((portName, val) => intf.port(portName).inject(val));
    }
  }
}

/// A monitor for the value output of the [DUT]].
class DUTOutMonitor extends Monitor<LogicValue> {
  /// Instance of the [Interface] to the DUT.
  final AdderInterface intf;

  DUTOutMonitor(this.intf, Component parent, {String name = 'dutOutMonitor'})
      : super(name, parent);

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));

    // Every positive edge of the clock
    intf.clk.posedge.listen((event) {
      // Send out an event with the value of the dut
      add(intf.out.value);
    });
  }
}

/// A monitor for the enable signal of the [DUT].
class DUTInMonitor extends Monitor<List<LogicValue>> {
  // FUZZING MOD - convert to <DUTSeqItem>
  /// Instance of the [Interface] to the DUT.
  final AdderInterface intf;

  DUTInMonitor(this.intf, Component parent, {String name = 'dutInMonitor'})
      : super(name, parent);

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));

    // Every positive edge of the clock
    intf.clk.posedge.listen((event) {
      // If the enable bit on the interface is 1
      add([
        intf.in1.value,
        intf.in2.value
      ]); // FUZZING MOD (convert arg to List<int>)
    });
  }
}

/// A scoreboard to check that the value output from the [DUT] matches
/// expectations based on the clk, enable, and reset signals.
class DUTScoreboard extends Component {
  /// A stream which pops out a `true` every time enable is high.
  final Stream<List<LogicValue>> inStream;

  /// A stream which sends out the current value out of the dut once per cycle.
  final Stream<LogicValue> outStream;

  /// An instance of the interface to the [DUT].
  final AdderInterface intf;

  DUTScoreboard(this.inStream, this.outStream, this.intf, Component parent,
      {String name = 'dutScoreboard'})
      : super(name, parent);

  /// The most recent value recieved on [valueStream].
  int? a;
  int? b;
  int? seenOut;

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));

    await intf.reset.nextNegedge;

    // record if we've seen an enable this cycle
    inStream.listen((event) {
      logger.finest('Detected inputs on dut: $event');

      a = event[0].toInt();
      b = event[1].toInt();
    });

    // record the value we saw this cycle
    outStream.listen((event) {
      seenOut = event.toInt();
    });

    // check values on negative edge
    intf.clk.negedge.listen((event) {
      int expected = a! + b!;

      var matchesExpectations = seenOut == expected;

      if (!matchesExpectations) {
        logger.severe('Expected $expected but saw $seenOut');
        //throw ('Expected $expected but saw $seenOut'); // FUZZING MOD
      } else {
        logger.finest('DUT value matches expectations with $seenOut');
      }
    });
  }
}
