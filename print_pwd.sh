#!/bin/sh
cd "$(dirname "$0")" >/dev/null 2>&1 || exit 1
pwd -P
cd - >/dev/null 2>&1 || exit 1