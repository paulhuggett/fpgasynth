cmake_minimum_required(VERSION 3.22)
project (cmake_example)
find_package (verilator HINTS $ENV{VERILATOR_ROOT})
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unknown-warning-option")

set (verilator_args --timing --assert -Wall)
set (vsrcs "${CMAKE_CURRENT_SOURCE_DIR}/..")

add_executable (Vadsr Vadsr_tb_main.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vadsr PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vadsr
  TOP_MODULE adsr_tb
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/adsr_tb.sv"
    "${vsrcs}/adsr.sv"
    "${vsrcs}/eexp.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Veexp Veexp_tb_main.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Veexp PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Veexp SOURCES "${vsrcs}/eexp_tb.sv" "${vsrcs}/eexp.sv" VERILATOR_ARGS ${verilator_args})

add_executable (Vlerp Vlerp_tb_main.cpp Vmain.hpp sc_time_stamp.cpp)
set_target_properties (Vlerp PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED Yes)
verilate (Vlerp SOURCES "${vsrcs}/lerp_tb.sv" "${vsrcs}/lerp.sv" VERILATOR_ARGS ${verilator_args})
