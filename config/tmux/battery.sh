#!/usr/bin/env zsh

echo "♥" $(pmset -g batt | grep -Eo '[0-9]+%')
