#!/usr/bin/env bash
#
# Display the temperature of both the CPU cores and the SATA drives.

source user.conf && source global.conf

# Store the sysctl status report into a variable in order to limit the number of calls to it and speed up the process
sysctl_status="$(sysctl -a)"
for core_number in $(seq 0 "${CPU_CORE_AMOUNT}"); do
  cpu_temperature="$(echo "${sysctl_status}" | grep "cpu.${core_number}.temp" | cut -c24-25 | tr -d "\n")"
  printf "Core %s: %s°C\n" "${core_number}" "${cpu_temperature}"
done

echo ""

for drive_label in ${SATA_DRIVES}; do
  serial_number="$(smartctl -i /dev/"${drive_label}" | grep "Serial Number" | awk '{print $3}')"
  drive_temperature="$(smartctl -A /dev/"${drive_label}" | grep "Temperature_Celsius" | awk '{print $10}')"
  # Some drives don't report their temperature in their SMART
  if [ "${drive_temperature}" = "" ]; then
    printf "%s %-15s: N/A\n" "${drive_label}" "${serial_number}"
  else
    printf "%s %-15s: %s°C\n" "${drive_label}" "${serial_number}" "${drive_temperature}"
  fi
done
