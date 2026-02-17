# Lu177 Simulation

## Origin
Repo created from two repos:
  - git@github.com:lg9783/DaRT.git/savePS at commit e491462d018ba29f9ab55aab8d1c2a15dc268f7e -> decaySimulation folder
  - git@github.com:lg9783/RBE.git/inputFromDaRT at commit 420bb06e90c883b7768beacc1f064bd8fd189c93 -> DNAsimulation folder
  
## Overview
- The decaySimulation simulates a cylindrical source, where the source is placed randomly on the surface of the cylinder. The cylinder is surrounded by 10 rings of boxes, the radius of which can be changed from the mac file. Particles entering these boxes are transformed to the box coordinate system and saved to a phase space file.
- The DNAsimulation reads the phase space file as an input and runs the DNA simulation, see seperate README.

## How to Run
