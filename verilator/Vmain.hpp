#include "verilated.h"
template <typename TestBench>
int Vmain(int argc, char** argv) {
  // Setup context, defaults, and parse command line
  Verilated::debug(0);
  auto context = std::make_unique<VerilatedContext> ();
  context->commandArgs(argc, argv);
  // Construct the Verilated model
  auto top = std::make_unique<TestBench> ();

  // Simulate until $finish
  while (!context->gotFinish()) {
    top->eval(); // Evaluate model

    // Advance time
    if (!top->eventsPending()) {
      break;
    }
    context->time(top->nextTimeSlot());
  }

  if (!context->gotFinish()) {
    VL_DEBUG_IF(VL_PRINTF("+ Exiting without $finish; no events left\n"););
  }
  top->final(); // Final model cleanup
  return 0;
}
