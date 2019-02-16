#!/usr/bin/env bash
#
# Diplay a table containing useful drive identification information.

readonly repoParentDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"c
source "${repoParentDirectory}"/user.conf && source "${repoParentDirectory}"/global.conf

echo "+========+============================================+=================+"
echo "| Device | GPTID                                      | Serial          |"
echo "+========+============================================+=================+"

for driveLabel in ${SATA_DRIVES}; do
  gptid="$(glabel status -s "${driveLabel}p2" | awk '{print $1}')"
  serialNumber="$(smartctl -i /dev/${driveLabel} | grep "Serial Number" | awk '{print $3}')"
  printf "| %-6s | %-42s | %-15s |\n" "${driveLabel}" "${gptid}" "${serialNumber}"
  echo "+--------+--------------------------------------------+-----------------+"
done
