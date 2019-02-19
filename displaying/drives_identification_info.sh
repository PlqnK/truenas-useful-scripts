#!/usr/bin/env bash
#
# Diplay a table containing useful drive identification information.

readonly REPOSITORY_ROOT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
source "${REPOSITORY_ROOT_DIRECTORY}"/user.conf && source "${REPOSITORY_ROOT_DIRECTORY}"/global.conf

echo "+========+============================================+=================+"
echo "| Device | GPTID                                      | Serial          |"
echo "+========+============================================+=================+"

for drive_label in ${SATA_DRIVES}; do
  gptid="$(glabel status -s "${drive_label}p2" | awk '{print $1}')"
  serial_number="$(smartctl -i /dev/${drive_label} | grep "Serial Number" | awk '{print $3}')"
  printf "| %-6s | %-42s | %-15s |\n" "${drive_label}" "${gptid}" "${serial_number}"
  echo "+--------+--------------------------------------------+-----------------+"
done
