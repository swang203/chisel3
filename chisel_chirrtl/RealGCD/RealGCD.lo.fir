circuit RealGCD :
  module RealGCD :
    input clock : Clock
    input reset : UInt<1>
    output io_in_ready : UInt<1>
    input io_in_valid : UInt<1>
    input io_in_bits_a : UInt<16>
    input io_in_bits_b : UInt<16>
    output io_out_valid : UInt<1>
    output io_out_bits : UInt<16>

    reg x : UInt<16>, clock with :
      reset => (UInt<1>("h0"), x) @[RealGCD.scala 22:14]
    reg y : UInt<16>, clock with :
      reset => (UInt<1>("h0"), y) @[RealGCD.scala 23:14]
    reg p : UInt<1>, clock with :
      reset => (UInt<1>("h0"), p) @[RealGCD.scala 24:18]
    node _T = eq(p, UInt<1>("h0")) @[RealGCD.scala 26:18]
    node _T_1 = eq(p, UInt<1>("h0")) @[RealGCD.scala 28:24]
    node _T_2 = and(io_in_valid, _T_1) @[RealGCD.scala 28:21]
    node _GEN_0 = mux(_T_2, io_in_bits_a, x) @[RealGCD.scala 28:28 RealGCD.scala 29:7 RealGCD.scala 22:14]
    node _GEN_1 = mux(_T_2, io_in_bits_b, y) @[RealGCD.scala 28:28 RealGCD.scala 30:7 RealGCD.scala 23:14]
    node _GEN_2 = mux(_T_2, UInt<1>("h1"), p) @[RealGCD.scala 28:28 RealGCD.scala 31:7 RealGCD.scala 24:18]
    node _T_3 = gt(x, y) @[RealGCD.scala 35:13]
    node _T_4 = sub(y, x) @[RealGCD.scala 36:28]
    node _T_5 = tail(_T_4, 1) @[RealGCD.scala 36:28]
    node _GEN_3 = mux(_T_3, y, _GEN_0) @[RealGCD.scala 35:19 RealGCD.scala 35:23]
    node _GEN_4 = mux(_T_3, x, _T_5) @[RealGCD.scala 35:19 RealGCD.scala 35:31 RealGCD.scala 36:23]
    node _GEN_5 = mux(p, _GEN_3, _GEN_0) @[RealGCD.scala 34:12]
    node _GEN_6 = mux(p, _GEN_4, _GEN_1) @[RealGCD.scala 34:12]
    node _T_6 = eq(y, UInt<1>("h0")) @[RealGCD.scala 40:21]
    node _T_7 = and(_T_6, p) @[RealGCD.scala 40:29]
    node _GEN_7 = mux(io_out_valid, UInt<1>("h0"), _GEN_2) @[RealGCD.scala 41:23 RealGCD.scala 42:7]
    io_in_ready <= _T @[RealGCD.scala 26:15]
    io_out_valid <= _T_7 @[RealGCD.scala 40:16]
    io_out_bits <= x @[RealGCD.scala 39:16]
    x <= _GEN_5
    y <= _GEN_6
    p <= mux(reset, UInt<1>("h0"), _GEN_7) @[RealGCD.scala 24:18 RealGCD.scala 24:18]