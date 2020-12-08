circuit Adder :
  module Adder :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip in0 : UInt<8>, flip in1 : UInt<8>, out : UInt<8>}

    node _io_out_T = add(io.in0, io.in1) @[Adder.scala 17:20]
    node _io_out_T_1 = tail(_io_out_T, 1) @[Adder.scala 17:20]
    io.out <= _io_out_T_1 @[Adder.scala 17:10]