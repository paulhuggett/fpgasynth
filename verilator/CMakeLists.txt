cmake_minimum_required(VERSION 3.22)
project (cmake_example)
find_package (verilator HINTS $ENV{VERILATOR_ROOT})
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unknown-warning-option")

set (verilator_args --timing --assert -Wall)
set (vsrcs "${CMAKE_CURRENT_SOURCE_DIR}/..")

add_executable (Vadsr Vadsr.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vadsr PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vadsr
  TOP_MODULE adsr_tb
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/adsr.sv"
    "${vsrcs}/adsr_tb.sv"
    "${vsrcs}/eexp.sv"
    "${vsrcs}/mul.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Veexp Veexp.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Veexp PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Veexp SOURCES "${vsrcs}/eexp_tb.sv" "${vsrcs}/eexp.sv" VERILATOR_ARGS ${verilator_args})

add_executable (Vlerp Vlerp.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vlerp PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vlerp SOURCES "${vsrcs}/lerp_tb.sv" "${vsrcs}/lerp.sv" VERILATOR_ARGS ${verilator_args})

add_executable (Vmul Vmul.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vmul PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vmul SOURCES "${vsrcs}/mul_tb.sv" "${vsrcs}/mul.sv" VERILATOR_ARGS ${verilator_args})

add_executable (Vnco Vnco.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vnco PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vnco
  TOP_MODULE nco_tb
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/lerp.sv"
    "${vsrcs}/nco.sv"
    "${vsrcs}/nco_tb.sv"
    "${vsrcs}/sine_wavetable.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Vsine_wavetable Vsine_wavetable.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vsine_wavetable PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vsine_wavetable
  SOURCES
  "${vsrcs}/mypackage.sv"
  "${vsrcs}/lerp.sv"
  "${vsrcs}/sine_wavetable_tb.sv"
    "${vsrcs}/sine_wavetable.sv"
  VERILATOR_ARGS ${verilator_args}
)
