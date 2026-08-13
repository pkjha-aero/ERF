# ERF Build System Guide

This guide explains how to configure, build, and install ERF with various options and on different platforms.

## Quick Start

### Using CMake Presets (Recommended)

CMake Presets provide convenient, reproducible build configurations. List available presets:

```bash
cmake --list-presets
```

Build with a preset:

```bash
cmake --preset default
cmake --build --preset default
```

Available presets:
- **default**: Serial debug build (good for development)
- **release**: Serial optimized build
- **parallel**: MPI + OpenMP (CPU parallelism)
- **gpu-cuda**: NVIDIA GPU support
- **gpu-hip**: AMD GPU support
- **minimal**: Minimal build without optional dependencies
- **ci-gcc**: CI build with GCC
- **ci-clang**: CI build with Clang

### Manual Configuration

```bash
mkdir build && cd build
cmake -DERF_ENABLE_MPI=ON -DERF_ENABLE_OPENMP=ON ..
cmake --build . -j 4
```

## CMake Options Reference

### Dimension & Precision

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_DIM` | 3 | Number of spatial dimensions (3 only) |
| `ERF_PRECISION` | DOUBLE | Mesh precision: SINGLE or DOUBLE |
| `ERF_PARTICLES_PRECISION` | DOUBLE | Particle precision: SINGLE or DOUBLE |

### Performance & Parallelism

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_ENABLE_MPI` | OFF | Enable multi-process parallelism (MPI) |
| `ERF_ENABLE_OPENMP` | OFF | Enable multi-threading (OpenMP) |
| `ERF_ENABLE_CUDA` | OFF | Enable NVIDIA GPU (CUDA 11.0+) |
| `ERF_ENABLE_HIP` | OFF | Enable AMD GPU (ROCm) |
| `ERF_ENABLE_SYCL` | OFF | Enable Intel GPU (SYCL) |
| `ERF_ENABLE_NVHPC` | OFF | Enable NVIDIA compiler suite |

### GPU Architecture (when GPU enabled)

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_CUDA_ARCH` | auto | CUDA architecture: 'auto', 'native', '80', '90', etc. |
| `ERF_HIP_ARCH` | gfx90a | HIP architecture: gfx90a (MI250X), gfx908 (MI100), etc. |

### I/O & Dependencies

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_ENABLE_NETCDF` | OFF | Enable NetCDF I/O |
| `ERF_ENABLE_HDF5` | OFF | Enable HDF5 I/O (required for NetCDF) |
| `ERF_ENABLE_PARTICLES` | OFF | Enable Lagrangian particle tracking |
| `ERF_ENABLE_FCOMPARE` | OFF | Build fcompare utility |

### Parameterizations

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_ENABLE_NOAHMP` | OFF | Enable Noah-MP land surface model |
| `ERF_ENABLE_WINDFARM` | OFF | Enable wind farm parameterizations |
| `ERF_ENABLE_WSM6_FORT` | OFF | Enable WSM6 microphysics (Fortran) |
| `ERF_ENABLE_RRTMGP` | OFF | Enable RRTMGP radiation |
| `ERF_ENABLE_EAMXX_SHOC` | OFF | Enable EAMxx SHOC parameterization |

### Testing & Documentation

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_ENABLE_TESTS` | OFF | Enable unit and regression tests |
| `ERF_ENABLE_UNIT_TESTS` | OFF | Enable gtest-based unit tests |
| `ERF_ENABLE_REGRESSION_TESTS_ONLY` | OFF | Enable only regression tests |
| `ERF_ENABLE_DOCUMENTATION` | OFF | Build Doxygen documentation |
| `CODECOVERAGE` | OFF | Enable code coverage profiling (GCC only) |

### Build Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `ERF_USE_INTERNAL_AMREX` | ON | Use bundled AMReX submodule |
| `ERF_ENABLE_ALL_WARNINGS` | ON | Enable strict compiler warnings |
| `CMAKE_BUILD_TYPE` | - | Build type: Debug, Release, RelWithDebInfo |

## Option Compatibility Matrix

Certain options have dependencies and conflicts:

| Requirement | Enables | Incompatible | Notes |
|-------------|---------|--------------|-------|
| WSM6_FORT | Fortran | - | Requires PRECISION=DOUBLE |
| NOAHMP | Fortran, MPI, NetCDF | - | Requires NetCDF |
| RRTMGP | EKAT, Kokkos, MPI | - | Large dependency set |
| ML_UPHYS_DIAGNOSTICS | - | PARTICLES=OFF | Requires particles |
| CUDA | CUDA toolkit 11.0+ | HIP, SYCL | Cannot mix GPU backends |
| HIP | ROCm | CUDA, SYCL | Cannot mix GPU backends |
| SYCL | Intel oneAPI | CUDA, HIP | Cannot mix GPU backends |

## Common Build Configurations

### Development (Debug, Serial)
```bash
cmake --preset default
cmake --build --preset default -j 4
```

### Production (Release, MPI+OpenMP)
```bash
cmake --preset parallel
cmake --build --preset parallel -j 8
```

### GPU Development (CUDA)
```bash
cmake --preset gpu-cuda
cmake --build --preset gpu-cuda -j 4
```

### CI with Coverage (GCC)
```bash
cmake --preset ci-gcc
cmake --build --preset ci-gcc -j 8
ctest --output-on-failure
```

### Custom Configuration
```bash
mkdir build && cd build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DERF_ENABLE_MPI=ON \
  -DERF_ENABLE_OPENMP=ON \
  -DERF_ENABLE_NETCDF=ON \
  -DERF_ENABLE_TESTS=ON \
  -DERF_CUDA_ARCH="80 90" \
  ..
cmake --build . -j 16
ctest --output-on-failure
```

## Compiler-Specific Notes

### GCC
- Recommended version: 7.0+
- Warnings enabled by default (ERF_ENABLE_ALL_WARNINGS=ON)
- Code coverage supported via CODECOVERAGE=ON

```bash
cmake -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc ..
```

### Clang
- Recommended version: 5.0+
- Similar warning support to GCC
- Faster compilation on some systems

```bash
cmake -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang ..
```

### Intel
- Recommended version: 18.0+
- Some warnings disabled (diag-disable:11074,11076)
- NVHPC can be used for GPU support

```bash
cmake -DCMAKE_CXX_COMPILER=icpc -DCMAKE_C_COMPILER=icc ..
```

### NVIDIA HPC (NVHPC)
- Requires NVHPC toolkit for CUDA compilation
- Recommended for GPU-only builds

```bash
module load nvhpc
cmake -DERF_ENABLE_CUDA=ON -DERF_ENABLE_NVHPC=ON ..
```

## HPC System Configuration

### Cray Systems (Perlmutter, Summit, etc.)

Cray automatically sets compilers via module wrappers. Load modules first:

```bash
module load cmake
module load cray-mpich
module load cray-hdf5
cmake -DERF_ENABLE_MPI=ON -DERF_ENABLE_HDF5=ON ..
```

Special note: Cray MPI wrappers are detected automatically; no additional configuration needed.

### Summit (IBM Power)

```bash
module load cmake/3.20+
module load xl
module load essl
cmake \
  -DCMAKE_CXX_COMPILER=xlc++ \
  -DERF_ENABLE_MPI=ON \
  -DERF_ENABLE_OPENMP=ON \
  -DERF_ENABLE_CUDA=ON \
  ..
```

### Frontier (AMD GPUs)

```bash
module load cmake
module load rocm
cmake \
  -DERF_ENABLE_MPI=ON \
  -DERF_ENABLE_HIP=ON \
  -DERF_ENABLE_OPENMP=ON \
  -DERF_HIP_ARCH=gfx90a \
  ..
```

## Performance Tuning

### Build Time Optimization

1. **Use ccache** (auto-detected):
   ```bash
   module load ccache  # or sccache
   # ccache is automatically used if found
   ```

2. **Parallel build jobs**:
   ```bash
   cmake --build . -j $(nproc)
   ```

3. **Incremental builds**:
   ```bash
   # Only rebuild changed targets
   cmake --build . -j 8 --target erf_abl
   ```

### Runtime Optimization

1. **Release build** (much faster than Debug):
   ```bash
   cmake -DCMAKE_BUILD_TYPE=Release ..
   ```

2. **CUDA fast math** (slightly less accurate):
   ```bash
   cmake -DERF_ENABLE_CUDA=ON -DENABLE_CUDA_FASTMATH=ON ..
   ```

3. **OpenMP tuning**:
   ```bash
   export OMP_NUM_THREADS=8
   export OMP_PLACES=cores
   export OMP_PROC_BIND=spread
   ```

## Installation

### System-wide Installation

```bash
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
cmake --build .
sudo cmake --install .
```

### User Installation

```bash
cmake -DCMAKE_INSTALL_PREFIX=$HOME/software/erf ..
cmake --build .
cmake --install .
```

### Using Installed ERF

After installation, use ERF as a CMake package:

```cmake
# In your project's CMakeLists.txt
find_package(ERF 26.06 REQUIRED)

target_link_libraries(my_app ERF::erf_api)
target_include_directories(my_app PRIVATE ${ERF_INCLUDE_DIRS})
```

## Troubleshooting

### "MPI not found"
```bash
# Option 1: Load MPI module
module load openmpi  # or cray-mpich, etc.

# Option 2: Specify MPI compiler wrapper
cmake -DMPI_CXX_COMPILER=mpicxx -DMPI_C_COMPILER=mpicc ..

# Option 3: Disable MPI if not needed
cmake -DERF_ENABLE_MPI=OFF ..
```

### "CUDA/HIP compiler not found"
```bash
# CUDA: Ensure CUDA toolkit is in PATH
export PATH=/usr/local/cuda/bin:$PATH

# HIP: Load ROCm module
module load rocm
```

### "Compiler warnings as errors"
Warnings are errors in CI by default. For development:
```bash
cmake -DERF_ENABLE_ALL_WARNINGS=OFF ..
```

Or fix the warnings (recommended).

### Build cache issues
```bash
# Clear cmake cache
rm -rf CMakeCache.txt CMakeFiles/

# Clear compiler cache (if using ccache)
ccache --clear

# Full rebuild
cmake --build . --clean-first -j 8
```

### Out-of-memory during compilation
Reduce parallel jobs:
```bash
cmake --build . -j 2
```

Or reduce optimization level for large files:
```bash
cmake -DCMAKE_CXX_FLAGS_RELEASE="-O1" ..
```

## Advanced Configuration

### Custom Compiler Flags

```bash
cmake \
  -DCMAKE_CXX_FLAGS="-march=native -mtune=native" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  ..
```

### Static Linking

```bash
cmake -DBUILD_SHARED_LIBS=OFF ..
```

### Cross-Compilation

Requires a toolchain file:

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=./Toolchain-ARM.cmake ..
```

### Ninja Build System

```bash
cmake -G Ninja ..
ninja -j 8
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Build ERF
  run: |
    cmake --preset ci-gcc
    cmake --build --preset ci-gcc -j 4
    ctest --preset default --output-on-failure
```

### Jenkins

```groovy
stage('Build') {
  steps {
    sh '''
      cmake --preset parallel
      cmake --build --preset parallel -j 8
      ctest --output-on-failure
    '''
  }
}
```

## Building Documentation

```bash
cmake -DERF_ENABLE_DOCUMENTATION=ON ..
cmake --build . --target doxygen
# Output: build/docs/html/index.html
```

## Related Files

- [DEPENDENCIES.md](DEPENDENCIES.md) — Required and optional dependencies
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contribution guidelines
- [CMakePresets.json](CMakePresets.json) — Preset configurations
- [CMakeLists.txt](CMakeLists.txt) — Main build configuration

## Support

For build issues:
1. Check [DEPENDENCIES.md](DEPENDENCIES.md) for version requirements
2. Check this guide for compiler-specific notes
3. Run with verbose output: `cmake --build . --verbose`
4. Report issues on GitHub with full cmake output
