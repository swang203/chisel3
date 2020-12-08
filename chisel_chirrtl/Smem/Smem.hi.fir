circuit Smem :
  module Smem :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip addr : UInt<10>, dataOut : UInt<32>}

    mem mem : @[Smem.scala 15:24]
      data-type => UInt<32>
      depth => 1024
      read-latency => 1
      write-latency => 1
      reader => io_dataOut_MPORT
      read-under-write => undefined
    mem.io_dataOut_MPORT.addr is invalid @[Smem.scala 15:24]
    mem.io_dataOut_MPORT.clk is invalid @[Smem.scala 15:24]
    mem.io_dataOut_MPORT.en <= UInt<1>("h0") @[Smem.scala 15:24]
    node _io_dataOut_T = gt(io.addr, UInt<8>("hc8")) @[Smem.scala 18:43]
    wire _io_dataOut_WIRE : UInt<10> @[Smem.scala 18:25]
    _io_dataOut_WIRE is invalid @[Smem.scala 18:25]
    when _io_dataOut_T : @[Smem.scala 18:25]
      _io_dataOut_WIRE <= io.addr @[Smem.scala 18:25]
      node _io_dataOut_T_1 = or(_io_dataOut_WIRE, UInt<10>("h0")) @[Smem.scala 18:25]
      node _io_dataOut_T_2 = bits(_io_dataOut_T_1, 9, 0) @[Smem.scala 18:25]
      mem.io_dataOut_MPORT.en <= UInt<1>("h1") @[Smem.scala 18:25]
      mem.io_dataOut_MPORT.addr <= _io_dataOut_T_2 @[Smem.scala 18:25]
      mem.io_dataOut_MPORT.clk <= clock @[Smem.scala 18:25]
    io.dataOut <= mem.io_dataOut_MPORT.data @[Smem.scala 18:14]