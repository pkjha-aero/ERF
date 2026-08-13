# ERF Dependencies

This document specifies the required versions and compatibility ranges for ERF dependencies.

## Core Dependencies

### CMake
- **Minimum:** 3.20
- **Recommended:** 3.24+
- **Notes:** CMake 3.20+ required for FATAL_ERROR behavior; 3.21+ enables CMakePresets.json support

### C++ Standard
- **Requirement:** C++17
- **Compilers:**
  - GCC 7.0+
  - Clang 5.0+
  - Intel 18.0+
  - NVHPC 21.0+
  - MSVC 2017+

## Mandatory Dependencies

### AMReX
- **Minimum Version:** 23.10
- **Recommended:** Latest stable (24.x)
- **Build Options:**
  - 3D support required
  - Fortran support (if `ERF_ENABLE_MORR_FORT` or `ERF_ENABLE_WSM6_FORT`)
  - Linear solvers enabled
  - EB (Embedded Boundary) support
- **Repository:** https://github.com/AMReX-codes/AMReX.git

## Optional Dependencies

### NetCDF
- **Minimum Version:** 4.6.1
- **Recommended:** 4.8.0+
- **Enabled by:** `ERF_ENABLE_NETCDF=ON`
- **Build Requirements:** HDF5 support
- **Repository:** https://www.unidata.ucar.edu/downloads/netcdf/

### HDF5
- **Minimum Version:** 1.10.0
- **Recommended:** 1.12.0+
- **Enabled by:** `ERF_ENABLE_HDF5=ON`
- **Note:** Required for NetCDF I/O

### Noah-MP
- **Location:** Submodule at `Submodules/NOAHMP`
- **Build Type:** Fortran bridge
- **Enabled by:** `ERF_ENABLE_NOAHMP=ON`
- **Requirements:** Fortran compiler, MPI, NetCDF

### RRTMGP
- **Location:** Submodule at `Submodules/RRTMGP/cpp`
- **Minimum Version:** Compatible with submodule tag
- **Enabled by:** `ERF_ENABLE_RRTMGP=ON`
- **Requirements:** MPI, EKAT, Kokkos
- **Repository:** https://github.com/earth-system-radiation/rrtmgp.git

### EKAT
- **Location:** Submodule at `Submodules/ekat`
- **Enabled by:** `ERF_ENABLE_RRTMGP=ON`, `ERF_ENABLE_EAMXX_SHOC=ON`, or `ERF_ENABLE_P3=ON`
- **Requirements:** MPI, Kokkos
- **Repository:** https://github.com/E3SM-Project/EKAT.git

### Kokkos
- **Minimum Version:** 3.6.0 (via EKAT)
- **Recommended:** 4.x
- **Build Backends:**
  - Serial (default)
  - OpenMP
  - CUDA 11.0+
  - HIP (ROCm)
  - SYCL
- **Repository:** https://github.com/kokkos/kokkos.git

### MPI
- **Minimum Version:** MPI 3.0 standard
- **Implementations:** OpenMPI, MPICH, Cray MPICH
- **Enabled by:** `ERF_ENABLE_MPI=ON`
- **Cray Note:** Special detection for bare MPI wrappers that would hang

## Compiler-Specific Requirements

### CUDA
- **Minimum Version:** 11.0
- **Enabled by:** `ERF_ENABLE_CUDA=ON`
- **CMake:** Requires C/C++ support

### HIP (ROCm)
- **Minimum Version:** ROCm 4.0+
- **Enabled by:** `ERF_ENABLE_HIP=ON`
- **Architecture:** Defaults to `gfx90a` (MI250X)
- **Environment Variables:**
  - `ROCM_GPU`: GPU architecture
  - `HIPARCHS`: Alternative GPU architecture setting
  - `HIP_ARCH`: Another alternative

### SYCL
- **Minimum Version:** Intel oneAPI 2021.2+
- **Enabled by:** `ERF_ENABLE_SYCL=ON`

## Testing Dependencies

### GTest
- **Version:** Automatically fetched by AMReX
- **Enabled by:** `ERF_ENABLE_TESTS=ON`

## Development Dependencies

### Doxygen
- **Minimum Version:** 1.8.0
- **Enabled by:** `ERF_ENABLE_DOCUMENTATION=ON`

### Python (for post-processing)
- **Minimum Version:** 3.7
- **Tools:** See `erftools` repository
- **Repository:** https://github.com/erf-model/erftools.git

## Version Compatibility Matrix

| AMReX | NetCDF | HDF5 | CUDA | ROCm | Status     |
|-------|--------|------|------|------|------------|
| 23.10 | 4.6.1+ | 1.10 | 11.0 | 4.0+ | Minimum   |
| 24.x  | 4.8.0+ | 1.12 | 12.0 | 5.0+ | Preferred |
| 25.x  | TBD    | TBD  | 12.0 | 5.0+ | In dev    |

## Known Incompatibilities

- `ERF_ENABLE_WSM6_FORT` requires `ERF_PRECISION=DOUBLE`
- `ERF_ENABLE_ML_UPHYS_DIAGNOSTICS` requires `ERF_ENABLE_PARTICLES=ON`
- `ERF_ENABLE_RRTMGP` requires MPI and EKAT
- Kokkos GPU backends (CUDA, HIP, SYCL) cannot be mixed

## Updating Dependencies

To update submodule dependencies:

```bash
# Update specific submodule
git submodule update --remote Submodules/AMReX

# Or update all submodules
git submodule update --remote --recursive
```

For system-level dependencies, ensure compatibility with the versions above before building with external packages enabled.

## Reporting Dependency Issues

When reporting compatibility issues:
1. Include exact version numbers: `cmake --version`, `gcc --version`, etc.
2. List enabled CMake options from `cmake_cache_dump.cmake`
3. Provide full build logs with verbose flag: `cmake --build . --verbose`
