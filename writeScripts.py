'''
Create all files required to run both steps of simulation. saves files in a results folder
'''

import numpy as np
import os
import random

# parameters to set
folder = "test"
numThread = 2
seeds = [random.randint(1, 10000) for a in range(1)]
rMin = 155
rMax = 245
histoneFile = "../../DNAsimulation/geometryFiles/histonePositions_4x4_300nm.csv"
sugarFile = "../../DNAsimulation/geometryFiles/sugarPos_4x4_300nm.csv"

targetSize = 300 #nanometers
gpsRadius = 1 #micrometers
printProgress = 10
numIons = 100

time = "0-00:10"
mem = 1
projectcode = "IFAC023282"
####
os.makedirs(f"./results/{folder}")

for seed in seeds:
    filename = f"Lu177_{seed}.sh" #to be run from folder created
    with open(f"./results/{folder}/"+ filename , 'w') as f:
        f.write("#!/bin/bash --login\n")

        f.write(f"#SBATCH --job-name=Lu177_{seed}\n")
        f.write(f"#SBATCH --output=Lu177_{seed}.out.%J\n")
        f.write(f"#SBATCH --error=Lu177_{seed}.err.%J\n")
        # maximum job time in D-HH:MM
        f.write(f"#SBATCH --time={time}\n")
        f.write("#SBATCH --nodes=1\n")
        f.write("#SBATCH -p short\n")
        f.write(f"#SBATCH --ntasks-per-node={numThread}\n") 
        f.write(f"#SBATCH --mem {mem}GB\n")
        f.write(f"#SBATCH --account={projectcode}\n")
        f.write("\n")
        f.write("module add apps/geant/4.11.0.0\n")

        f.write(f"time ../../decaySimulation/build/decay -mac Lu177.in -out Lu177_part1_{seed} -seed {seed}\n")

        f.write(f"time ../../DNAsimulation/simulation/build/dna -mac dna_PS.in -PS Lu177_part1_{seed}.bin -out Lu177_part2_{seed} -sugar {sugarFile} -histone {histoneFile} -seed {seed} \n")

        f.write("module load apps/root/6.26.00\n")

        f.write("conda activate clustering\n")

        for i in range(10):
            f.write(f"python ../../DNAsimulation/Clustering/run.py --filename Lu177_part2_{seed}.root --output Lu177_{seed}_copy{i}.csv --sugar {sugarFile} --copy {i}\n")


filename = f"./results/{folder}/Lu177.in" #to be run from folder created
with open(filename , 'w') as f:
    f.write("/run/verbose 2\n")
    f.write("/control/verbose 2\n")
    f.write(f"/det/cellPos_min {rMin} micrometer\n")
    f.write(f"/det/cellPos_max {rMax} micrometer\n")
    f.write("/run/initialize\n")

    f.write("/gun/particle ion\n")
    f.write("/gun/ion 88 224 0 0\n")

    f.write(f"/run/printProgress {printProgress}\n")
    f.write(f"/run/beamOn {numIons}\n")

filename = f"./results/{folder}/dna_PS.in" #to be run from folder created
with open(filename , 'w') as f:
    f.write("/run/verbose 2\n")
    f.write("/control/verbose 2\n")
    f.write(f"/det/setSize 300 nm\n")
    f.write(f"/det/dkill 9 nm\n")
    f.write(f"/run/numberOfThreads {numThread}\n")
    f.write("/run/initialize\n")

    f.write(f"/run/printProgress {printProgress}\n")