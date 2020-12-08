circuit Functionality :
  module Functionality :
    input clock : Clock
    input reset : UInt<1>
    input io_x : UInt<16>
    input io_y : UInt<16>
    output io_z : UInt<16>

    node _T = and(io_x, io_y) @[Functionality.scala 13:8]
    node _T_1 = not(io_x) @[Functionality.scala 13:16]
    node _T_2 = and(_T_1, io_y) @[Functionality.scala 13:19]
    node _T_3 = or(_T, _T_2) @[Functionality.scala 13:13]
    io_z <= _T_3 @[Functionality.scala 14:8]