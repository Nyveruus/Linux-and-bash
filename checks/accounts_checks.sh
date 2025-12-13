USERS="/etc/passwd"
SHADOW="/etc/shadow"
GROUP="/etc/group"

function accounts_non_root_uid() {
    log_info "Files: $USERS, $SHADOW, $GROUP"
    local uid_zero="$(awk -F: '$3 == 0 && $1 != "root" {print $1}' $USERS)"

    if [[ -n "$uid_zero" ]]; then
        ((CRITICAL_COUNT++))
        log_warn "Non root users with UID 0: $uid_zero" log C
    else
        log_pass "Only root has UID 0" log
    fi
}

function accounts_empty_passwords() {
    local empty_password_users="$(awk -F: '$2 == "" {print $1}' $SHADOW)"

    if [[ -n "$empty_password_users" ]]; then
        ((CRITICAL_COUNT++))
        log_warn "Users with empty passwords: $empty_password_users" log C
    else
        log_pass "No users with empty passwords" log
    fi
}

function accounts_root_locked() {
    local check="$(awk -F: '($2 == "!" || $2 == "*") && $1 == "root" {print $1}' $SHADOW)"

    if [[ -n "$check" ]]; then
        log_pass "Root is locked" log
    else
        log_warn "Root is not locked" log C
        ((CRITICAL_COUNT++))
    fi
}

function accounts_duplicate_ids() {
    local duplicate_uids="$(awk -F: '{print $3}' "$USERS" | sort | uniq -d)"
    if [[ -n "$duplicate_uids" ]]; then
        log_warn "Duplicate UIDs: $duplicate_uids" log M
        ((MEDIUM_COUNT++))

        local uid
        for uid in $duplicate_uids; do
            local user="$(awk -F: -v uid="$uid" '$3 == uid {print $1}' "$USERS" | tr "\n" " ")"
            log_info "  $uid used by $user" log
        done
    else
        log_pass "No duplicate UIDs found" log
    fi

    local duplicate_gids="$(awk -F: '{print $3}' "$GROUP" | sort | uniq -d)"

    if [[ -n "$duplicate_gids" ]]; then
        log_warn "Duplicate GIDs: $duplicate_gids" log M
        ((MEDIUM_COUNT++))

        local gid
        for gid in $duplicate_gids; do
            local group="$(awk -F: -v gid="$gid" '$3 == gid {print $1}' "$GROUP" | tr "\n" " ")"
            log_warn "  $gid used by $group" log M
            ((MEDIUM_COUNT++))
        done
    else
        log_pass "No duplicate GIDs found" log
    fi
}

function accounts_service_interactive_shells() {
    local accounts="$(awk -F: '($3 < 1000 && $3 != 0 || $3 > 1100) && ($7 !~ /.*nologin$/ && $7 !~ /.*false$/ && $7 !~ /.*sync/) {print $1}' $USERS | tr "\n" " ")"

    if [[ -n "$accounts" ]]; then
        log_warn "Service accounts with interactive shells: ${accounts}" log L
        ((LOW_COUNT++))
    else
        log_pass "No service accounts found with interactive shells" log
    fi
}

function accounts_sudoers() {
    local sudoers=$(cat $GROUP | grep "sudo" | cut -d: -f4)
    local wheel=$(cat $GROUP | grep "wheel" | cut -d: -f4)
    if [[ -n "$wheel" ]]; then
        if [[ -n "$sudoers" ]]; then
            log_info "Members of sudo: $sudoers" log
        fi
        log_info "Members of wheel: $wheel" log
    else
        log_info "Members of sudo: $sudoers" log
    fi
}


