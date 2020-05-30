import subprocess
import os
from pathlib import Path
import sys

num_drones = int(sys.argv[1])
bash = Path('/bin/bash')
Px4_home = Path('/opt/Firmware')
jmavsim_backend = px4_home / 'Tools' / 'sitl_multiple_run.sh'
jmavsim_drone = px4_home / 'Tools' / 'jmavsim_run.sh'

-p 4562 -l
./Tools/jmavsim_run.sh -p 4561

world_simulator_cmd = [
    os.fspath(bash),
    os.fspath(jmavsim_backend),
    str(num_drones)
]

world_starter = subprocess.Popen(world_simulator_cmd)
world_starter.wait()

drone_processes = []

start_port = 4560
for port in range(start_port, start_port + num_drones):
    drone_simulator_cmd = [
        os.fspath(bash),
        os.fspath(jmavsim_drone),
        '-p', str(port),
        '-l'
    ]
    drone = subprocess.Popen(world_simulator_cmd)
    drone_processes.append(drone)

for process in drone_processes:
    process.wait()
