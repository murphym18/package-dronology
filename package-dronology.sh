#!/bin/bash
# Packages dronology as a deb package
# Program Args:
#   1) path to Dronology (working git repo)

# Check command line arguments
if [ "$#" -lt 1 ]
then
  echo "ERROR: you must provide the path to dronology as an argument"
  exit 1
fi

### Create some variables

# SCRIPT_DIR = The directory this file is in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# DRONOLOGY_DIR = the directory of the Dronology project
DRONOLOGY_DIR=$1

# WORK_DIR = the directory save the output to (the caller's working directory)
WORK_DIR=$PWD

# VER = the shortened commit hash of HEAD
VER=$(cd $DRONOLOGY_DIR; git rev-parse --short HEAD)


# compile the java and package it up
cd $DRONOLOGY_DIR
mvn clean
mvn package -Dmaven.test.skip=true
cd $WORK_DIR

### MAKE THE DEB SOURCE DIRECTORY
# This is the directory where we gather all the files that go in the deb package
PACKAGE_NAME="dronology-$VER-all"
OUT_DIR="$WORK_DIR/$PACKAGE_NAME"

DRONOLOGY_LIB_DIR="$DRONOLOGY_DIR/edu.nd.dronology.services.launch/target/edu.nd.dronology.services.launch-0.0.1-SNAPSHOT-bin/edu.nd.dronology.services.launch-0.0.1-SNAPSHOT/lib"
VAADIN_LIB_DIR="$DRONOLOGY_DIR/edu.nd.dronology.ui.vaadin/target/vaadinui-1.0-SNAPSHOT-bin/vaadinui-1.0-SNAPSHOT/lib"
VAADIN_WAR_FILE="$DRONOLOGY_DIR/edu.nd.dronology.ui.vaadin/target/vaadinui-1.0-SNAPSHOT.war"

# tar_pipe is like copy but directories are merged together
function tar_pipe() {
  SRC="$1"
  DEST="$2"
  mkdir -p "$DEST"
  ls "$SRC" | xargs tar -C "$SRC" -cf - | tar -C "$DEST" -xf -
}

# Copy the program files to the package
tar_pipe "$VAADIN_LIB_DIR" "$OUT_DIR/usr/local/Dronology/lib"
tar_pipe "$DRONOLOGY_LIB_DIR" "$OUT_DIR/usr/local/Dronology/lib"
tar_pipe "$SCRIPT_DIR/dronology-prototype" "$OUT_DIR"
cp "$VAADIN_WAR_FILE" "$OUT_DIR/usr/local/Dronology/webapps/ROOT.war"

# Get jetty
bash "$SCRIPT_DIR/download_jetty.sh"
JETTY_VERSION=$(cut -d" " -f1 "$SCRIPT_DIR/.cache/jetty_latest.txt")
tar -C "$OUT_DIR/usr/local/Dronology/" -xf "$SCRIPT_DIR/.cache/$JETTY_VERSION.tar"
find "$OUT_DIR/usr/local/Dronology/" -maxdepth 1 -type d -regex '^.*jetty.*' -exec mv {} "$OUT_DIR/usr/local/Dronology/jetty" \;

# Create the package meta files
mkdir -p "$OUT_DIR/DEBIAN"
cat <<EOF > "$OUT_DIR/DEBIAN/control"
Package: dronology
Version: 0.$VER
Architecture: all
Essential: no
Priority: optional
Depends: adduser, openjdk-8-jdk, maven, mosquitto
Maintainer: Michael Murphy
Description: Dronology java backend
EOF

### preinst
cat <<EOF > "$OUT_DIR/DEBIAN/preinst"
#!/bin/bash
# preinst script for dronology

EOF
chmod 755 "$OUT_DIR/DEBIAN/preinst"

### postinst
cat <<EOF > "$OUT_DIR/DEBIAN/postinst"
#!/bin/bash
# postinst script for dronology

setup_dronology_user() {
	if ! getent group dronology >/dev/null; then
		addgroup --quiet --system dronology
	fi

	if ! getent passwd dronology >/dev/null; then
    adduser \
      --quiet \
      --system \
      --ingroup dronology \
      --shell /usr/sbin/nologin \
      --gecos "Dronology Service" \
      --no-create-home \
      --home /var/lib/dronology \
      --disabled-login \
      dronology
	fi
}

setup_dronology_script() {
  chmod 555 "\$1"
  chown root:root "\$1"
}

setup_dronology_user

setup_dronology_script "/usr/local/bin/dronology-start"
setup_dronology_script "/usr/local/bin/dronology-stop"
setup_dronology_script "/usr/local/bin/dronology-logs"

chown -R dronology:dronology /usr/local/Dronology
chown -R dronology:dronology /var/lib/dronology

systemctl daemon-reload

EOF
chmod 755 "$OUT_DIR/DEBIAN/postinst"

### prerm
cat <<EOF >>"$OUT_DIR/DEBIAN/prerm"
#!/bin/bash
# prerm script for dronology

systemctl stop dronology-omnibus.service dronology.service dronology-vaadin.service

EOF
chmod 755 "$OUT_DIR/DEBIAN/prerm"

### postrm
cat <<EOF >"$OUT_DIR/DEBIAN/postrm"
#!/bin/bash
# postrm script for dronology

systemctl daemon-reload
EOF
chmod 755 "$OUT_DIR/DEBIAN/postrm"

dpkg-deb --build "$OUT_DIR"
