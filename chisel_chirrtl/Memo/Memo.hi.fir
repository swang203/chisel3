circuit Memo :
  module Memo :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip wen : UInt<1>, flip wrAddr : UInt<8>, flip wrData : UInt<8>, flip ren : UInt<1>, flip rdAddr : UInt<8>, rdData : UInt<8>}

    mem mem : @[Memo.scala 23:16]
      data-type => UInt<8>
      depth => 256
      read-latency => 0
      write-latency => 1
      reader => _T_1
      writer => _T
      read-under-write => undefined
    mem._T_1.addr is invalid @[Memo.scala 23:16]
    mem._T_1.clk is invalid @[Memo.scala 23:16]
    mem._T_1.en <= UInt<1>("h0") @[Memo.scala 23:16]
    mem._T.addr is invalid @[Memo.scala 23:16]
    mem._T.clk is invalid @[Memo.scala 23:16]
    mem._T.en <= UInt<1>("h0") @[Memo.scala 23:16]
    mem._T.data is invalid @[Memo.scala 23:16]
    mem._T.mask is invalid @[Memo.scala 23:16]
    when io.wen : @[Memo.scala 26:17]
      mem._T.addr <= io.wrAddr @[Memo.scala 26:22]
      mem._T.clk <= clock @[Memo.scala 26:22]
      mem._T.en <= UInt<1>("h1") @[Memo.scala 26:22]
      mem._T.mask <= UInt<1>("h0") @[Memo.scala 26:22]
      mem._T.data <= io.wrData @[Memo.scala 26:34]
      mem._T.mask <= UInt<1>("h1") @[Memo.scala 26:34]
    io.rdData <= UInt<1>("h0") @[Memo.scala 29:13]
    when io.ren : @[Memo.scala 30:17]
      mem._T_1.addr <= io.rdAddr @[Memo.scala 30:35]
      mem._T_1.clk <= clock @[Memo.scala 30:35]
      mem._T_1.en <= UInt<1>("h1") @[Memo.scala 30:35]
      io.rdData <= mem._T_1.data @[Memo.scala 30:29]