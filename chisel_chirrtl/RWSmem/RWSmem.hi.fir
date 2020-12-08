circuit RWSmem :
  module RWSmem :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip enable : UInt<1>, flip write : UInt<1>, flip addr : UInt<10>, flip dataIn : UInt<32>, dataOut : UInt<32>}

    mem mem : @[RWSmem.scala 15:24]
      data-type => UInt<32>
      depth => 1024
      read-latency => 1
      write-latency => 1
      readwriter => rdwrPort
      read-under-write => undefined
    mem.rdwrPort.addr is invalid @[RWSmem.scala 15:24]
    mem.rdwrPort.clk is invalid @[RWSmem.scala 15:24]
    mem.rdwrPort.wmode <= UInt<1>("h0") @[RWSmem.scala 15:24]
    mem.rdwrPort.en <= UInt<1>("h0") @[RWSmem.scala 15:24]
    mem.rdwrPort.wdata is invalid @[RWSmem.scala 15:24]
    mem.rdwrPort.wmask is invalid @[RWSmem.scala 15:24]
    io.dataOut is invalid @[RWSmem.scala 16:14]
    when io.enable : @[RWSmem.scala 17:19]
      mem.rdwrPort.addr <= io.addr @[RWSmem.scala 18:23]
      mem.rdwrPort.clk <= clock @[RWSmem.scala 18:23]
      mem.rdwrPort.en <= UInt<1>("h1") @[RWSmem.scala 18:23]
      mem.rdwrPort.wmask <= UInt<1>("h0") @[RWSmem.scala 18:23]
      when io.write : @[RWSmem.scala 19:21]
        mem.rdwrPort.wdata <= io.dataIn @[RWSmem.scala 19:32]
        mem.rdwrPort.wmask <= UInt<1>("h1") @[RWSmem.scala 19:32]
        mem.rdwrPort.wmode <= UInt<1>("h1") @[RWSmem.scala 19:32]
      else :
        io.dataOut <= mem.rdwrPort.rdata @[RWSmem.scala 20:34]