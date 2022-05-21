# Blackbox Fuzzing ROHD Hardware Designs

Not recommended, use coverage-guided greybox fuzzing whenever possible.

## Background
This fuzzing technique applies [libFuzzer](https://llvm.org/docs/LibFuzzer.html), a C/C++ coverage-guided fuzzer, as a blackbox fuzzer for compiled Dart executables. 

The guiding motivation is to use existing tooling for fuzzing a language that does not have a lot of fuzzing support. Since Dart is a newer language, there are no "go-to" fuzzers for it. The workflow below demonstrates how to call an external executable from a C/C++ function. This function monitors stderr to determine if the executable threw any errors and alerts libFuzzer by throwing a runtime error within the function itself. 

Since the Dart code is compiled ahead of time and is written in Dart, there is no way for libFuzzer to instrument the code to get coverage metrics. Although blackbox fuzzing typically does not have great performance in finding bugs, using libFuzzer allows us to take advantage of its corpus generation functionalities. The hope is if good seeds are intially passed into the fuzzing campaign, there is higher chance of finding a crashing input.


## Workflow
Compile dart into machine code:

```
dart compile exe /path/to/testbench_vf.dart
```

Use the fuzz target provided in `fuzz.cc` and set the `executable` variable to the path of the compiled Dart executable.

The fuzz target parses the byte stream provided by libFuzzer into a binary string that is readily accepted by the ROHD-VF fuzzing harness.

Compile the target:
```
clang++ -fsanitize=fuzzer fuzz.cc
```

Begin fuzzing campaign:

```
./a.out
```

See libFuzzer docs for more information such as specifying a corpus directory.

