#!/bin/bash
# Packages dronology-gcs as a deb package
# Program Args:
#   1) path to Dronology-GCS (working git repo)

if [ "$#" -lt 1 ]
then
  echo "ERROR: you must provide the path to dronology as an argument"
  exit 1
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GCS_DIR=$1
WORK_DIR=$PWD
VER=$(cd $GCS_DIR; git rev-parse --short HEAD)
cd $WORK_DIR

PACKAGE_NAME="gcs-$VER-all"
OUT_DIR="$WORK_DIR/$PACKAGE_NAME"
mkdir -p "$OUT_DIR/DEBIAN"
mkdir -p "$OUT_DIR/usr/local/Dronology-GCS"
ls "$GCS_DIR" | xargs tar -C "$GCS_DIR" -cf - | tar -C "$OUT_DIR/usr/local/Dronology-GCS" -xf -
ls "$SCRIPT_DIR/gcs-prototype" | xargs tar -C "$SCRIPT_DIR/gcs-prototype" -cf - | tar -C "$OUT_DIR" -xf -

cat <<EOF > "$OUT_DIR/DEBIAN/control"
Package: Dronology-GCS
Version: $VER
Architecture: all
Essential: no
Priority: optional
Depends: dronology
Maintainer: Michael Murphy
Description: Dronology ground control station
EOF

# postinst
################################################################################
cat <<EOF > "$OUT_DIR/DEBIAN/postinst"
#!/bin/bash
# postinst script for dronology-gcs

setup_dronology_script() {
  chmod 555 "\$1"
  chown root:root "\$1"
}

setup_dronology_script "/usr/local/bin/gcs-start"
setup_dronology_script "/usr/local/bin/gcs-stop"
setup_dronology_script "/usr/local/bin/gcs-logs"

chown -R dronology:dronology /usr/local/Dronology-GCS

export HOME=/var/lib/dronology

cd /usr/local/Dronology-GCS
sudo -u dronology -g dronology -- /usr/bin/env python3.8 -m venv .venv
source .venv/bin/activate
sudo -u dronology -g dronology -- /usr/local/Dronology-GCS/.venv/bin/pip install --upgrade pip
sudo -u dronology -g dronology -- /usr/local/Dronology-GCS/.venv/bin/pip install -r requirements.txt

systemctl daemon-reload

EOF
chmod 755 "$OUT_DIR/DEBIAN/postinst"

# prerm
################################################################################
cat <<EOF >>"$OUT_DIR/DEBIAN/prerm"
#!/bin/bash
# prerm script for dronology

systemctl stop gcs.service

EOF
chmod 755 "$OUT_DIR/DEBIAN/prerm"

# postrm
################################################################################
cat <<EOF >"$OUT_DIR/DEBIAN/postrm"
#!/bin/bash
# postrm script for dronology

systemctl daemon-reload
EOF
chmod 755 "$OUT_DIR/DEBIAN/postrm"

dpkg-deb --build "$OUT_DIR"
