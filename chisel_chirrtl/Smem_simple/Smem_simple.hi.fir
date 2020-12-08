circuit Smem_simple :
  module Smem_simple :
    input clock : Clock
    output io : { flip enable : UInt<1>, flip addr : UInt<10>, dataOut : UInt<32>}

    mem mem : @[Smem.scala 15:24]
      data-type => UInt<32>
      depth => 1024
      read-latency => 1
      write-latency => 1
      reader => rdport
      read-under-write => undefined
    mem.rdport.addr is invalid @[Smem.scala 15:24]
    mem.rdport.clk is invalid @[Smem.scala 15:24]
    mem.rdport.en <= UInt<1>("h0") @[Smem.scala 15:24]
    when io.enable : @[Smem.scala 18:25]
      mem.rdport.addr <= io.addr @[Smem.scala 18:25]
      mem.rdport.clk <= clock @[Smem.scala 18:25]
      mem.rdport.en <= UInt<1>("h1") @[Smem.scala 18:25]
    io.dataOut <= mem.rdport.data @[Smem.scala 18:14]