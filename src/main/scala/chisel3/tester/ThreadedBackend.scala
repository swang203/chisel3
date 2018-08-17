// See LICENSE for license details.

package chisel3.tester

import java.util.concurrent.{Semaphore, SynchronousQueue, TimeUnit}
import scala.collection.mutable

import chisel3._

/** Common utility functions for backends implementing concurrency by threading.
  * The backend must invoke concurrency functions as appropriate, eg during step() calls
  */
trait ThreadedBackend {
  var nextActionId: Int = 0  // counter for unique ID assigned to each poke action

  // combinationalPaths: map of sink Data to all source Data nodes.
  protected class ThreadingChecker(
      combinationalPaths: Map[Data, Set[Data]], dataNames: Map[Data, String]) {
    /** Desired threading checking behavior:
      * At a high level, the sequence should be lexically unambiguous. Threads are started no earlier than the fork, but
      * there are no other guarantees on execution order.
      *
      * Any sequence of peeks and pokes limited to a single thread are allowed.
      *
      * Cross-thread operations are allowed under timescope-like semantics:
      * Peeks to a signal combinationally affect by pokes from other threads are allowed under similar rules:
      * - the previous poke was done by a parent thread before the current thread spawned
      *
      * Pokes to a signal previously poked by another thread are allowed if:
      * - (the condition for peeks also applies to pokes)
      * - the poke is a subset (in time) of the previous poke
      *
      * One edge case is a end-of-timescope revert and poke from a different thread within the same timestep:
      *   In this case, the revert must no-op if it is no longer on top of the timescope stack for a signal
      *   (conflict checking is deferred until the end of the timestep)
      *   Otherwise, conflict checking is the same as the usual case.
      *
      * In each discrete timestep, all actions should execute and batch up errors, so that thread
      * ordering errors can be generated in addition to any (false-positive) correctness errors:
      * Start timestep by moving blocked threads to active
      *   Clear active peeks / pokes belonging to the last cycle of that clock
      * Run all threads:
      *   If other joined threads are enabled, add them to the end of the active threads list
      *   Exceptions propagate immediately
      *   Test failures are batched to the end of the timestep
      *   Peeks and pokes are recorded in a table and associated with the clock / timestep and thread
      * At the end of the timestep:
      *   Check for peek and poke ordering dependence faults
      *   Report batched test failures
      */

    protected class Timescope(val parentThread: TesterThread, val parentTimescope: Option[Timescope]) {
      // Latest poke on a signal in this timescope
      val pokes = mutable.HashMap[Data, SignalPokeRecord]()
    }

    abstract class PokeRecord {
      def actionId: Int
      def thread: TesterThread
    }
    case class SignalPokeRecord(timescope: Timescope, priority: Int, value: BigInt,
        actionId: Int, trace: Throwable) extends PokeRecord {
      override def thread = timescope.parent
    }
    case class XPokeRecord(thread: TesterThread, actionId: Int) extends PokeRecord {
      def priority: Int = Int.MaxValue
    }
    case class PeekRecord(thread: TesterThread, actionId: Int, trace: Throwable)

    protected val threadTimescopes = mutable.HashMap[TesterThread, mutable.ListBuffer[Timescope]]()

    // Active pokes on a signal, map of wire -> timescope
    protected val signalPokes = mutable.HashMap[Data, mutable.ListBuffer[Timescope]]()
    protected val revertPokes = mutable.HashMap[Data, mutable.ListBuffer[PokeRecord]]()

    // Active peeks on a signal, lasts until the specified clock advances
    protected val signalPeeks = mutable.HashMap[Data, mutable.ListBuffer[PeekRecord]]()

    // All poke revert operations

    /**
     * Logs a poke operation for later checking.
     * Returns whether to execute it, based on priorities compared to other active pokes.
     */
    def doPoke(thread: TesterThread, signal: Data, value: BigInt, priority: Int, trace: Throwable): Unit = {
      val timescope = threadTimescopes(thread).last
      val pokeRecord = SignalPokeRecord(timescope, priority, value, nextActionId, trace)
      timescope.pokes.put(signal, pokeRecord)
      nextActionId = nextActionId + 1

      val signalTimescopeStack = signalPokes.getOrElseUpdate(signal, mutable.HashMap())
          .getOrElseUpdate(priority, mutable.ListBuffer())
      val signalTimescopeLast = signalTimescopeStack.lastOption

      // Don't stack repeated copies of the same timescope.
      // If the timescope exists but isn't the last on the stack, it will be caught during end-of-timestep checking.
      if (!signalTimescopeLast.isDefined || signalTimescopeLast.get != timescope) {
        signalTimescopeStack.append(timescope)
      }
    }

    /**
     * Logs a peek operation for later checking.
     */
    def doPeek(thread: TesterThread, signal: Data, trace: Throwable): Unit = {
      signalPeeks.getOrElseUpdate(signal, mutable.ListBuffer())
          .append(PeekRecord(thread, nextActionId, trace))
      nextActionId = nextActionId + 1
    }

    /**
     * Creates a new timescope in the specified thread.
     */
    def newTimescope(parent: TesterThread): Timescope = {
      val newTimescope = new Timescope(parent)
      threadTimescopes.getOrElseUpdate(parent, mutable.ListBuffer()).append(
          newTimescope)
      newTimescope
    }

    /**
     * Closes the specified timescope, returns a map of wires to values of any signals that need to be updated.
     */
    def closeTimescope(timescope: Timescope): Map[Data, Option[BigInt]] = {
      // Clear timescope from thread first
      val timescopeList = threadTimescopes(timescope.parentThread)
      require(timescopeList.last == timescope)
      timescopeList.trimEnd(1)
      if (timescopeList.isEmpty) {
        threadTimescopes.remove(timescope.parentThread)
      }

      // Clear the timescope from signal pokes, and revert if this is the active poke
      timescope.pokes.map { case (data, pokeRecord) =>
        // TODO: better error message when closing a timescope on the same timestep as a malformed operation
        require(signalPokes(data).count(_ == timescope) == 1)

        signalPokes(data) -= timescope
        if (signalPokes(data).isEmpty) {
          signalPokes.remove(data)
        }
      }

      // Get the PokeRecords of the value to revert to
      val revertMap = timescope.pokes.toMap map { case (data, pokeRecord) =>
        (data, signalPokes.get(data) match {
          case Some(pokesMap) => pokesMap(pokesMap.keys.min).last.pokes(data)
          case None =>
            val record = XPokeRecord(timescope.parent, nextActionId)
            nextActionId = nextActionId + 1
            record
        })
      }

      // Register those pokes as happening on this timestep
      revertMap foreach { case (data, pokeRecord) =>
        revertPokes.getOrElseUpdate(data, mutable.ListBuffer()).append(
            pokeRecord)
      }

      revertMap map { case (data, pokeRecord) => (data, pokeRecord match {
        case signal: SignalPokeRecord => Some(signal.value)
        case _: XPokeRecord => None
      } ) }
    }

    /**
     * Starts a new timestep, checking if there were any conflicts on the previous timestep (and
     * throwing exceptions if there were).
     */
    def timestep(): Unit = {
      // check overlapped pokes from different threads with same priority
      signalPokes foreach { case (signal, priorityToTimescopes) =>
        priorityToTimescopes foreach { case (priority, timescopes) =>
          val threads = timescopes.map(_.parent).distinct
          if (threads.length > 1) {
            throw new ThreadOrderDependentException(s"conflicting pokes on signal $signal at priority $priority from threads $threads")
          }
        }
      }

      // check poke | peek dependencies
      signalPeeks foreach { case (signal, peeks) =>
        val peekThreads = peeks.map(_.thread).toSet
        // Pokes must be from every peeked thread, or alternatively stated,
        // if there was one peek thread, all pokes must be from it;
        // if there were multiple peek threads, there can be no pokes
        val canPokeThreads: Set[TesterThread] = if (peekThreads.size == 1) peekThreads else Set()

        val otherPokeThreads = signalPokes.get(signal).filter { priorityToTimescopes =>
          !(priorityToTimescopes(priorityToTimescopes.keySet.min).map(_.parent).toSet subsetOf canPokeThreads)
        }.toSet.flatten
        val otherRevertThreads = revertPokes.get(signal).filter { pokes =>
          !(pokes.map(_.thread).toSet subsetOf canPokeThreads)
        }.toSet.flatten

        // Get a list of threads that have affected a combinational source for the signal
        val combPokeSignals = combinationalPaths.get(signal).toSet.flatten.filter { source =>
          signalPokes.get(source).filter { priorityToTimescopes =>
            !(priorityToTimescopes(priorityToTimescopes.keySet.min).map(_.parent).toSet subsetOf canPokeThreads)
          }.isDefined
        }
        val combRevertSignals = combinationalPaths.get(signal).toSet.flatten.filter { source =>
          revertPokes.get(source).filter { pokes =>
            !(pokes.map(_.thread).toSet subsetOf canPokeThreads)
          }.isDefined
        }

        val signalName = dataNames(signal)
        // TODO: better error reporting
        if (!otherPokeThreads.isEmpty) {
          throw new ThreadOrderDependentException(s"peek on $signalName conflicts with pokes from other threads")
        }
        if (!otherRevertThreads.isEmpty) {
          throw new ThreadOrderDependentException(s"peek on $signalName conflicts with timescope revert from other threads")
        }

        if (!combPokeSignals.isEmpty) {
          val signalsStr = combPokeSignals.map(dataNames(_)).mkString(", ")
          throw new ThreadOrderDependentException(s"peek on $signalName combinationally affected by pokes to $signalsStr from other threads")
        }
        if (!combRevertSignals.isEmpty) {
          val signalsStr = combRevertSignals.map(dataNames(_)).mkString(", ")
          throw new ThreadOrderDependentException(s"peek on $signalName combinationally affected by timescope reverts to $signalsStr from other threads")
        }
      }
      revertPokes.clear()
      signalPeeks.clear()
    }
  }


  protected class TesterThread(runnable: => Unit,
      val startingActionId: Int, val parent: Option[TesterThread])
      extends AbstractTesterThread {
    val waiting = new Semaphore(0)
    var done: Boolean = false

    val thread = new Thread(new Runnable {
      def run() {
        try {
          waiting.acquire()
          try {
            timescope {
              runnable
            }
          } catch {
            case e: InterruptedException => throw e  // propagate to upper level handler
            case e @ (_: Exception | _: Error) =>
              onException(e)
          }
          done = true
          threadFinished(TesterThread.this)
          scheduler()
        } catch {
          case e: InterruptedException =>  // currently used as a signal to stop the thread
            // TODO: allow other uses for InterruptedException?
        }
      }
    })
  }

  protected var currentThread: Option[TesterThread] = None
  protected val driverSemaphore = new Semaphore(0)  // blocks runThreads() while it's running

  // TODO: does this need to be replaced with concurrent data structures?
  protected val activeThreads = mutable.ArrayBuffer[TesterThread]()  // list of threads scheduled for sequential execution
  protected val blockedThreads = mutable.HashMap[Clock, Seq[TesterThread]]()  // threads blocking on a clock edge
  protected val joinedThreads = mutable.HashMap[TesterThread, Seq[TesterThread]]()  // threads blocking on another thread
  protected val allThreads = mutable.ArrayBuffer[TesterThread]()  // list of all threads

  /**
   * Runs the specified threads, blocking this thread while those are running.
   * Newly formed threads or unblocked join threads will also run.
   *
   * Prior to this call: caller should remove those threads from the blockedThread list.
   * TODO: does this interface suck?
   *
   * Updates internal thread queue data structures. Exceptions will also be queued through onException() calls.
   * TODO: can (should?) this provide a more functional interface? eg returning what threads are blocking on?
   */
  protected def runThreads(threads: Seq[TesterThread]) {
    activeThreads ++= threads
    scheduler()
    driverSemaphore.acquire()
  }

  /**
   * Invokes the thread scheduler, which should be done anytime a thread needs to pass time.
   * Prior to this call: caller should add itself to the blocked / joined threads list
   * (unless terminating).
   * After this call: caller should block on its semaphore (unless terminating). currentThread
   * will no longer be valid.
   *
   * Unblocks the next thread to be run, possibly also also stepping time via advanceTime().
   * When there are no more active threads, unblocks the driver thread via driverSemaphore.
   */
  protected def scheduler() {
    if (!activeThreads.isEmpty) {
      val nextThread = activeThreads.head
      currentThread = Some(nextThread)
      activeThreads.trimStart(1)
      nextThread.waiting.release()
    } else {
      currentThread = None
      driverSemaphore.release()
    }
  }

  /**
   * Called when an exception happens inside a thread.
   * Can be used to propagate the exception back up to the main thread.
   * No guarantees are made about the state of the system on an exception.
   *
   * The thread then terminates, and the thread scheduler is invoked to unblock the next thread.
   * The implementation should only record the exception, which is properly handled later.
   */
  protected def onException(e: Throwable)

  /**
   * Called on thread completion to remove this thread from the running list.
   * Does not terminate the thread, does not schedule the next thread.
   */
  protected def threadFinished(thread: TesterThread) {
    allThreads -= thread
    joinedThreads.remove(thread) match {
      case Some(testerThreads) => activeThreads ++= testerThreads
      case None =>
    }
  }

  def fork(runnable: => Unit): TesterThread = {
    val newThread = new TesterThread(runnable, nextActionId,
        currentThread.map(_.parents).toSet.flatten ++ currentThread.toSet)
    allThreads += newThread
    activeThreads += newThread
    newThread.thread.start()
    newThread
  }

  def join(thread: AbstractTesterThread) = {
    val thisThread = currentThread.get
    val threadTyped = thread.asInstanceOf[TesterThread]  // TODO get rid of this, perhaps by making it typesafe
    if (!threadTyped.done) {
      joinedThreads.put(threadTyped, joinedThreads.getOrElseUpdate(threadTyped, Seq()) :+ thisThread)
      scheduler()
      thisThread.waiting.acquire()
    }
  }
}