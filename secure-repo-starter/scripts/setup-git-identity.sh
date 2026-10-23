#!/usr/bin/env bash
# One-time Git identity setup. Works in Git Bash (Windows) and Linux/macOS.
set -euo pipefail
git config --global user.name "Dhananjay Gupta"
git config --global user.email "dhananjaygupta1312@gmail.com"
git config --global init.defaultBranch main
git config --global core.autocrlf input
echo "Git identity set:"
git config --global --get user.name
git config --global --get user.email
