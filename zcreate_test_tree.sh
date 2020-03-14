#!/bin/bash
#TT:Sat 14 Mar 2020 12:01:47 PM PDT
# Create the base testing tree for zfs send/receive
#

set -e
readonly PROG="${BASH_SOURCE[0]##*/}"
usage() {
	printf "usage: %s [-h] <pool>\n" "${PROG}"
	exit 199
}

(( $# )) || usage
case "$1" in
	-h|--help) usage;;
esac

readonly basePool="$1"
readonly p_zfs='/sbin/zfs'
readonly p_zpool='/sbin/zpool'

for binary in "${p_zfs}" "${p_zpool}"; do
	if [[ ! -x "${binary}" ]]; then
		echo "[FATAL] please update script with full path to '${binary#/sbin/}' binary: (default:${binary})"
		exit 1
	fi
done

if ! $p_zpool list "${basePool}" &>/dev/null; then
	echo "[FATAL] zfs pool does not exist: ${basePool}"
	exit 2
fi

if $p_zfs list -oname "${basePool}/ztest" &>/dev/null; then
	echo "[INFO] destroying: ${basePool}/ztest"
	$p_zfs destroy -r "${basePool}/ztest"
fi

while read -r i; do
	echo "${i}"
	$p_zfs create "${i}"
done <<EOL
${basePool}/ztest
${basePool}/ztest/lxd
${basePool}/ztest/lxd/containers
${basePool}/ztest/lxd/containers/css-demo
${basePool}/ztest/lxd/custom
${basePool}/ztest/lxd/custom-snapshots
${basePool}/ztest/lxd/deleted
${basePool}/ztest/lxd/deleted/containers
${basePool}/ztest/lxd/deleted/images
${basePool}/ztest/lxd/deleted/images/4ebc59ba4949395e3331b85ebb0f0df81ee7528641ad828730814c6f3518287c
${basePool}/ztest/lxd/deleted/images/77866cd160e953f29064754b487e9a6a06e857d1a3882cc7996f6e5c659e3d37
${basePool}/ztest/lxd/deleted/images/d5de42917b8dc1a5b95a6dacfe89ac0f2d9f9e8498852ba05203d2128c6b5c3d
${basePool}/ztest/lxd/images
${basePool}/ztest/lxd/images/8c4e87e53c024e0449003350f0b0626b124b68060b73c0a7ad9547670e00d4b3
${basePool}/ztest/lxd/images/b6103335dd65d2a20ff54411c08fe72807416bd067b9529ab73be6697ca40803
${basePool}/ztest/lxd/images/c102f708e15cc052d2c01728821ce1789016bc37da25bff912fa18eea1062c90
${basePool}/ztest/lxd/images/dc656d94d3175e879a5abfb5b8579325e54b85593fcc992090a46b4225301f8e
${basePool}/ztest/lxd/snapshots
EOL

echo "[INFO] snapshot"
$p_zfs snapshot ${basePool}/ztest/lxd/deleted/images/d5de42917b8dc1a5b95a6dacfe89ac0f2d9f9e8498852ba05203d2128c6b5c3d@readonly
$p_zfs snapshot ${basePool}/ztest/lxd/deleted/images/4ebc59ba4949395e3331b85ebb0f0df81ee7528641ad828730814c6f3518287c@readonly
$p_zfs snapshot ${basePool}/ztest/lxd/deleted/images/77866cd160e953f29064754b487e9a6a06e857d1a3882cc7996f6e5c659e3d37@readonly
echo "[INFO] clone"
$p_zfs clone ${basePool}/ztest/lxd/deleted/images/d5de42917b8dc1a5b95a6dacfe89ac0f2d9f9e8498852ba05203d2128c6b5c3d@readonly		${basePool}/ztest/lxd/containers/alpine
$p_zfs clone ${basePool}/ztest/lxd/deleted/images/4ebc59ba4949395e3331b85ebb0f0df81ee7528641ad828730814c6f3518287c@readonly		${basePool}/ztest/lxd/containers/calc20
$p_zfs clone ${basePool}/ztest/lxd/deleted/images/77866cd160e953f29064754b487e9a6a06e857d1a3882cc7996f6e5c659e3d37@readonly		${basePool}/ztest/lxd/deleted/containers/fe89e83a-936b-49dd-8631-8b72a57951e4
$p_zfs snapshot ${basePool}/ztest/lxd/deleted/containers/fe89e83a-936b-49dd-8631-8b72a57951e4@copy-4e6d38b2-512a-4973-a198-de2da8ccf46d
$p_zfs clone ${basePool}/ztest/lxd/deleted/containers/fe89e83a-936b-49dd-8631-8b72a57951e4@copy-4e6d38b2-512a-4973-a198-de2da8ccf46d	${basePool}/ztest/lxd/containers/daemons_vpn-terra-tek
echo "[INFO] snapshot: send2zscratch"
$p_zfs snapshot -r ${basePool}/ztest@send2zscratch
