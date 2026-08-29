# ERFGitVersion.cmake
#
# Generates ${ERF_VERSION_HEADER_DIR}/ERF_Version.H from Source/ERF_Version.H.in
# via Tools/gen_erf_version.py, once at configure time and again on every build,
# and exposes erf_attach_version_header(<target>) to put the generated header on
# a target's include path. See VERSION_MANAGEMENT.md.
#
# The generator rewrites the header only when its contents change, so a stable
# git state does not trigger recompiles.

if(DEFINED _ERF_GIT_VERSION_INCLUDED)
  return()
endif()
set(_ERF_GIT_VERSION_INCLUDED TRUE)

find_package(Python3 COMPONENTS Interpreter QUIET)
if(Python3_Interpreter_FOUND)
  set(_erf_version_python "${Python3_EXECUTABLE}")
else()
  set(_erf_version_python "python3")
endif()

set(ERF_VERSION_HEADER_DIR "${PROJECT_BINARY_DIR}/ERF_generated"
    CACHE INTERNAL "Directory holding the generated ERF_Version.H")

set(_erf_version_template "${PROJECT_SOURCE_DIR}/Source/ERF_Version.H.in")
set(_erf_version_output   "${ERF_VERSION_HEADER_DIR}/ERF_Version.H")
set(_erf_version_script   "${PROJECT_SOURCE_DIR}/Tools/gen_erf_version.py")

if(DEFINED PROJECT_VERSION AND NOT PROJECT_VERSION STREQUAL "")
  set(_erf_project_version "${PROJECT_VERSION}")
else()
  set(_erf_project_version "0.0.0")
endif()

# Best-effort AMReX version for the header; the runtime banner still prints
# amrex::Version() regardless of what is captured here.
set(_erf_amrex_version "unknown")
if(DEFINED AMReX_VERSION AND NOT AMReX_VERSION STREQUAL "")
  set(_erf_amrex_version "${AMReX_VERSION}")
elseif(DEFINED AMREX_GIT_VERSION AND NOT AMREX_GIT_VERSION STREQUAL "")
  set(_erf_amrex_version "${AMREX_GIT_VERSION}")
endif()

set(_erf_version_command
    "${_erf_version_python}" "${_erf_version_script}"
    --template        "${_erf_version_template}"
    --output          "${_erf_version_output}"
    --source-dir      "${PROJECT_SOURCE_DIR}"
    --project-version "${_erf_project_version}"
    --cxx-compiler    "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}"
    --amrex-version   "${_erf_amrex_version}")

file(MAKE_DIRECTORY "${ERF_VERSION_HEADER_DIR}")

# Generate once now so the header exists for the first build, even before the
# custom target runs.
execute_process(COMMAND ${_erf_version_command} RESULT_VARIABLE _erf_version_rc)
if(NOT _erf_version_rc EQUAL 0 OR NOT EXISTS "${_erf_version_output}")
  message(WARNING
    "ERF: could not run Tools/gen_erf_version.py (rc=${_erf_version_rc}); "
    "writing a placeholder ERF_Version.H without git metadata")
  string(TIMESTAMP _erf_fallback_date "%Y-%m-%dT%H:%M:%SZ" UTC)
  set(ERF_VERSION       "${_erf_project_version}")
  set(ERF_GIT_DESCRIBE  "unknown")
  set(ERF_GIT_SHA       "unknown")
  set(ERF_GIT_DIRTY     "false")
  set(ERF_BUILD_DATE    "${_erf_fallback_date}")
  set(ERF_CXX_COMPILER  "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
  set(ERF_AMREX_VERSION "${_erf_amrex_version}")
  configure_file("${_erf_version_template}" "${_erf_version_output}" @ONLY)
endif()

# Regenerate on every build so the stamp tracks the working tree.
add_custom_target(erf_version_header ALL
  BYPRODUCTS "${_erf_version_output}"
  COMMAND ${_erf_version_command}
  COMMENT "Regenerating ERF_Version.H"
  VERBATIM)

# Put the generated header on <target>'s include path and make it wait for the
# generator.
function(erf_attach_version_header target)
  if(NOT TARGET ${target})
    message(FATAL_ERROR "erf_attach_version_header: no such target '${target}'")
  endif()
  add_dependencies(${target} erf_version_header)
  target_include_directories(${target} PUBLIC
    "$<BUILD_INTERFACE:${ERF_VERSION_HEADER_DIR}>"
    "$<INSTALL_INTERFACE:include>")
endfunction()
