#Copyright (c) Microsoft. All rights reserved.
#Licensed under the MIT license. See LICENSE file in the project root for full license information.

#this is CMakeLists.txt for tlsio_arduino_ut
cmake_minimum_required(VERSION 2.8.11)

compileAsC11()
set(theseTestsName tlsioarduino_ut)

set(${theseTestsName}_test_files
${theseTestsName}.c
)

set(${theseTestsName}_c_files
${SHARED_UTIL_PAL_FOLDER}/tlsio_options.c
${SHARED_UTIL_SRC_FOLDER}/crt_abstractions.c
${SHARED_UTIL_SRC_FOLDER}/vector.c
${SHARED_UTIL_SRC_FOLDER}/optionhandler.c
${EXTERNAL_PAL_REPO_DIR}/pal/src/tlsio_arduino.c
)

include_directories(${EXTERNAL_PAL_REPO_DIR}/pal/inc)

set(${theseTestsName}_h_files
)

build_c_test_artifacts(${theseTestsName} ON "tests/azure_c_shared_utility_tests")
