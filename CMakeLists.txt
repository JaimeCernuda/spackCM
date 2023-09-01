cmake_minimum_required(VERSION 3.22)
project(untitled)

set(CMAKE_CXX_STANDARD 17)

include(spackCM.cmake)

spackCM(adios2)

add_executable(test main.cpp)

MESSAGE(STATUS "${ADIOS2_INCLUDE_DIR}): " ${ADIOS2_INCLUDE_DIR})
MESSAGE(STATUS "${ADIOS2_LIBRARIES}): " ${ADIOS2_LIBRARIES})

#target_link_libraries(test adios2::adios2)
