#!/usr/bin/env bash

echo "♥" "$(pmset -g batt | grep -Eo '[0-9]+%')"
