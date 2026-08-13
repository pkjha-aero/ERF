# Helper module for MPI detection and configuration
# Provides streamlined MPI setup with fallback for problematic compilers

function(erf_configure_mpi)
  set(options)
  set(oneValueArgs)
  set(multiValueArgs COMPONENTS)
  cmake_parse_arguments(MPI_CFG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(_default_components C CXX)
  if(NOT DEFINED MPI_CFG_COMPONENTS)
    set(MPI_CFG_COMPONENTS ${_default_components})
  endif()

  # Check if we're on Cray with bare MPI wrappers (which will hang)
  set(_skip_mpi_detection FALSE)

  if(DEFINED ENV{CRAYPE_VERSION} OR DEFINED ENV{CRAY_MPICH_DIR})
    # On Cray system - check if using problematic bare MPI wrappers
    if(CMAKE_CXX_COMPILER MATCHES "mpicxx" OR
       CMAKE_C_COMPILER MATCHES "mpicc" OR
       CMAKE_Fortran_COMPILER MATCHES "mpifort")
      message(STATUS "Detected bare MPI wrappers on Cray - using manual MPI setup (would hang with find_package)")
      set(_skip_mpi_detection TRUE)
    endif()
  endif()

  if(_skip_mpi_detection)
    # Cray workaround: Manual MPI target creation
    message(VERBOSE "Manually configuring MPI for Cray system")

    # Extract Cray MPICH version info
    set(_mpich_version "UNKNOWN")
    if(DEFINED ENV{CRAY_MPICH_VERSION})
      set(_mpich_version "$ENV{CRAY_MPICH_VERSION}")
    elseif(DEFINED ENV{CRAY_MPICH_VER})
      set(_mpich_version "$ENV{CRAY_MPICH_VER}")
    endif()

    # Create minimal MPI targets (Cray wrappers handle all flags)
    foreach(_component IN LISTS MPI_CFG_COMPONENTS)
      if(NOT TARGET MPI::MPI_${_component})
        add_library(MPI::MPI_${_component} INTERFACE IMPORTED)
        set(MPI_${_component}_FOUND TRUE)
      endif()
    endforeach()

    set(MPI_FOUND TRUE PARENT_SCOPE)
    set(MPI_VERSION "3.1")
    message(STATUS "Cray MPICH: ${_mpich_version}, MPI Standard: ${MPI_VERSION}")
  else()
    # Standard path: Use CMake's find_package(MPI)
    message(VERBOSE "Detecting MPI with find_package()")
    find_package(MPI QUIET COMPONENTS ${MPI_CFG_COMPONENTS})

    if(NOT MPI_FOUND)
      message(FATAL_ERROR
        "MPI required but not found. "
        "Install MPI and either:\n"
        "  1. Load appropriate modules from your system\n"
        "  2. Pass compiler hints: -DMPI_CXX_COMPILER=mpicxx -DMPI_C_COMPILER=mpicc\n"
        "On HPC systems, consult module avail mpi or documentation.")
    endif()
  endif()

  message(VERBOSE "MPI_FOUND: ${MPI_FOUND}")
  set(MPI_FOUND ${MPI_FOUND} PARENT_SCOPE)

endfunction()
