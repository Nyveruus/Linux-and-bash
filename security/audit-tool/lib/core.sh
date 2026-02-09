readonly SCRIPT_NAME="lat"
readonly SCRIPT_VERSION="v1.0.0"

readonly RESET="\033[0m"
readonly BLUE="\033[34m"
readonly RED="\033[31m"
readonly YELLOW="\033[33m"
readonly GREEN="\033[32m"

CRITICAL_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
ERROR_COUNT=0

CATEGORY=("default")

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORTFILE="$DIR/reports/lat_audit_${TIMESTAMP}.txt"

function log_info() {
	sleep 0.07
	if [[ $2 == "log" ]]; then
		echo "[INFO] $1" >> "$REPORTFILE"
		echo -e "${BLUE}[INFO]${RESET} $1"
	else
		echo -e "${BLUE}[INFO]${RESET} $1"
	fi
}

function log_error() {
	sleep 0.1
	if [[ $2 == "log" ]]; then
		echo "[INFO] $1" >> "$REPORTFILE"
		echo -e "${RED}[ERROR]${RESET} $1" >&2
	else
		echo -e "${RED}[ERROR]${RESET} $1"
	fi
}

function log_warn() {
	sleep 0.1
	if [[ $2 == "log" && -z $3 ]]; then
		echo "[WARNING] $1" >> "$REPORTFILE"
		echo -e "${YELLOW}[WARNING]${RESET} $1"
	elif [[ -n $3 ]]; then
		if [[ $3 == C ]]; then
			echo "[WARNING][C] $1" >> "$REPORTFILE"
			echo -e "${YELLOW}[WARNING][C]${RESET} $1"
		elif [[ $3 == M ]]; then
			echo "[WARNING][M] $1" >> "$REPORTFILE"
			echo -e "${YELLOW}[WARNING][M]${RESET} $1"
		else
			echo "[WARNING][L] $1" >> "$REPORTFILE"
			echo -e "${YELLOW}[WARNING][L]${RESET} $1"
		fi
	else
		echo -e "${YELLOW}[WARNING]${RESET} $1"
	fi
}

function log_pass() {
	sleep 0.07
	if [[ $2 == "log" ]]; then
		echo "[PASS] $1" >> "$REPORTFILE"
		echo -e "${GREEN}[PASS]${RESET} $1"
	else
		echo -e "${GREEN}[PASS]${RESET} $1"
	fi
}
function log_cat() {
	echo $1 >> "$REPORTFILE"
	echo $1
}

function help() {
	cat <<EOF
Usage: ./$SCRIPT_NAME [options] [args]

Security and hardening tool for Debian-based Linux distros

Options:
	-h, --help			Show this help message and exit
	-c, --category		Run checks for a specific categogory
	--version			Show tool version and exit

Categories:
  accounts
    User account security checks

  pwpolicy
    Password policy and aging checks

  ssh
    SSH config checks

  permissions
    File and important permission checks

Severity levels:
	Critical		Immediate security risk
	Medium			Potential security risk
	Low				Hardening recommendation
EOF
exit 0	
}

function banner() {
	echo ""
	echo "======================"
	echo "LAT - Linux Audit Tool"
	echo "======================"
	echo ""
}

function print_summary() {
	local total_issues=$((LOW_COUNT + MEDIUM_COUNT + CRITICAL_COUNT))
	: '
	echo ""
	echo "==================="
	echo "   AUDIT SUMMARY   "
	echo "==================="
	echo -e "${RED}Critical:${RESET} $CRITICAL_COUNT"
	echo -e "${YELLOW}Medium:${RESET} $MEDIUM_COUNT"
	echo -e "${GREEN}Low:${RESET} $LOW_COUNT"
	if [[ $total_issues -gt 0 ]]; then
		echo "Total issues: $total_issues"
	else
		echo "No issues found"
	fi
	echo "==================="
	'
	{
	echo ""
	echo "==================="
	echo "   AUDIT SUMMARY   "
	echo "==================="
	echo "Critical: $CRITICAL_COUNT"
	echo "Medium: $MEDIUM_COUNT"
	echo "Low: $LOW_COUNT"
	if [[ $total_issues -gt 0 ]]; then
		echo ""
		echo "Total issues: $total_issues"
	else
		echo "No issues found"
	fi
	echo "==================="
	} | tee -a "$REPORTFILE"
}
