#!/bin/bash -e

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"

if ! which python3 >/dev/null 2>&1 && ! which python2 >/dev/null 2>&1; then
	echo -e "\e[35m"
	echo "Python (python3/python2) is missing for U-Boot"
	echo "Please install it:"
	"$RK_SCRIPTS_DIR/install-python2.sh"
	echo -e "\e[0m"
	exit 1
fi
