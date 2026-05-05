#!/usr/bin/env bash
set -Eeuo pipefail

shopt -s inherit_errexit 2>/dev/null || true

declare -g  __INNER_APP_CODE__=0
declare -g  __INNER_APP_ENTRY__="main"

declare -gA __INNER_APP_META__=()

declare -gA __INNER_TEST_MAP__=()
declare -ga __INNER_TEST_LIST__=()

declare -ga __INNER_TRACE_SOURCE__=()
declare -g  __INNER_TRACE_INIT__=0
declare -g  __INNER_TRACE_FILE__=""
declare -g  __INNER_TRACE_DIR__=""
declare -g  __INNER_TRACE_FIFO__=""
declare -g  __INNER_TRACE_PID__=""
