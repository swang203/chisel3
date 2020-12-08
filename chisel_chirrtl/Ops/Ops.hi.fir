circuit Ops :
  module Ops :
    input sel : UInt<4>
    input is : SInt<8>
    input iu : UInt<8>
    output os : SInt<14>
    output ou : UInt<13>
    output obool : UInt<1>

    os <= SInt<1>("h0")
    ou <= UInt<1>("h0")
    obool <= UInt<1>("h0")
    when eq(sel, UInt<1>("h0")) :
      os <= add(is, is)
      ou <= add(iu, iu)
    else :
      when eq(sel, UInt<1>("h1")) :
        os <= sub(is, is)
        ou <= sub(iu, iu)
      else :
        when eq(sel, UInt<2>("h2")) :
          os <= mux(eq(is, SInt<1>("h0")), SInt<2>("h1"), div(is, is))
          ou <= mux(eq(iu, UInt<1>("h0")), UInt<1>("h1"), div(iu, iu))
        else :
          when eq(sel, UInt<2>("h3")) :
            os <= rem(is, is)
            ou <= rem(iu, iu)
          else :
            when eq(sel, UInt<3>("h4")) :
              ou <= add(and(is, is), and(iu, iu))
            else :
              when eq(sel, UInt<3>("h5")) :
                ou <= add(or(is, is), or(iu, iu))
              else :
                when eq(sel, UInt<3>("h4")) :
                  ou <= add(xor(is, is), xor(iu, iu))
                else :
                  when eq(sel, UInt<3>("h5")) :
                    ou <= add(eq(is, is), eq(iu, iu))
                  else :
                    when eq(sel, UInt<3>("h4")) :
                      ou <= add(neq(is, is), neq(iu, iu))
                    else :
                      when eq(sel, UInt<3>("h5")) :
                        ou <= add(geq(is, is), geq(iu, iu))
                      else :
                        when eq(sel, UInt<3>("h4")) :
                          ou <= add(leq(is, is), leq(iu, iu))
                        else :
                          when eq(sel, UInt<3>("h5")) :
                            ou <= add(gt(is, is), gt(iu, iu))
                          else :
                            ou <= add(lt(is, is), lt(iu, iu))