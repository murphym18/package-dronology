#!/bin/bash
# Packages dronology as a deb package
# Program Args:
#   1) path to Dronology (working git repo)

if [ "$#" -lt 1 ]
then
  echo "ERROR: you must provide the path to dronology as an argument"
  exit 1
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DRONOLOGY_DIR=$1
WORK_DIR=$PWD
VER=$(cd $DRONOLOGY_DIR; git rev-parse --short HEAD)
cd $WORK_DIR

PACKAGE_NAME="dronology-$VER-all"
OUT_DIR="$WORK_DIR/$PACKAGE_NAME"
mkdir -p "$OUT_DIR/DEBIAN"
mkdir -p "$OUT_DIR/usr/local/Dronology"
ls "$DRONOLOGY_DIR" | xargs tar -C "$DRONOLOGY_DIR" -cf - | tar -C "$OUT_DIR/usr/local/Dronology" -xf -
ls "$SCRIPT_DIR/dronology-prototype" | xargs tar -C "$SCRIPT_DIR/dronology-prototype" -cf - | tar -C "$OUT_DIR" -xf -

cat <<EOF > "$OUT_DIR/DEBIAN/control"
Package: Dronology
Version: $VER
Architecture: all
Essential: no
Priority: optional
Depends: adduser, openjdk-8-jdk, maven, mosquitto
Maintainer: Michael Murphy
Description: Dronology java backend
EOF

# preinst
################################################################################
cat <<EOF > "$OUT_DIR/DEBIAN/preinst"
#!/bin/bash
# preinst script for dronology

EOF
chmod 755 "$OUT_DIR/DEBIAN/preinst"

# postinst
################################################################################
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

setup_dronology_user

chown -R dronology:dronology /usr/local/Dronology
chown -R dronology:dronology /var/lib/dronology

cd /usr/local/Dronology
export HOME=/var/lib/dronology
sudo -u dronology -g dronology -- /usr/bin/mvn install -Dmaven.test.skip=true
systemctl daemon-reload
EOF
chmod 755 "$OUT_DIR/DEBIAN/postinst"

# prerm
################################################################################
cat <<EOF >>"$OUT_DIR/DEBIAN/prerm"
#!/bin/bash
# prerm script for dronology

systemctl stop dronology-omnibus.service dronology.service dronology-vaadin.service

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
