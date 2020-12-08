circuit Adder :
  module Adder :
    input clock : Clock
    input reset : UInt<1>
    input io_in0 : UInt<8>
    input io_in1 : UInt<8>
    output io_out : UInt<8>

    node _io_out_T = add(io_in0, io_in1) @[Adder.scala 17:20]
    node _io_out_T_1 = tail(_io_out_T, 1) @[Adder.scala 17:20]
    io_out <= _io_out_T_1 @[Adder.scala 17:10]