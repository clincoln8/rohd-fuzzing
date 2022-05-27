## Counter Example
This dir contains an example testbench that is fully 'fuzzable' with Dust. The original counter and counter_vf files were written by Max Korbel of Intel and have been expanded on for demonstration purposes. 

The buggy_counter.dart reverts its output val to 3 anytime the value is greater than or equal to 4. This violates the invariant that a counter's output should increase by 1 at every clock cycle. 

Fuzzing the buggy_counter_vf.dart testbench with Dust produces a failing input when running

```
dart run dust -y 0,1 -i 30 -f /path/to/failing/dir /path/to/examples/counter/buggy_counter_vf.dart
```

A failing input for this example is any input that sets enable to high for more than 4 clock cycles.