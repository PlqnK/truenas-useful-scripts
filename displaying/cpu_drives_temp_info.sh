#!/usr/bin/env bash
#
# Display the temperature of both the CPU cores and the SATA drives.

source ../user.conf && source ../global.conf

# Store the sysctl status report into a variable in order to limit the number of calls to it and speed up the process
sysctlStatus="$(sysctl -a)"
for coreNumber in $(seq 0 "${CPU_CORE_AMOUNT}"); do
  temperature="$(echo "${sysctlStatus}" | grep "cpu.${coreNumber}.temp" | cut -c24-25 | tr -d "\n")"
  printf "Core %s: %s°C\n" "${coreNumber}" "${temperature}"
done

echo ""

for driveLabel in ${SATA_DRIVES}; do
  serialNumber="$(smartctl -i /dev/${driveLabel} | grep "Serial Number" | awk '{print $3}')"
  temperature="$(smartctl -A /dev/${driveLabel} | grep "Temperature_Celsius" | awk '{print $10}')"
  # Some drives don't report their temperature in their SMART
  if [ "${temperature}" = "" ]; then
    printf "%s %-15s: N/A\n" "${driveLabel}" "${serialNumber}"
  else
    printf "%s %-15s: %s°C\n" "${driveLabel}" "${serialNumber}" "${temperature}"
  fi
done
