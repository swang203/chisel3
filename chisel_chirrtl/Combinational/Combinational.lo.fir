circuit Combinational :
  module Combinational :
    input clock : Clock
    input reset : UInt<1>
    input io_x : UInt<16>
    input io_y : UInt<16>
    output io_z : UInt<16>

    node _T = add(io_x, io_y) @[Combinational.scala 12:16]
    node _T_1 = tail(_T, 1) @[Combinational.scala 12:16]
    io_z <= _T_1 @[Combinational.scala 12:8]