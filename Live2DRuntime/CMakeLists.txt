cmake_minimum_required(VERSION 3.20)

project(PhoebeLive2DRuntime LANGUAGES C CXX)

if(NOT DEFINED CUBISM_CORE_INCLUDE)
  message(FATAL_ERROR "CUBISM_CORE_INCLUDE is required")
endif()

add_library(PhoebeLive2DRuntime STATIC
  src/PhoebeLive2DRuntime.cpp
)

target_compile_features(PhoebeLive2DRuntime PRIVATE cxx_std_14)
target_include_directories(PhoebeLive2DRuntime
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
  PRIVATE ${CUBISM_CORE_INCLUDE}
)

set_target_properties(PhoebeLive2DRuntime PROPERTIES
  OUTPUT_NAME PhoebeLive2DRuntime
  POSITION_INDEPENDENT_CODE ON
)
