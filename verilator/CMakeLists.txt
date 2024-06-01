cmake_minimum_required (VERSION 3.22)
project (verilate_synth)
find_package (verilator HINTS $ENV{VERILATOR_ROOT})

enable_testing()

function (verilate_test target)
  cmake_parse_arguments (arg # prefix
    "" # options
    "" # one-value keywords
    "SOURCES" # multi-value keywords
    ${ARGN}
  )
  configure_file (
    "${CMAKE_CURRENT_SOURCE_DIR}/main.cpp.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${target}.cpp"
    USE_SOURCE_PERMISSIONS
  )
  add_executable ("${target}"
    "${CMAKE_CURRENT_BINARY_DIR}/${target}.cpp"
    main.hpp
    sc_time_stamp.cpp
  )
  target_compile_features ("${target}" PRIVATE cxx_std_20)
  target_include_directories ("${target}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  verilate ("${target}"
    PREFIX "${target}"
    SOURCES ${arg_SOURCES}
    TOP_MODULE "${target}_tb"
    VERILATOR_ARGS --timing --assert -Wall
  )
  add_test (NAME "${target}" COMMAND "${target}")
endfunction ()

set (vsrcs "${CMAKE_CURRENT_SOURCE_DIR}/..")
verilate_test (bin2bcd SOURCES "${vsrcs}/bin2bcd_tb.sv" "${vsrcs}/bin2bcd.sv")
verilate_test (eexp SOURCES "${vsrcs}/eexp.sv" "${vsrcs}/eexp_tb.sv")
verilate_test (lerp SOURCES "${vsrcs}/lerp.sv" "${vsrcs}/lerp_tb.sv")
verilate_test (mul SOURCES "${vsrcs}/mul_tb.sv" "${vsrcs}/mul.sv")
verilate_test (
  adsr
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/eexp.sv"
    "${vsrcs}/mul.sv"
    "${vsrcs}/adsr.sv"
    "${vsrcs}/adsr_tb.sv"
)
verilate_test (
  nco
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/lerp.sv"
    "${vsrcs}/nco.sv"
    "${vsrcs}/nco_tb.sv"
    "${vsrcs}/sine_wavetable.sv"
)
verilate_test (
  sine_wavetable
  SOURCES
    "${vsrcs}/mypackage.sv"
    "${vsrcs}/lerp.sv"
    "${vsrcs}/sine_wavetable_tb.sv"
    "${vsrcs}/sine_wavetable.sv"
)

