# Install

To use this tool you must install the dependencies:
 
```bash
sudo apt install --yes jq openjdk-8-jdk maven
```

Clone this repo, for example:

```bash
cd ~/Desktop
git clone git@github.com:murphym18/package-dronology.git
```

# Usage

Clone the dronology and dronology-gcs repos and `checkout` the version you want to package. The packaging scripts assume the repos are clean.

This example clones the repos into a directory called `clean-repos` on the desktop:
```bash
mkdir -p ~/Desktop/clean-repos

cd ~/Desktop/clean-repos
git clone git@github.com:SAREC-Lab/Dronology.git
cd Dronology
git checkout 2020_Spring_DroneResponse

cd ~/Desktop/clean-repos
git clone git@github.com:SAREC-Lab/Dronology-GCS.git
cd Dronology-GCS
git checkout py3
```

## Build Dronology
`cd` to where you want the generated deb files to go. Run the package script for dronology, called `package-dronology.sh`, giving it the path to the `Dronology`. For example:

```bash
mkdir -p ~/Desktop/package-dronology/out
cd ~/Desktop/package-dronology/out
bash ../package-dronology.sh ~/Desktop/clean-repos/Dronology
```

## Build Dronology-GCS
`cd` to where you'd like the deb file to be saved. Run the package script for the ground control station called, `package-dronology-gcs.sh`, passing it the path to `Dronology-GCS`

```bash
mkdir -p ~/Desktop/package-dronology/out
cd ~/Desktop/package-dronology/out
bash ../package-dronology-gcs.sh ~/Desktop/clean-repos/Dronology-GCS
```

## Build the simulation service
The simulation service includes scripts to start and stop simulations. It also includes systemd units that help you run simulations on a server.

`cd` to where you'd like to deb file to be saved. Run the script that makes the `deb` package, called `package-simulation-service.sh`.

```bash
mkdir -p ~/Desktop/package-dronology/out
cd ~/Desktop/package-dronology/out
bash ../package-simulation-service.sh
```
