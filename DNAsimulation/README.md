# DNAsimulation

Geant4-DNA simulation of direct and indirect DNA damage. This code can run:

1. Standalone primary simulations (alpha/proton/electron via GPS).
2. Phase-space driven simulations using particle records from `../decaySimulation`.

The simulation writes ROOT ntuples for event energy, direct interactions, and chemistry-mediated interactions. The `Clustering` module then converts these into strand-break metrics.

## Directory layout

- `simulation/`: Geant4 executable (`dna`) and input macros.
- `geometryFiles/`: scripts to generate DNA/histone geometry CSV files.
- `Clustering/`: C++/Python clustering pipeline for strand-break analysis.
- `testSet/`: reproducible test scripts and reference comparisons.

## Build

From `DNAsimulation/simulation`:

```bash
mkdir -p build
cd build
cmake ..
make -j8
```

This builds the `dna` executable.

## Required geometry inputs

`dna` expects:

- `-sugar <file>`: sugar/base position CSV.
- `-histone <file>`: histone position CSV.

Generate these from `geometryFiles/plotChromatinFibreSection.py` if needed.

## Runtime modes

### 1) Standalone GPS mode (no phase space)

Use `dna.in` (or your own macro) and provide sugar/histone files:

```bash
./dna -mac dna.in -out run_alpha -sugar /path/to/sugar.csv -histone /path/to/histone.csv -seed 123
```

In this mode primaries come from GPS macro commands (`/gps/...`).

### 2) Phase-space mode (from decaySimulation)

Use phase-space written by `../decaySimulation` (`float[12]` binary records). Run:

```bash
./dna -mac dna_PS.in -out run_ps -sugar /path/to/sugar.csv -histone /path/to/histone.csv -PS /path/to/PSfile.bin -seed 123
```

In this mode each phase-space record is replayed as one event.

## Main command-line options

- `-mac <file>`: macro file to execute.
- `-out <name>`: ROOT output filename stem.
- `-seed <int>`: RNG seed.
- `-gui`: visualization session.
- `-chemOFF`: disable DNA chemistry stage.
- `-sugar <file>`: sugar/base geometry input.
- `-histone <file>`: histone geometry input.
- `-PS <file>`: phase-space binary input (enables phase-space replay mode).

## Key macro controls

- `/det/setSize`: target box size (should match geometry generation assumptions).
- `/det/dkill`: radical culling distance from DNA.
- `/run/numberOfThreads`: Geant4 thread count.
- `/scheduler/endTime`: chemistry end time.
- `/run/beamOn`: number of primaries (or ignored in `-PS` mode if BeamOn is set by record count).

## Output summary

The ROOT output contains ntuples including:

- `EventEdep`: event-level deposited energy and track summary.
- `Direct`: direct energy deposition points in DNA volumes.
- `Indirect`: chemistry reactions involving DNA molecules.
- `Info`: run metadata (volume, basepairs count, git hash, Geant4 version, model).
- `Events` (only with `-PS`): mapping between DNA event ID and upstream event ID.

## Clustering workflow

`Clustering/` consumes the ROOT output and reports strand-break classes (SSB, cSSB, DSB, etc.) and DSB cluster-size distributions. See `Clustering/run.py` and `testSet/README.md` for runnable examples.

## Notes

- Older references to executable name `rbe` and `photon_simulation` are legacy and not applicable to this repository layout.
- Top-level project context is in `../README.md`, including the decay-to-DNA two-stage workflow.
