IMPORTANT_DIRS=(/usr/local/sbin /usr/sbin /usr/local/bin /usr/bin /etc /usr/lib /usr/lib64 /usr/lib32 /boot)
IMPORTANT_FILES=(/etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers /etc/ssh/sshd_config)

function permissions_world_writable_files() {
    local found_issue=0

    local path
    for path in "${IMPORTANT_DIRS[@]}"; do
        local writable_files="$(find $path -type f -perm -002 2> /dev/null | head -10)"

        if [[ -n $writable_files ]]; then
            found_issue=1
            log_warn "World-writable files found in: $path" log C
            ((CRITICAL_COUNT++))
            echo "$writable_files" | while read -r line; do
                log_info "  $line" log
            done
        fi
    done

    if ((! found_issue)); then
        log_pass "No world-writable files in important system directories"
    fi
}

function permissions_world_writable_dirs() {
    local bad_dirs="$(find /tmp /var/tmp -type d -perm -002 ! -perm -1000 2>/dev/null)"

    if [[ -n "$bad_dirs" ]]; then
        log_warn "World-writable directories without sticky bit:" log M
        ((MEDIUM_COUNT++))
        echo "$bad_dirs" | while read -r dir; do
            log_info "  $dir" log
        done
    else
        log_pass "World-writable directories have sticky bit set" log
    fi
}

function permissions_suid_files() {
    local search=$(find / -perm -4000 -type f 2>/dev/null)
    local count="$(echo "$search" | wc -l)"

    local found_weird=0
    local normal_suid_files=(
        /usr/bin/passwd
        /usr/bin/chsh
        /usr/bin/chfn
        /usr/bin/sudo
        /usr/bin/su
        /usr/bin/ping
        /usr/bin/mount
        /usr/bin/umount
        /usr/bin/newgrp
        /usr/bin/gpasswd
        /usr/sbin/pppd
        /usr/lib/xorg/Xorg.wrap
        /usr/lib/polkit-1/polkit-agent-helper-1
        /usr/lib/openssh/ssh-keysign
        /usr/lib/dbus-1.0/dbus-daemon-launch-helper
        /usr/bin/ntfs-3g
        /usr/bin/fusermount3
    )

    if [[ $count -gt 0 ]]; then
        log_info "Found $count SUID files" log
        while read -r file; do

            local normal
            local is_known=0

            for normal in "${normal_suid_files[@]}"; do
                if [[ "$file" == "$normal" ]]; then
                    is_known=1
                    break
                fi
            done

            if [[ $is_known -eq 0 ]]; then
                log_warn "  Found non-system SUID file: $file" log M
                found_weird=1
                ((MEDIUM_COUNT++))
            fi

        done <<< "$search"

        if [[ $found_weird -eq 0 ]]; then
            log_pass "All SUID files are standard system files" log
        fi
    else
        log_pass "No SUID files found" log
    fi
}

function permissions_sgid_files() {
    local search=$(find / -perm -2000 -type f 2>/dev/null)
    local count="$(echo "$search" | wc -l)"

     if [[ $count -gt 0 ]]; then
        log_info "Found $count SGID files" log

        echo "$search" | while read -r file; do
                log_info "  $file" log
        done

    else
        log_info "No SGID binaries found" log
    fi
}

function permissions_critical_files() {
    local -A expected_permissions=(
    ["/etc/passwd"]="644"
    ["/etc/shadow"]="640"
    ["/etc/group"]="644"
    ["/etc/gshadow"]="640"
    ["/etc/sudoers"]="440"
    ["/etc/ssh/sshd_config"]="644"
    )

    local file
    for file in "${IMPORTANT_FILES[@]}"; do
        local permissions=$(stat -c %a "$file")
        if [[ "$permissions" != "${expected_permissions[$file]}" ]]; then
            log_warn "$file does not have expected permissions: $permissions" log C
            ((CRITICAL_COUNT++))
        else
            log_pass "$file has expected permissions"
        fi
    done
}

function permissions_different_home_dirs() {
    local file
    for file in /home/*; do
        if [[ -z "$file" ]]; then
            log_info "No home directoris found"
            break
        fi
        local permissions=$(stat -c %a "$file")
        if [[ "$permissions" -ne 700 ]]; then
            log_warning "Home directory $file does not have expected permissions"
            ((LOW_COUNT++))
        else
            log_pass "Home directory $file has expected permissions"
        fi
    done

}


