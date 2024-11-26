#!/bin/sh

# Test script for setup-mbnix.sh

# Load the setup script
. /home/seb/mbnix/.mbnix/setup_mbnix.sh

# Test warn function
test_warn() {
  output=$(warn "This is a test warning" 2>&1)
  expected_output="\033[33mWarning:\033[0m This is a test warning"
  if [ "$output" = "$expected_output" ]; then
    echo "warn function test passed"
  else
    echo "warn function test failed"
  fi
}

# Test validate_mb_color function
test_validate_mb_color() {
  export MB_COLOR="RED"
  validate_mb_color
  if [ "$MB_COLOR" = "$RED" ]; then
    echo "validate_mb_color function test passed for RED"
  else
    echo "validate_mb_color function test failed for RED"
  fi

  export MB_COLOR="INVALID_COLOR"
  validate_mb_color
  if [ "$MB_COLOR" = "$PINK_BOLD" ]; then
    echo "validate_mb_color function test passed for fallback"
  else
    echo "validate_mb_color function test failed for fallback"
  fi
}

# Test animate_message function
test_animate_message() {
  output=$(animate_message "Test message" 1 "$GREEN_BOLD" 1 0)
  expected_output="\033[01;32mTest message\033[0m"
  if [ "$output" = "$expected_output" ]; then
    echo "animate_message function test passed"
  else
    echo "animate_message function test failed"
  fi
}

# Test oops function
test_oops() {
  output=$(oops "This is a test error" 2>&1)
  expected_output="\033[01;38;5;225mError:\033[0m This is a test error"
  if echo "$output" | grep -q "$expected_output"; then
    echo "oops function test passed"
  else
    echo "oops function test failed"
  fi
}

# Test source_util_post function
test_source_util_post() {
  echo "echo 'Test script sourced'" > /tmp/test_script.sh
  output=$(source_util_post /tmp/test_script.sh 2>&1)
  expected_output="Test script sourced"
  if [ "$output" = "$expected_output" ]; then
    echo "source_util_post function test passed"
  else
    echo "source_util_post function test failed"
  fi
  rm /tmp/test_script.sh
}

# Test mbcmd function
test_mbcmd() {
  output=$(mbcmd help 2>&1)
  if echo "$output" | grep -q "USAGE:"; then
    echo "mbcmd function test passed"
  else
    echo "mbcmd function test failed"
  fi
}

# Test setup_envs function
test_setup_envs() {
  echo "no" | setup_envs
  if [ -z "$MB_SETUP_ENV_VARS" ]; then
    echo "setup_envs function test passed"
  else
    echo "setup_envs function test failed"
  fi
}

# Test reset_envs function
test_reset_envs() {
  export MB_SETUP_ENV_VARS="TEST_VAR"
  export TEST_VAR="test_value"
  reset_envs
  if [ -z "$TEST_VAR" ]; then
    echo "reset_envs function test passed"
  else
    echo "reset_envs function test failed"
  fi
}

# Run tests
test_warn
# test_validate_mb_color
test_animate_message
test_oops
test_source_util_post
test_mbcmd
test_setup_envs
test_reset_envs