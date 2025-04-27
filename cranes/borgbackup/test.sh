#!/bin/bash

# Path to the script being tested
SCRIPT_PATH="binary.sh"

# Colors for fancy output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Functions for test display
function header() {
	echo -e "\n${BOLD}${BLUE}===== $1 =====${RESET}\n"
}

function subheader() {
	echo -e "\n${BOLD}${CYAN}--- $1 ---${RESET}\n"
}

function success() {
	echo -e "${GREEN}✓ SUCCESS: $1${RESET}"
}

function failure() {
	echo -e "${RED}✗ FAILED: $1${RESET}"
}

function run_test() {
	local test_name="$1"
	local expected_exit="$2"
	shift 2
	local test_vars=("$@")
	
	subheader "Running test: ${test_name}"
	
	# Display environment variables
	echo -e "${CYAN}Environment variables:${RESET}"
	for var in "${test_vars[@]}"; do
		echo -e "  ${YELLOW}${var}${RESET}"
	done
	
	echo -e "\n${BOLD}Output:${RESET}"
	
	# Run the script with testing flag and specified environment variables
	env TESTING=true "${test_vars[@]}" bash "$SCRIPT_PATH"
	local exit_code=$?
	
	echo ""
	
	# Check if the exit code matches expected value
	if [ $exit_code -eq $expected_exit ]; then
		if [ $expected_exit -eq 0 ]; then
			success "Test passed as expected (exit code: $exit_code)"
			echo -e "Expected: Script should succeed with exit code 0"
			echo -e "Actual: Script succeeded with exit code 0"
		else
			success "Test failed as expected (exit code: $exit_code)"
			echo -e "Expected: Script should fail with non-zero exit code"
			echo -e "Actual: Script failed with exit code $exit_code"
		fi
	else
		if [ $expected_exit -eq 0 ]; then
			failure "Test should have succeeded but failed instead"
			echo -e "Expected: Script should succeed with exit code 0"
			echo -e "Actual: Script failed with exit code $exit_code"
		else
			failure "Test should have failed but succeeded instead"
			echo -e "Expected: Script should fail with non-zero exit code"
			echo -e "Actual: Script succeeded with exit code 0"
		fi
	fi
	
	echo -e "\n${BOLD}${YELLOW}Press Enter to continue...${RESET}"
	read
}

clear
header "BORG BACKUP SCRIPT TESTING SUITE"

# Define test cases as arrays: test_name§environment_variables§expected_exit_code
test_cases=(
	# Test case 1: Basic single repo (should succeed)
	"Basic configuration (single repo)§0§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626262626 ENCRYPTION=none REPO_BASE_LOCATION=/path/to/repo SINGLE_REPO=true DO_COMPACT=true"
	
	# Test case 2: Repo rotation (should succeed)
	"Repository rotation§0§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626262626 ENCRYPTION=none REPO_BASE_LOCATION=/path/to/repo1;/path/to/repo2;/path/to/repo3 SINGLE_REPO=true DO_COMPACT=false"
	
	# Test case 3: Repo rotation with empty entries (should succeed)
	"Repository rotation with empty entries§0§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626262626 ENCRYPTION=none REPO_BASE_LOCATION=;/path/to/repo1;;/path/to/repo2; SINGLE_REPO=true DO_COMPACT=false"
	
	# Test case 4: Multi-repo mode (should succeed)
	"Multi-repo mode§0§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626262626 ENCRYPTION=none REPO_BASE_LOCATION=/path/to/repo SINGLE_REPO=false DO_COMPACT=true"
	
	# Test case 5: Missing required variable (should fail)
	"Missing required variable§1§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume ENCRYPTION=none REPO_BASE_LOCATION=/path/to/repo SINGLE_REPO=true DO_COMPACT=true"
	
	# Test case 6: Empty rotation list (should fail)
	"Empty rotation list§1§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626262626 ENCRYPTION=none REPO_BASE_LOCATION=;;; SINGLE_REPO=true DO_COMPACT=true"
	
	# Test case 7: Different day for rotation (should succeed)
	"Different day for rotation§0§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626349026 ENCRYPTION=none REPO_BASE_LOCATION=/path/to/repo1;/path/to/repo2;/path/to/repo3 SINGLE_REPO=true DO_COMPACT=false"
	
	# Test case 8: Custom prefix (should succeed)
	"Custom prefix§0§SALVAGE_MACHINE_NAME=testmachine SALVAGE_CRANE_NAME=borgbackup SALVAGE_VOLUME_NAME=testvolume SALVAGE_TIDE_TIMESTAMP=1626262626 ENCRYPTION=none REPO_BASE_LOCATION=/path/to/repo SINGLE_REPO=true DO_COMPACT=true CUSTOM_PREFIX=\${SALVAGE_MACHINE_NAME}_\${SALVAGE_VOLUME_NAME}"
)

# Run all test cases
for test_case in "${test_cases[@]}"; do
	IFS='§' read -r test_name expected_exit test_vars <<< "$test_case"
	run_test "$test_name" "$expected_exit" $test_vars
done

header "TESTING COMPLETE"
echo -e "${BOLD}${GREEN}All tests have been executed. Please review the outputs.${RESET}"
