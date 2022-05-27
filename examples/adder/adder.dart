/// adder.dart
/// A simple adder module
///
/// 2022 May 20
/// Author: Christie Ellks
///
import 'package:rohd/rohd.dart';

enum AdderDirection { inward, outward, misc }

/// A simple [Interface] for [Counter].
class AdderInterface extends Interface<AdderDirection> {
  Logic get in1 => port('in1');
  Logic get in2 => port('in2');
  Logic get reset => port('reset');
  Logic get out => port('out');
  Logic get clk => port('clk');

  final int inWidth;
  final int outWidth;

  AdderInterface({this.inWidth = 4, this.outWidth = 5}) {
    setPorts([Port('in1', inWidth), Port('in2', inWidth), Port('reset')],
        [AdderDirection.inward]);

    setPorts([
      Port('out', outWidth),
    ], [
      AdderDirection.outward
    ]);

    setPorts([Port('clk')], [AdderDirection.misc]);
  }
}

/// A simple adder which adds the [in1] and [in2] and sets the result in [out].
class Adder extends Module {
  Logic get in1 => input('in1');
  Logic get in2 => input('in2');
  Logic get reset => input('reset');
  Logic get out => output('out');
  Logic get clk => input('clk');

  late final AdderInterface intf;

  Adder(AdderInterface intf) : super(name: 'counter') {
    this.intf = AdderInterface(inWidth: intf.inWidth, outWidth: intf.outWidth)
      ..connectIO(this, intf,
          inputTags: {AdderDirection.inward, AdderDirection.misc},
          outputTags: {AdderDirection.outward});

    _buildLogic();
  }

  void _buildLogic() {
    var nextVal = Logic(name: 'nextVal', width: intf.outWidth);

    var a = Logic(),
        b = Logic(),
        c = Logic(),
        d = Logic(),
        e = Logic(),
        a_c = Logic(),
        b_c = Logic(),
        c_c = Logic(),
        d_c = Logic();

    // a <= in1[0] ^ in2[0];
    // a_c <= in1[0] & in2[0];

    // b <= (in1[1] ^ in2[1]) ^ a_c;

    // b_c <= in1[1] & in2[1];

    // c <= in1[2] ^ in2[2] ^ b_c;

    // c_c <= in1[2] & in2[2];

    // d <= in1[3] ^ in2[3] ^ c_c;
    // d_c <= in1[3] & in2[3];

    a <= in1[0] + in2[0];
    a_c <= in1[0] & in2[0];

    b <= (in1[1] + in2[1]) + a_c;

    b_c <= (in1[1] & (in2[1] | a_c)) | (in2[1] & (in1[1] | a_c));

    c <= in1[2] + in2[2] + b_c;

    c_c <= (in1[2] & (in2[2] | b_c)) | (in2[2] & (in1[2] | b_c));

    d <= in1[3] + in2[3] + c_c;
    // d_c <= (in1[3] & (in2[3] | c_c)) | (in2[3] & (in1[3] | c_c)); correct
    d_c <= (in1[3] & (in2[3] | c_c));

    nextVal <= [a, b, c, d, d_c].rswizzle();

    Sequential(clk, [
      If(reset, then: [out < 0], orElse: [out < nextVal])
    ]);
  }
}
