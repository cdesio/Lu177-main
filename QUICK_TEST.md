# Lu177 Quick Test

This document describes how to run the end-to-end quick test script:

- `run_full_lu177_quick_test.sh`

The pipeline is:

1. `decaySimulation` (generate phase-space `.bin`)
2. `DNAsimulation/simulation` (consume phase-space, produce DNA ROOT output)
3. `DNAsimulation/Clustering` (produce damage CSV outputs)

## Script Location

- `/Users/yw18581/work/Lu177/run_full_lu177_quick_test.sh`

## What Must Be Installed

## System tools

- `cmake`
- C++ toolchain (compiler + make/ninja)
- Geant4 runtime/build dependencies available to CMake
- `python3`

## Python/Clustering environment

The clustering stage in `Lu177/DNAsimulation/Clustering` requires Python modules:

- `numpy`
- `scipy`
- `ROOT` (PyROOT)

Recommended conda env (example):

```bash
conda create -n clustering python=3.12 -y
conda activate clustering
conda install -c conda-forge numpy scipy root pybind11 -y
```

Validation:

```bash
conda run -n clustering python -c "import ROOT, numpy, scipy; print('ok')"
```

## Important Note About Current Script

`run_full_lu177_quick_test.sh` currently calls clustering with plain `python3`.

That means you should either:

1. Activate the clustering env before running the script, so `python3` points to the env Python:

```bash
conda activate clustering
/Users/yw18581/work/Lu177/run_full_lu177_quick_test.sh
```

2. Or run with an environment where `python3` has `numpy/scipy/ROOT` installed.

If you do not, the quick test may fail at clustering with missing module errors.

## Run the Quick Test

Default run:

```bash
/Users/yw18581/work/Lu177/run_full_lu177_quick_test.sh
```

Run with more decay primaries:

```bash
EVENTS=200 /Users/yw18581/work/Lu177/run_full_lu177_quick_test.sh
```

Custom output directory:

```bash
OUT_DIR=/Users/you/some/output/dir /Users/yw18581/work/Lu177/run_full_lu177_quick_test.sh
```

## Outputs

By default outputs go to:

- `/Users/yw18581/work/Lu177/quick_test_runs/quick_test_<timestamp>/`

Files include:

- `Ra224_quick_test.in`
- `decay_<tag>.bin`
- `decay_<tag>.root`
- `dna_<tag>.root`
- `damage_<tag>.csv`
- `DSBclusterSize_damage_<tag>.csv`

## Troubleshooting

## 1) Fails at clustering with `No module named ...`

Install required Python modules in the environment used by `python3` (`numpy`, `scipy`, `ROOT`).

## 2) `Phase-space file missing or empty`

Increase primaries:

```bash
EVENTS=200 /Users/yw18581/work/Lu177/run_full_lu177_quick_test.sh
```

## 3) Clustering output path issues

The current Lu177 clustering code expects `--output` as a filename-like value.
If absolute paths cause issues, run clustering from the target directory and pass a basename.

## 4) Build failures

Confirm Geant4 and CMake toolchain are correctly configured for both:

- `decaySimulation`
- `DNAsimulation/simulation`

