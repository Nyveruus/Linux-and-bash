# LAT - LINUX AUDITING TOOL

## Description:

LAT is a CLI auditing and hardening tool, exclusively written in Bash designed for Debian-based Linux distributions. It is tested on Debian.

The goal of LAT is to audit the security of your system, based on the findings of several "check" functions of four categories: accounts, password quality and aging policies, ssh config, and important permissions.

For every check function a warning (or several warnings) can be outputted depending on the nature of the check. If the check is succesful - that is, it doesn't find anything wrong - it outputs "pass". 
In some cases it may output "info" for more ambiguous checks that ultimately depend on the intended function of your system, for instance, the number of users part of the sudoers group or the number of SGID files in your system.

Every flaw has three possible severities:

1. Critical - designated for immediate security risks
2. Medium - designated for potential security risks
3. Low - small flaws that relate more to ways to harden your system

And each warning outputted will have a suffix of [C], [M] or [L] respectively to easily interpret the severity of the flaw that the warning is outputting.

./lat.sh by default runs all categories. If the user so desires, they may specify the categories that they specifically want to audit, using the option -c or --category. 

When the audit is finalized, a summary of the findings is outputted, including the total number of critical flaws, medium, flaws, and low flaws; the total number of flaws is also outputted thereafter.

The entire audit is saved as a timestamped .txt file in reports/

## Architecture of the program
### lat.sh

The main script that is executed by the user. It is the backbone of the program, providing all of the necessary infrastructure needed to audit. It is in charge of parsing user arguments, sourcing libraries, and executing all the necessary wrapper functions.

### lib/

lib/ contains the main libraries used by the program

core.sh is where most system constants and variables are defined. It also contains several omnipresent functions for matters such as, logging, printing the banner, printing the summary..., or for neutral purposes like the help function.

distro.sh contains the necessary functions for detecting the system distro and warning the user that the program is designed for Debian-based distros.

### checks/

The meat of the program. This contains all of the "check" functions for the four categories.

1. accounts_checks.sh
2. permissions_checks.sh
3. pwpolicy_checks.sh
4. permissions_checks.sh

### reports/

This is the directory where audits are saved

## USAGE:

Usage: ./lat.sh [options] [arguments]

### Options:

- -h, --help			Show a help message and exit
- -c, --category		Run checks for a specific category, see below
- --version			    Show tool version and exit

### Categories:

- accounts: User account security checks
- pwpolicy: Password policy and aging checks
- ssh: SSH config checks
- permissions: File and important permission checks

Severity levels:

-	Critical		Immediate security risk
-	Medium			Potential security risk
-	Low				Hardening recommendation
	
## CHECK FUNCTIONS
### accounts

- Non-root accounts with root UID
- Users with empty passwords
- Root is not locked
- Duplicate UIDs
- Duplicate GIDs
- Service accounts with interactive login shells
- List members of sudo and/or wheel

### pwpolicy

- Password aging policy is enabled and password aging settings
- Password history is enabled
- Password quality policy is enabled (PAM pwquality) and settings

### ssh

- SSH config file exists (/etc/ssh/sshd_config)
- SSH config settings
- SSH port
- Maximum authentication and max session settings
- Permissions for ~/.ssh/authorized_keys (all home directories)

### permissions

- World writable system files in important sytem directories
- World writable system directories have sticky bit set
- Non-system SUID files
- Info of all SGID files
- Critical system files have expected permissions
- Home directories have expected permissions

## Future additions

- Install and uninstall scripts
- Network category
- Kernel category
- Log category
- Services category
- Package manager and packages category
- More checks for each category
