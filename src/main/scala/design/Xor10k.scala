// See README.md for license details.

package design

import chisel3._

class Xor10k extends Module {
  val io = IO(new Bundle {
    val vec = Input(Vec(10000, UInt(8.W)))
    val out = Output(UInt(8.W))
  })

  io.out := 0.U
  for (i <- 0 to 10000 - 1) {
    io.out := io.out ^ io.vec(i)
  }
}
