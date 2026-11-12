#!/bin/sh
# USB NCM gadget configuration hook.

NCM_INSTANCES=${NCM_INSTANCES:-ncm.usb0}
USB_NCM_IPV4=${USB_NCM_IPV4:-169.254.77.2/16}
USB_NCM_NM_FILE=${USB_NCM_NM_FILE:-/etc/NetworkManager/system-connections/usb-ncm.nmconnection}

usb_ncm_set_attr()
{
	[ -r "$1" ] || return 1
	[ "$(tr -d '\0\n' < "$1")" = "$2" ] || printf '%s\n' "$2" > "$1"
}

usb_post_init_hook()
{
	# Standard composite-device class for the NCM IAD plus ADB interface.
	usb_ncm_set_attr "$USB_GADGET_DIR/bDeviceClass" 0xef || return 1
	usb_ncm_set_attr "$USB_GADGET_DIR/bDeviceSubClass" 0x02 || return 1
	usb_ncm_set_attr "$USB_GADGET_DIR/bDeviceProtocol" 0x01
}

usb_ncm_write_nmconnection()
{
	uuid="$1"
	nm_dir=$(dirname "$USB_NCM_NM_FILE")
	mkdir -p "$nm_dir" || return 1

	if [ -f "$USB_NCM_NM_FILE" ] &&
		grep -qx "uuid=$uuid" "$USB_NCM_NM_FILE" &&
		grep -qx "address1=$USB_NCM_IPV4" "$USB_NCM_NM_FILE"; then
		chmod 0600 "$USB_NCM_NM_FILE" || return 1
		return 0
	fi

	(
		umask 0177
		cat > "$USB_NCM_NM_FILE" <<EOF
[connection]
id=usb-ncm
uuid=$uuid
type=ethernet
autoconnect-priority=100
interface-name=usb0

[ethernet]

[ipv4]
address1=$USB_NCM_IPV4
ignore-auto-dns=true
method=manual
never-default=true

[ipv6]
addr-gen-mode=default
method=disabled

[proxy]
EOF
	) || return 1
	chmod 0600 "$USB_NCM_NM_FILE" || return 1
	if command -v nmcli >/dev/null 2>&1; then
		nmcli connection reload >/dev/null 2>&1 || true
	fi
}

ncm_prepare()
{
	serial=$(cat "$USB_GADGET_STRINGS_DIR/serialnumber") || return 1
	hash=$(printf '%s' "$serial" | sha256sum | cut -c1-32)
	[ "${#hash}" -eq 32 ] || return 1

	suffix=$(printf '%s' "$hash" | cut -c1-8 | sed 's/../&:/g; s/:$//')
	uuid="$(printf '%s' "$hash" | cut -c1-8)-$(printf '%s' "$hash" | cut -c9-12)-4$(printf '%s' "$hash" | cut -c14-16)-a$(printf '%s' "$hash" | cut -c18-20)-$(printf '%s' "$hash" | cut -c21-32)"

	# Locally administered unicast MACs, stable for this board's serial.
	usb_ncm_set_attr dev_addr "02:$suffix:02" || return 1
	usb_ncm_set_attr host_addr "02:$suffix:01" || return 1
	usb_ncm_write_nmconnection "$uuid"
}
