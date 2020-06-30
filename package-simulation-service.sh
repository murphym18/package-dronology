#!/bin/bash
# makes the simulation-service deb package

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$PWD
VER=$(cd $SCRIPT_DIR; git rev-parse --short HEAD)
PACKAGE_NAME="simulation-service-0.$VER-all"
OUT_DIR="$WORK_DIR/$PACKAGE_NAME"
cd $WORK_DIR

mkdir -p "$OUT_DIR/DEBIAN"

function tar_pipe() {
  SRC="$1"
  DEST="$2"
  mkdir -p "$DEST"
  ls "$SRC" | xargs tar -C "$SRC" -cf - | tar -C "$DEST" -xf -
}
tar_pipe "$SCRIPT_DIR/simulation-service-prototype" "$OUT_DIR"


cat <<EOF > "$OUT_DIR/DEBIAN/control"
Package: simulation-service
Version: 0.$VER
Architecture: all
Essential: no
Priority: optional
Maintainer: Michael Murphy
Description: Scripts and service units for PX4 simulator
EOF

### postinst
cat <<EOF > "$OUT_DIR/DEBIAN/postinst"
#!/bin/bash
# postinst script for simulation-service

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

function setup_helper_script() {
  chmod 555 "\$1"
  chown root:root "\$1"
}

setup_helper_script "/usr/local/bin/simulator-logs"
setup_helper_script "/usr/local/bin/simulator-start"
setup_helper_script "/usr/local/bin/simulator-stop"

function setup_env_file() {
  chmod 664 "\$1"
  chown dronology:dronology "\$1"
}

setup_env_file "/var/lib/dronology/simulator.env"

systemctl daemon-reload

EOF
chmod 755 "$OUT_DIR/DEBIAN/postinst"

### prerm
cat <<EOF >>"$OUT_DIR/DEBIAN/prerm"
#!/bin/bash
# prerm script for simulation-service

systemctl stop simulator.service

EOF
chmod 755 "$OUT_DIR/DEBIAN/prerm"

### postrm
cat <<EOF >"$OUT_DIR/DEBIAN/postrm"
#!/bin/bash
# postrm script for simulation-service

systemctl daemon-reload
EOF
chmod 755 "$OUT_DIR/DEBIAN/postrm"

dpkg-deb --build "$OUT_DIR"
