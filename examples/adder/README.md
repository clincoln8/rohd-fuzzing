# Adder DUT Example

This is an example of fuzzing a ROHD design which has multiple input ports with bit width >1.

The `Adder` module has a bug so that the final carry (`d_c`) is implemented in correctly. This causes an error when `in1` begins with a zero, but there is a carry from the previous bits (reading the buses from left to right).

For example, 0111 + 1111 (which is 7+15) should equal 10110 (which is 22). However because of the bug, this `Adder` will have an output of 00110 (which is 6). 

Running a dust fuzzing campaign successfully generated the input of `01111111111111111111` which translates to two DUTSeqItems: [[7, 15], [15, 15]].