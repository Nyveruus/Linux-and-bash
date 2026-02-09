function detect_debian() {
	if [[ ! -e /etc/debian_version ]]; then
		log_error "LAT is intended for Debian-based distros. May not work as intended"
	fi

	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		DISTRO="$PRETTY_NAME"
		log_info "Detected distro: $DISTRO" log
	fi
	
	return 0
}

function detect_init() {
	if command -v systemctl &> /dev/null; then
		INIT_SYSTEM="systemd"
		log_info "Detected system/service manager: $INIT_SYSTEM"
		return 0
	else
		log_error "LAT must be used with systemd devices"
		exit 1
	fi 
}
