SSH_CONFIG_FILE="/etc/ssh/sshd_config"

function ssh_config_existance() {
	if [[ ! -e "$SSH_CONFIG_FILE" ]]; then
		log_error "Could not find ssh config file $SSH_CONFIG_FILE" log
		((ERROR_COUNT++))
		return 1
	fi
	log_info "SSH config file: $SSH_CONFIG_FILE" log
	return 0
}

function ssh_config() {
	
	local settings=(PermitRootLogin PasswordAuthentication PermitEmptyPasswords X11Forwarding)
	
	local results=()
	local setting
	for setting in "${settings[@]}"; do
		local result=$(cat $SSH_CONFIG_FILE | grep $setting | head -n 1 | awk '{print $2}')
		results+=("$result")
	done
	
	local i
	for ((i=0; i<"${#settings[@]}"; i++)); do

		if [[ "${results[$i]}" == yes ]]; then
			if [[ "${settings[$i]}" == "PermitRootLogin" || "${settings[$i]}" == "PasswordAuthentication" ]]; then
				log_warn "${settings[$i]} is set to yes" log C
				((CRITICAL_COUNT++))
			else
				log_warn "${settings[$i]} is set to yes" log M
				((MEDIUM_COUNT++))
			fi
		else
			log_pass "${settings[$i]} is set to no" log
		fi
	done
	
}

function ssh_port_check() {
	local port_check=$(cat $SSH_CONFIG_FILE | grep "Port" | head -n 1 | awk '{print $2}')
		if [[ ! "$port_check" =~ [0-65535] ]]; then
			log_error "Invalid port"
			((ERROR_COUNT++))
			return 1
		fi

    	if [[ $port_check -eq 22 ]]; then
        	log_warn "Default SSH port 22 is being used" log M
        	((MEDIUM_COUNT++))
		else
			log_pass "Default SSH port 22 is not being used" log
    	fi
}

function ssh_max_auth_tries() {
    	local max_auth=$(cat $SSH_CONFIG_FILE | grep "MaxAuthTries" | head -n 1 | awk '{print $2}')
    
    	if [[ $max_auth -gt 4 ]]; then
        	log_warn "Maximum authentication tries is greater than 4" log L
        	((LOW_COUNT++))
		else
			log_pass "Max authentication tries is lower than 4" log
    	fi

    	local max_sessions
    	max_sessions=$(cat $SSH_CONFIG_FILE | grep "MaxSessions" | head -n 1 | awk '{print $2}')
    
    	if [[ $max_sessions -gt 5 ]]; then
        	log_warn "Maximum sessions is greater than 5" log L
        	((LOW_COUNT++))
		else
			log_pass "Maximum sessions is bellow 5" log
    	fi
}

function ssh_authorized_keys() {
	#local file="/home/$SUDO_USER/.ssh/authorized_keys"
	local user
	for user in /home/*; do
		local file="$user/.ssh/authorized_keys"
		if [[ -f "$file" ]]; then
			local permissions=$(stat -c "%a" "$file")
			if [[ ! $permissions =~ ^[4-7]00$ ]]; then
				log_warn "Insecure ssh key file permissions: $permissions in $file" log C
				((CRITICAL_COUNT++))
			else
				log_pass "Secure ssh key file permissions in $file" log
			fi
		else
			log_info "/home/$i/.ssh/authorized_keys file not found" log
		fi
	done
}
