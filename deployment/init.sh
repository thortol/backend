#!/bin/bash

# This script is intended to work with an EC2 Ubuntu instance, but will likely work with any Linux server running
# systemd. This is also used in the deployment guide.
#
# Note that, for the Terraform deployment, some actions are done by cloud-init (see cloud-config)

set -euxo pipefail

BASEDIR=/opt/cadet
PKGURL='https://github.com/source-academy/cadet/releases/download/latest-stable/cadet-0.0.1.tar.gz'
PKGPATH='/run/cadet-init/cadet-0.0.1.tar.gz'
SVCURL='https://raw.githubusercontent.com/source-academy/cadet/stable/deployment/cadet.service'
SVCPATH='/etc/systemd/system/cadet.service'

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

curl -L "$SVCURL" > "$SVCPATH"
systemctl daemon-reload

mkdir -p "$(dirname "$PKGPATH")"
rm -f "$PKGPATH"
curl -L "$PKGURL" > "$PKGPATH"
# FIXME add some checksumming

systemctl stop cadet
rm -rf "$BASEDIR"
mkdir -p "$BASEDIR"
tar -zxf "$PKGPATH" -C "$BASEDIR" --no-same-owner
mkdir -p "$BASEDIR/tmp"
chmod 1777 "$BASEDIR"/{tmp,lib/tzdata-*/priv/tmp_downloads}
chmod a+x "$BASEDIR"/{bin/cadet,erts-*/bin/*,releases/*/{iex,elixir}}
chown -R nobody:nogroup "$BASEDIR"/lib/tzdata-*/priv/{release_ets,latest_remote_poll.txt}
"$BASEDIR/bin/cadet" eval Cadet.Release.migrate
systemctl start cadet
