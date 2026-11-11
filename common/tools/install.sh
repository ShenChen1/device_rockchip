#!/bin/bash -e

[ "$RK_ROOTFS_PREBUILT_TOOLS" ] || exit 0

TARGET_DIR="$1"
[ "$TARGET_DIR" ] || exit 1
OVERLAY_DIR="$(dirname "$(realpath "$0")")"

case "${RK_TOOL_ARCH:-${RK_KERNEL_ARM32:+armhf}}" in
	""|arm64|aarch64) TARGET_ARCH=aarch64 ;;
	arm|armhf) TARGET_ARCH=armhf ;;
	*) echo "Unsupported tool architecture: $RK_TOOL_ARCH" >&2; exit 1 ;;
esac

SOURCES=("$OVERLAY_DIR/$TARGET_ARCH/")
if [ "$RK_ROOTFS_PREBUILT_TOOLS_LIST" ]; then
	SOURCES=()
	set -f
	for TOOL in $RK_ROOTFS_PREBUILT_TOOLS_LIST; do
		if [[ ! "$TOOL" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$ ]] ||
			[ "$TOOL" = adbd ] || [ "$TOOL" = README ]; then
			echo "Invalid prebuilt tool selection: $TOOL" >&2
			exit 1
		fi
		SOURCE="$OVERLAY_DIR/$TARGET_ARCH/$TOOL"
		if [ ! -f "$SOURCE" ] || [ ! -x "$SOURCE" ]; then
			echo "Missing executable prebuilt tool: $SOURCE" >&2
			exit 1
		fi
		SOURCES+=("$SOURCE")
	done
	[ "${#SOURCES[@]}" -gt 0 ] || { echo 'Empty prebuilt tool selection' >&2; exit 1; }
fi

RK_RSYNC="${RK_RSYNC:-rsync -av --chmod=u=rwX,go=rX --copy-unsafe-links --keep-dirlinks --chown=0:0}"
echo "Installing prebuilt tools ($TARGET_ARCH): ${RK_ROOTFS_PREBUILT_TOOLS_LIST:-all}"
DEST_DIR="$TARGET_DIR/usr/bin/"
mkdir -p "$DEST_DIR"
$RK_RSYNC --exclude=adbd --exclude=README "${SOURCES[@]}" "$DEST_DIR/"
