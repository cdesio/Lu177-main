# Lu177 Simulation

## Origin

This repository combines two codebases:

- `DaRT` branch `savePS` -> `decaySimulation/`
- `RBE` branch `inputFromDaRT` -> `DNAsimulation/`

## End-to-end workflow

The project is a two-stage Geant4 pipeline:

1. `decaySimulation` models radioactive decays in and around a cylindrical source.
2. Particles entering target cell volumes are written to a binary phase-space file (`.bin`).
3. `DNAsimulation` reads that phase-space file (`-PS`) and runs Geant4-DNA transport/chemistry in chromatin geometry.
4. `DNAsimulation/Clustering` post-processes ROOT outputs into strand-break metrics (SSB, cSSB, DSB, cluster sizes).

## Repository layout

- `decaySimulation/`: stage 1 source/decay simulation and phase-space generation.
- `DNAsimulation/simulation/`: stage 2 DNA-scale simulation (`dna` executable).
- `DNAsimulation/geometryFiles/`: geometry generation scripts (sugar/histone positions).
- `DNAsimulation/Clustering/`: clustering and break classification.
- `DNAsimulation/testSet/`: reproducible test scripts.

## Build

### Build decay simulation

```bash
cd decaySimulation
mkdir -p build
cd build
cmake ..
make -j8
```

### Build DNA simulation

```bash
cd DNAsimulation/simulation
mkdir -p build
cd build
cmake ..
make -j8
```

## Run

### 1) Run decay stage (produce phase space)

From `decaySimulation/build`:

```bash
./decay -mac Ra224.in -out PSfile -seed 123
```

This produces:

- `PSfile.bin` (phase-space records for downstream DNA simulation)
- `PSfile.root` (run metadata/output ntuple)

### 2) Prepare DNA geometry inputs

If needed, generate geometry CSV files:

```bash
cd DNAsimulation/geometryFiles
python plotChromatinFibreSection.py
```

### 3) Run DNA stage using phase space

From `DNAsimulation/simulation/build`:

```bash
./dna -mac dna_PS.in -out dna_from_ps -PS /path/to/PSfile.bin -sugar /path/to/sugar.csv -histone /path/to/histone.csv -seed 123
```

## Optional standalone DNA mode

`DNAsimulation` can also be run without `-PS` using GPS primaries configured in `dna.in`.

## Notes

- `decaySimulation` and `DNAsimulation` each have their own detailed README:
  - `decaySimulation/` source and macros
  - `DNAsimulation/README.md` for simulation, output ntuples, and clustering details
- Relative script paths in helper scripts are environment-dependent; adjust to your local layout as needed.
