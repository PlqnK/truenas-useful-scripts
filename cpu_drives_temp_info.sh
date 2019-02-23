#!/usr/bin/env bash
#
# Display the temperature of both the CPU cores and the SATA drives.

source user.conf && source global.conf

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
  serial_number="$(smartctl -i /dev/"${drive_label}" | grep "Serial Number" | awk '{print $3}')"
  drive_temperature="$(smartctl -A /dev/"${drive_label}" | grep "Temperature_Celsius" | awk '{print $10}')"
  # Some drives don't report their temperature in their SMART.
  if [[ "${drive_temperature}" == "" ]]; then
    printf "%s %-15s: N/A\n" "${drive_label}" "${serial_number}"
  else
    printf "%s %-15s: %s°C\n" "${drive_label}" "${serial_number}" "${drive_temperature}"
  fi
done
