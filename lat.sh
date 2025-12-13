#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DIR/lib/core.sh"
source "$DIR/lib/distro.sh"
source "$DIR/checks/ssh_checks.sh"
source "$DIR/checks/accounts_checks.sh"
source "$DIR/checks/pwpolicy_checks.sh"
source "$DIR/checks/permissions_checks.sh"

function main() {


	parse_arguments "$@"

	banner

	detect_debian
	detect_init

	if [[ $EUID -ne 0 ]]; then
		log_error "LAT must run with root privelages"
		exit 1
	fi
	
	run_checks

	print_summary
}

function parse_arguments() {
	[[ $# -eq 0 ]] && return
	case "$1" in
		-h|--help)
		  help
		  ;;
		--version)
		  echo "$SCRIPT_VERSION"
		  exit 0
		  ;;
		-c|--category)
		  CATEGORY=()
		  local i
		  for ((i=2; i<=$#; i++)); do
			CATEGORY+=("${!i}")
		  done
		  ;;
		*)
		  log_error "Invalid usage $1. See ./lat.sh --help"
		  exit 1
		  ;;
	esac
}

function run_checks(){
	local i
	for i in "${CATEGORY[@]}"; do
		case $i in
			ssh)
			  check_ssh
			  ;;

			accounts)
			  check_accounts
			  ;;

			pwpolicy)
			  check_pwpolicy
			  ;;

			permissions)
			  check_permissions
			  ;;

			default)
			  check_accounts
			  check_pwpolicy
			  check_ssh
			  check_permissions
			  break
			  ;;

			*)
			  log_error "Unknown category: $i"
			  exit 1
			  ;;
		esac
	done
}

function check_ssh() {
	log_cat "----------"
	log_cat "SSH CONFIG"
	log_cat "----------"
	
	if ssh_config_existance; then
		ssh_config
		ssh_port_check
		ssh_max_auth_tries
		ssh_authorized_keys
	else
		log_info "Skipping SSH category"
	fi
}

function check_accounts() {
	log_cat "--------"
	log_cat "ACCOUNTS"
	log_cat "--------"

	accounts_non_root_uid
	accounts_empty_passwords
	accounts_root_locked
	accounts_duplicate_ids
	accounts_service_interactive_shells
	accounts_sudoers
}

function check_pwpolicy() {
	log_cat "-----------------"
	log_cat "PASSWORD POLICIES"
	log_cat "-----------------"

	pwpolicy_aging
	pwpolicy_history
	pwpolicy_quality
}

function check_permissions() {
	log_cat "----------------"
	log_cat "FILE PERMISSIONS"
	log_cat "----------------"

	permissions_world_writable_files
	permissions_world_writable_dirs
	permissions_suid_files
	permissions_sgid_files
	permissions_critical_files
	permissions_different_home_dirs
}

main "$@"

