# Log 12 - Asynchronous FIFO Flag Latency and Verification Basics

Date: 2026-10-14

## What I Did

After finishing the testbench yesterday, I had not examined the waveforms carefully. Today, I noticed that `empty` deasserts (`1 -> 0`) with a delay, but asserts (`0 -> 1`) without the same delay. The `full` flag behaves similarly: deassertion is delayed, while assertion is not.

At first, I thought there was a mistake in my RTL. After spending some time reviewing the code without finding the cause, I discussed it with AI and realized that this is expected behavior. The remote pointers pass through two-stage synchronizers before they can be used in the destination clock domain. These synchronizers reduce the risk of metastability propagating into downstream logic; they do not eliminate metastability itself.

## What I Learned

### Why Empty and Full Have Delayed Deassertion

The `empty` flag is evaluated in the read clock domain. Suppose no new writes are taking place and the write pointer has already propagated through the synchronizer. Its synchronized value is then stable and up to date, so reading the remaining entries does not require waiting for another write-pointer update to cross clock domains.

In the registered implementation, `empty_next` compares the next read Gray pointer with the synchronized write Gray pointer. Before the clock edge that accepts the final read, the combinational next-state logic predicts that the pointers will match. At that edge, the read pointer advances and `empty` is registered as 1. Thus, empty assertion does not incur an additional synchronization delay after the final read; it does not wait for a later read-clock edge to discover that the FIFO has become empty.

Deassertion is different. Suppose the FIFO is empty and the read pointer is stationary. When new data is written, the write pointer changes in the write clock domain. The read domain cannot immediately use that new value: it must first pass through the two-stage synchronizer. Only then can the read-side comparison recognize that data is available and deassert `empty`. In the registered version, registering the flag adds another local clock edge after the updated synchronized pointer becomes available.

This delay is conservative and safe. Data may already be stored while `empty` remains 1, temporarily preventing a read. That can reduce immediate throughput, but it does not cause an invalid read. The opposite situation would be unsafe: if the FIFO were actually empty but `empty` remained 0, another read could be incorrectly accepted. The flag must therefore assert in time to prevent underflow.

The same reasoning applies to `full` in the write clock domain. Local writes can assert full when the last available slot is filled. After a remote read frees space, the updated read pointer must cross into the write domain before full can deassert. Temporarily reporting full prevents a write even though space is available, which is safe. Failing to report full when all slots are occupied could allow overflow.

### An Introduction to Verification

The central goal of digital IC verification is to determine whether the RTL satisfies its predefined functional specification. In a chip project, verification extends beyond functional simulation to concerns such as clock-domain crossing safety, protocol timing, and reset reliability.

The tests I currently write are directed tests: I manually choose known scenarios, apply specific stimulus, and inspect how the RTL behaves. My current testbench mainly generates stimulus and waveforms; it does not yet provide a complete automated checking mechanism.

A common part of an automated verification environment is a reference model. For an asynchronous FIFO, the model can represent the required first-in, first-out behavior with a queue. If three data items are successfully written, they must be read in the same order. Successfully accepted data must not be lost, duplicated, or reordered.

The reference model does not need to reproduce the RTL's internal implementation or analog effects such as metastability. It models the expected functional behavior. A scoreboard then compares the DUT's actual results with the expected results produced by that model.

For example, the model adds an item to its queue when the FIFO accepts a write (`wr_en && !full`). When a read is accepted (`rd_en && !empty`), the scoreboard compares the corresponding output, sampled after the registered read result updates, with the item removed from the front of the queue. If they differ, it reports an error and provides information to help locate the problem. Matching accepted transfers is important: an asserted enable alone does not mean the FIFO actually performed an operation.

This gives me a clearer picture of the next stage of verification: moving from manually inspecting a few waveforms toward automatically checking whether the design preserves the behavior required by its specification.
