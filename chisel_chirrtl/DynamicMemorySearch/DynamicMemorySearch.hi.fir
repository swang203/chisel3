circuit DynamicMemorySearch :
  module DynamicMemorySearch :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip isWr : UInt<1>, flip wrAddr : UInt<3>, flip data : UInt<4>, flip en : UInt<1>, target : UInt<3>, done : UInt<1>}

    reg index : UInt<3>, clock with :
      reset => (reset, UInt<3>("h0")) @[DynamicMemorySearch.scala 30:23]
    mem list : @[DynamicMemorySearch.scala 32:19]
      data-type => UInt<4>
      depth => 8
      read-latency => 0
      write-latency => 1
      reader => memVal
      writer => _T_4
      read-under-write => undefined
    list.memVal.addr is invalid @[DynamicMemorySearch.scala 32:19]
    list.memVal.clk is invalid @[DynamicMemorySearch.scala 32:19]
    list.memVal.en <= UInt<1>("h0") @[DynamicMemorySearch.scala 32:19]
    list._T_4.addr is invalid @[DynamicMemorySearch.scala 32:19]
    list._T_4.clk is invalid @[DynamicMemorySearch.scala 32:19]
    list._T_4.en <= UInt<1>("h0") @[DynamicMemorySearch.scala 32:19]
    list._T_4.data is invalid @[DynamicMemorySearch.scala 32:19]
    list._T_4.mask is invalid @[DynamicMemorySearch.scala 32:19]
    list.memVal.addr <= index @[DynamicMemorySearch.scala 33:20]
    list.memVal.clk <= clock @[DynamicMemorySearch.scala 33:20]
    list.memVal.en <= UInt<1>("h1") @[DynamicMemorySearch.scala 33:20]
    node _T = eq(io.en, UInt<1>("h0")) @[DynamicMemorySearch.scala 35:16]
    node _T_1 = eq(list.memVal.data, io.data) @[DynamicMemorySearch.scala 35:35]
    node _T_2 = eq(index, UInt<3>("h7")) @[DynamicMemorySearch.scala 35:58]
    node _T_3 = or(_T_1, _T_2) @[DynamicMemorySearch.scala 35:48]
    node done = and(_T, _T_3) @[DynamicMemorySearch.scala 35:23]
    when io.isWr : @[DynamicMemorySearch.scala 37:18]
      list._T_4.addr <= io.wrAddr @[DynamicMemorySearch.scala 38:9]
      list._T_4.clk <= clock @[DynamicMemorySearch.scala 38:9]
      list._T_4.en <= UInt<1>("h1") @[DynamicMemorySearch.scala 38:9]
      list._T_4.mask <= UInt<1>("h0") @[DynamicMemorySearch.scala 38:9]
      list._T_4.data <= io.data @[DynamicMemorySearch.scala 38:21]
      list._T_4.mask <= UInt<1>("h1") @[DynamicMemorySearch.scala 38:21]
    else :
      when io.en : @[DynamicMemorySearch.scala 39:23]
        index <= UInt<1>("h0") @[DynamicMemorySearch.scala 40:11]
      else :
        node _T_5 = eq(done, UInt<1>("h0")) @[DynamicMemorySearch.scala 41:21]
        when _T_5 : @[DynamicMemorySearch.scala 41:34]
          node _T_6 = add(index, UInt<1>("h1")) @[DynamicMemorySearch.scala 42:20]
          node _T_7 = tail(_T_6, 1) @[DynamicMemorySearch.scala 42:20]
          index <= _T_7 @[DynamicMemorySearch.scala 42:11]
    io.done <= done @[DynamicMemorySearch.scala 44:13]
    io.target <= index @[DynamicMemorySearch.scala 45:13]