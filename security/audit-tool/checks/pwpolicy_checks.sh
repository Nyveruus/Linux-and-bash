
AGING_FILE="/etc/login.defs"
HISTORY_FILE="/etc/security/opasswd"
PAM_CONFIG_FILE="/etc/pam.d/common-password"
PW_QUALITY_FILE="/etc/security/pwquality.conf"

pwpolicy_aging() {
    log_info "Files: $AGING_FILE $PAM_CONFIG_FILE" log
    local days=$(grep PASS_MAX_DAYS $AGING_FILE | awk 'NR>1 {print $2}')
    local min_days=$(grep PASS_MIN_DAYS $AGING_FILE | awk 'NR>1 {print $2}')

    if [[ "$days" -eq 99999 ]]; then
        log_warn "Password max age is 99999 days, effectively no expiration" log M
        ((MEDIUM_COUNT++))
    elif [[ -z "$days" ]]; then
        log_warn "Password max age is not set" log M
        ((MEDIUM_COUNT++))
    elif [[ "$days" -gt 90 ]]; then
        log_warn "Password max age is less than 90 days" log L
        ((LOW_COUNT++))
    else
        log_pass "Password max age is set to $days days" log
    fi

    if [[ -z "$min_days" || "$min_days" -eq 0 ]]; then
        log_warn "Password minimum age not set" log L
        ((LOW_COUNT++))
    else
        log_pass "Password minimum age is set" log
    fi
}

pwpolicy_history() {
    local enabled=0
    local search=$(grep "remember" $PAM_CONFIG_FILE | awk -F= '{print $2}')
    if [[ -z "$search" || $search -eq 0 ]]; then
        enabled=0
        log_warn "Password history is not enabled" log M
        ((MEDIUM_COUNT++))
    else
        log_pass "Password history is enabled" log
    fi
    if ((enabled)); then
        [[ $search -lt 3 ]] && { log_warn "Password history is less than 3" log L ; ((LOW_COUNT++)) } \
        || log_pass "Password history is more than 3" log
    fi
}
pwpolicy_quality() {
    local search=$(grep pam_pwquality.so $PAM_CONFIG_FILE)
    if [[ -z "$search" ]]; then
        log_warn "PAM password quality is not enabled" log C
        ((CRITICAL_COUNT++))
        return
    else
        log_pass "PAM password quality is enabled" log
    fi

    local settings=(minlen dcredit ucredit lcredit)
    local minimum=(12 -1 -1 -1)

    log_info "Minimum password quality requirements:" log
    local password_complexity_flaw=0
    local i
    for ((i=0; i<${#settings[@]}; i++)); do
        if [[ $i -eq 0 ]]; then
            if [[ "$(grep ${settings[$i]} $PW_QUALITY_FILE | awk '{print $4}')" -lt 12 ]]; then
                log_warn "  minlen is under 12" log M
                ((MEDIUM_COUNT++))
            else
                log_pass "minlen is above 12" log
            fi
        else
            if [[ "$(grep ${settings[$i]} $PW_QUALITY_FILE | awk '{print $4}')" -gt -1 ]]; then
                log_warn "  ${settings[$i]} is greater than -1" log L
                password_complexity_flaw=1
            else
                log_pass "  ${settings[$i]} is below -1" log
            fi
        fi
    done
    ((password_complexity_flaw)) && ((LOW_COUNT++))
}


