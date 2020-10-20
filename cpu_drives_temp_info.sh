#!/usr/bin/env bash
#
# Display the temperature of both the CPU cores and the SATA drives.

readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=user.example.conf
source "${SCRIPT_PATH}/user.conf"
# shellcheck source=global.conf
source "${SCRIPT_PATH}/global.conf"

for core_number in $(seq 0 "${CPU_CORE_AMOUNT}"); do
  cpu_temperature="$(sysctl -n dev.cpu."${core_number}".temperature | sed 's/\..*$//g')"
  if [[ "${cpu_temperature}" -lt 0 ]]; then
    cpu_temperature="N/A"
  else
    cpu_temperature="${cpu_temperature}°C"
  fi
  printf "Core %s: %s\n" "${core_number}" "${cpu_temperature}"
done

echo ""

for drive_label in ${SATA_DRIVES}; do
  drive_information_attributes="$(smartctl -i -A /dev/"${drive_label}")"
  serial_number="$(echo "${drive_information_attributes}" | grep "Serial Number" | awk '{print $3}')"
  drive_temperature="$(echo "${drive_information_attributes}" | grep "Temperature_Celsius" | awk '{print $10}')" # SATA HDD
  if [[ -z "${drive_temperature}" ]]; then
    drive_temperature="$(echo "${drive_information_attributes}" | grep "Airflow_Temperature_Cel" | awk '{print $10}')" # SATA SSD
    if [[ -z "${drive_temperature}" ]]; then
      drive_temperature="$(echo "${drive_information_attributes}" | grep "Current Drive Temperature" | awk '{print $4}')" # SAS HDD
      if [[ -z "${drive_temperature}" ]]; then
        drive_temperature="N/A" # Some drives don't report their temperature
      fi
    fi
  fi
  if [[ "${drive_temperature}" != "N/A" ]]; then
    drive_temperature="${drive_temperature}°C"
  fi
  printf "%s (%-15s): %s\n" "${drive_label}" "${serial_number}" "${drive_temperature}"
done
