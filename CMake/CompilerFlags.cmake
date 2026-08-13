# Compiler flag configuration module
# Provides platform and compiler-specific flag handling with modern CMake practices

# Enable strict compiler warnings for a target
function(erf_target_enable_strict_warnings target_name)
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    target_compile_options(${target_name} PRIVATE
      -Wall
      -Wextra
      -Wpedantic
      -Wunused
      -Wconversion
      -Wshadow
      -Wold-style-cast
      -Wnon-virtual-dtor
      -Wduplicated-cond
      -Wduplicated-branches
      -Wlogical-op
    )
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(${target_name} PRIVATE
      -Wall
      -Wextra
      -Wpedantic
      -Wunused
      -Wconversion
      -Wshadow
      -Wold-style-cast
      -Wnon-virtual-dtor
      -Wrange-loop-construct
      -Wunused-lambda-capture
    )
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
    # Intel compiler is less aggressive with warnings by default
    target_compile_options(${target_name} PRIVATE
      -Wall
      -diag-disable:11074,11076
    )
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "NVHPC")
    target_compile_options(${target_name} PRIVATE -Wall)
  elseif(MSVC)
    target_compile_options(${target_name} PRIVATE /W4 /WX)
  endif()
endfunction()

# Enable C++17 standard with strict conformance
function(erf_target_set_cpp17_strict target_name)
  set_target_properties(${target_name} PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
  )

  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 7.0)
    target_compile_options(${target_name} PRIVATE -faligned-new)
  endif()
endfunction()

# Configure code coverage compilation flags (modern approach)
function(erf_target_enable_coverage target_name)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    message(WARNING "Code coverage profiling is only supported with GNU Compilers. Current compiler: ${CMAKE_CXX_COMPILER_ID}")
    return()
  endif()

  # Use target-based flags instead of global CMAKE_CXX_FLAGS
  target_compile_options(${target_name} PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:--coverage>
    $<$<COMPILE_LANGUAGE:C>:--coverage>
  )
  target_link_options(${target_name} PRIVATE --coverage)
endfunction()

# Configure CUDA-specific flags
function(erf_target_configure_cuda target_name)
  if(NOT ERF_ENABLE_CUDA)
    return()
  endif()

  set_target_properties(${target_name} PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
  )

  target_compile_options(${target_name} PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:
      --expt-relaxed-constexpr
      --expt-extended-lambda
      --Wno-deprecated-gpu-targets
      -m64
    >
  )

  if(ENABLE_CUDA_FASTMATH)
    target_compile_options(${target_name} PRIVATE
      $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>
    )
  endif()
endfunction()

# Configure HIP-specific flags
function(erf_target_configure_hip target_name)
  if(NOT ERF_ENABLE_HIP)
    return()
  endif()

  if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.21)
    # Set HIP architectures from environment or defaults
    set(hip_arch "")
    if(DEFINED AMReX_AMD_ARCH)
      set(hip_arch "${AMReX_AMD_ARCH}")
    elseif(DEFINED CMAKE_HIP_ARCHITECTURES)
      set(hip_arch "${CMAKE_HIP_ARCHITECTURES}")
    elseif(DEFINED ENV{ROCM_GPU})
      set(hip_arch "$ENV{ROCM_GPU}")
    elseif(DEFINED ENV{HIPARCHS})
      set(hip_arch "$ENV{HIPARCHS}")
    elseif(DEFINED ENV{HIP_ARCH})
      set(hip_arch "$ENV{HIP_ARCH}")
    else()
      set(hip_arch "gfx90a")
    endif()

    set_target_properties(${target_name} PROPERTIES HIP_ARCHITECTURES "${hip_arch}")
    message(VERBOSE "Set HIP_ARCHITECTURES=${hip_arch} for ${target_name}")
  endif()
endfunction()

# Apply ERF-standard flags to a target
# This is the main entry point for flag configuration
function(erf_target_apply_standard_flags target_name)
  erf_target_set_cpp17_strict(${target_name})
  erf_target_enable_strict_warnings(${target_name})
  erf_target_configure_cuda(${target_name})
  erf_target_configure_hip(${target_name})
endfunction()
