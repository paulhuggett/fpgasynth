cmake_minimum_required (VERSION 3.22)
project (cmake_example)
find_package (verilator HINTS $ENV{VERILATOR_ROOT})

set (verilator_args --timing --assert -Wall)
set (vsrcs "${CMAKE_CURRENT_SOURCE_DIR}/..")

add_executable (Vadsr Vadsr.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Vadsr PUBLIC cxx_std_20)
verilate (Vadsr
  TOP_MODULE adsr_tb
  PREFIX adsr
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/eexp.sv"
    "${vsrcs}/mul.sv"
    "${vsrcs}/adsr.sv"
    "${vsrcs}/adsr_tb.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Veexp Veexp.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Veexp PUBLIC cxx_std_20)
verilate (Veexp
  TOP_MODULE eexp_tb
  PREFIX eexp
  SOURCES "${vsrcs}/eexp.sv" "${vsrcs}/eexp_tb.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Vlerp Vlerp.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Vlerp PUBLIC cxx_std_20)
verilate (Vlerp
  TOP_MODULE lerp_tb
  PREFIX lerp
  SOURCES "${vsrcs}/lerp.sv" "${vsrcs}/lerp_tb.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Vmul Vmul.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Vmul PUBLIC cxx_std_20)
verilate (Vmul
  TOP_MODULE mul_tb
  PREFIX mul
  SOURCES "${vsrcs}/mul_tb.sv" "${vsrcs}/mul.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Vnco Vnco.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Vnco PUBLIC cxx_std_20)
verilate (Vnco
  TOP_MODULE nco_tb
  PREFIX nco
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/lerp.sv"
    "${vsrcs}/nco.sv"
    "${vsrcs}/nco_tb.sv"
    "${vsrcs}/sine_wavetable.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Vsine_wavetable Vsine_wavetable.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Vsine_wavetable PUBLIC cxx_std_20)
verilate (Vsine_wavetable
  PREFIX sine_wavetable
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/lerp.sv"
    "${vsrcs}/sine_wavetable_tb.sv"
    "${vsrcs}/sine_wavetable.sv"
  VERILATOR_ARGS ${verilator_args}
)

add_executable (Vbin2bcd Vbin2bcd.cpp main.hpp sc_time_stamp.cpp)
target_compile_features (Vbin2bcd PUBLIC cxx_std_20)
verilate (Vbin2bcd
  TOP_MODULE bin2bcd_tb
  PREFIX bin2bcd
  SOURCES
    "${vsrcs}/bin2bcd_tb.sv"
    "${vsrcs}/bin2bcd.sv"
  VERILATOR_ARGS ${verilator_args}
)
