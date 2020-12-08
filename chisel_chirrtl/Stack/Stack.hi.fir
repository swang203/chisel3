circuit Stack :
  module Stack :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip push : UInt<1>, flip pop : UInt<1>, flip en : UInt<1>, flip dataIn : UInt<32>, dataOut : UInt<32>}

    mem stack_mem : @[Stack.scala 16:22]
      data-type => UInt<32>
      depth => 8
      read-latency => 0
      write-latency => 1
      reader => _T_14
      writer => _T_3
      read-under-write => undefined
    stack_mem._T_14.addr is invalid @[Stack.scala 16:22]
    stack_mem._T_14.clk is invalid @[Stack.scala 16:22]
    stack_mem._T_14.en <= UInt<1>("h0") @[Stack.scala 16:22]
    stack_mem._T_3.addr is invalid @[Stack.scala 16:22]
    stack_mem._T_3.clk is invalid @[Stack.scala 16:22]
    stack_mem._T_3.en <= UInt<1>("h0") @[Stack.scala 16:22]
    stack_mem._T_3.data is invalid @[Stack.scala 16:22]
    stack_mem._T_3.mask is invalid @[Stack.scala 16:22]
    reg sp : UInt<4>, clock with :
      reset => (reset, UInt<4>("h0")) @[Stack.scala 17:26]
    reg out : UInt<32>, clock with :
      reset => (reset, UInt<32>("h0")) @[Stack.scala 18:26]
    when io.en : @[Stack.scala 20:16]
      node _T = lt(sp, UInt<4>("h8")) @[Stack.scala 21:25]
      node _T_1 = and(io.push, _T) @[Stack.scala 21:18]
      when _T_1 : @[Stack.scala 21:42]
        node _T_2 = bits(sp, 2, 0) @[Stack.scala 22:16]
        stack_mem._T_3.addr <= _T_2 @[Stack.scala 22:16]
        stack_mem._T_3.clk <= clock @[Stack.scala 22:16]
        stack_mem._T_3.en <= UInt<1>("h1") @[Stack.scala 22:16]
        stack_mem._T_3.mask <= UInt<1>("h0") @[Stack.scala 22:16]
        stack_mem._T_3.data <= io.dataIn @[Stack.scala 22:21]
        stack_mem._T_3.mask <= UInt<1>("h1") @[Stack.scala 22:21]
        node _T_4 = add(sp, UInt<1>("h1")) @[Stack.scala 23:16]
        node _T_5 = tail(_T_4, 1) @[Stack.scala 23:16]
        sp <= _T_5 @[Stack.scala 23:10]
      else :
        node _T_6 = gt(sp, UInt<1>("h0")) @[Stack.scala 24:31]
        node _T_7 = and(io.pop, _T_6) @[Stack.scala 24:24]
        when _T_7 : @[Stack.scala 24:39]
          node _T_8 = sub(sp, UInt<1>("h1")) @[Stack.scala 25:16]
          node _T_9 = tail(_T_8, 1) @[Stack.scala 25:16]
          sp <= _T_9 @[Stack.scala 25:10]
      node _T_10 = gt(sp, UInt<1>("h0")) @[Stack.scala 27:14]
      when _T_10 : @[Stack.scala 27:21]
        node _T_11 = sub(sp, UInt<1>("h1")) @[Stack.scala 28:27]
        node _T_12 = tail(_T_11, 1) @[Stack.scala 28:27]
        node _T_13 = bits(_T_12, 2, 0) @[Stack.scala 28:23]
        stack_mem._T_14.addr <= _T_13 @[Stack.scala 28:23]
        stack_mem._T_14.clk <= clock @[Stack.scala 28:23]
        stack_mem._T_14.en <= UInt<1>("h1") @[Stack.scala 28:23]
        out <= stack_mem._T_14.data @[Stack.scala 28:11]
    io.dataOut <= out @[Stack.scala 32:14]