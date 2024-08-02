cmake_minimum_required(VERSION 3.0.0 FATAL_ERROR)

# Set up the project
project(c
    LANGUAGES C ASM
)

# Define our target library and an alias for consumers
add_library(${PROJECT_NAME})

message(STATUS "start build: ${PROJECT_NAME}")

set(CMAKE_C_COMPILER    aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER  aarch64-linux-gnu-g++)
set(AS                  aarch64-linux-gnu-as)
set(AR                  aarch64-linux-gnu-ar)
set(OBJCOPY             aarch64-linux-gnu-objcopy)
set(OBJDUMP             aarch64-linux-gnu-objdump)
set(SIZE                aarch64-linux-gnu-size)

target_compile_options(${PROJECT_NAME} PRIVATE -fno-stack-protector)

target_sources(${PROJECT_NAME} PRIVATE
	${CMAKE_CURRENT_LIST_DIR}/src/memset.c
	${CMAKE_CURRENT_LIST_DIR}/src/exit.c
	${CMAKE_CURRENT_LIST_DIR}/src/snprintf.c
	${CMAKE_CURRENT_LIST_DIR}/src/putchar.c
	${CMAKE_CURRENT_LIST_DIR}/src/puts.c
	${CMAKE_CURRENT_LIST_DIR}/src/printf.c
	${CMAKE_CURRENT_LIST_DIR}/src/memmove.c
	${CMAKE_CURRENT_LIST_DIR}/src/memcmp.c
	${CMAKE_CURRENT_LIST_DIR}/src/memcpy.c
	${CMAKE_CURRENT_LIST_DIR}/src/strlen.c
	${CMAKE_CURRENT_LIST_DIR}/src/strrchr.c
	${CMAKE_CURRENT_LIST_DIR}/src/memchr.c
	${CMAKE_CURRENT_LIST_DIR}/src/strnlen.c
	${CMAKE_CURRENT_LIST_DIR}/src/strcmp.c
)

