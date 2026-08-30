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

set(_erf_version_command
    "${_erf_version_python}" "${_erf_version_script}"
    --template        "${_erf_version_template}"
    --output          "${_erf_version_output}"
    --source-dir      "${PROJECT_SOURCE_DIR}")

file(MAKE_DIRECTORY "${ERF_VERSION_HEADER_DIR}")

# Generate once now so the header exists for the first build, even before the
# custom target runs.
execute_process(COMMAND ${_erf_version_command} RESULT_VARIABLE _erf_version_rc)
if(NOT _erf_version_rc EQUAL 0 OR NOT EXISTS "${_erf_version_output}")
  message(WARNING
    "ERF: could not run Tools/gen_erf_version.py (rc=${_erf_version_rc}); "
    "writing a placeholder ERF_Version.H without git metadata")
  # Every placeholder in the template must be set here, or the header ships with
  # a literal @ERF_...@ in it and fails to compile.
  set(ERF_VERSION       "${ERF_VERSION_STRING}")
  set(ERF_GIT_SHA       "unknown")
  set(ERF_GIT_DIRTY     "false")
  set(ERF_GIT_BRANCH    "unknown")
  set(ERF_GIT_PARENT    "unknown")
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
