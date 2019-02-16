#!/usr/bin/env bash
#
# Send a SMART status summary and detailed report of all SATA drives via Email.

readonly repoParentDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
source "${repoParentDirectory}"/user.conf && source "${repoParentDirectory}"/global.conf

readonly EMAIL_SUBJECT="$(hostname) SMART status report"
readonly EMAIL_CONTENT="/tmp/smart_report.eml"

# Set Email headers
(
  echo "To: ${EMAIL_ADDRESS}"
  echo "Subject: ${EMAIL_SUBJECT}"
  echo "Content-Type: text/html"
  echo -e "MIME-Version: 1.0\n" # Need a blank line between the headers and the body as per RFC 822
) >"${EMAIL_CONTENT}"

# Only specify monospace font to let Email client decide of the rest
echo "<pre style=\"font-family:monospace\">" >>"${EMAIL_CONTENT}"

# Print a summary table of the status of all drives
(
  echo "<b>SMART status report summary for all drives:</b>"
  echo "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+"
  echo "|Device|Serial         |Temp|Power|Start|Spin |ReAlloc|Current|Offline |UDMA  |Seek  |High  |Command|Last|"
  echo "|      |               |    |On   |Stop |Retry|Sectors|Pending|Uncorrec|CRC   |Errors|Fly   |Timeout|Test|"
  echo "|      |               |    |Hours|Count|Count|       |Sectors|Sectors |Errors|      |Writes|Count  |Age |"
  echo "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+"
) >>"${EMAIL_CONTENT}"
for driveLabel in ${HARD_DISK_DRIVES}; do
  # Store the SMART status report into a variable in order to limit the number of use of smartctl and also asking
  # smartctl to diplay the Seek_Error_Rate in raw hexadecimal so that we can extract the number of seek errors
  # and total number of seeks afterwards
  driveStatus="$(smartctl -A -i -v 7,hex48 /dev/"${driveLabel}")"
  driveTestList="$(smartctl -l selftest /dev/"${driveLabel}")"

  # Grab all the values we need from the SMART status report
  lastTestHours="$(echo "${driveTestList}" | grep "# 1" | awk '{print $9}')"
  serialNumber="$(echo "${driveStatus}" | grep "Serial Number:" | awk '{print $3}')"
  temperature="$(echo "${driveStatus}" | grep "Temperature_Celsius" | awk '{print $10}')"
  powerOnHours="$(echo "${driveStatus}" | grep "Power_On_Hours" | awk '{print $10}')"
  startStopCount="$(echo "${driveStatus}" | grep "Start_Stop_Count" | awk '{print $10}')"
  spinRetryCount="$(echo "${driveStatus}" | grep "Spin_Retry_Count" | awk '{print $10}')"
  realocatedSectors="$(echo "${driveStatus}" | grep "Reallocated_Sector" | awk '{print $10}')"
  pendingSectorsCount="$(echo "${driveStatus}" | grep "Current_Pending_Sector" | awk '{print $10}')"
  uncorrectableSectorsCount="$(echo "${driveStatus}" | grep "Offline_Uncorrectable" | awk '{print $10}')"
  udmaCrcErrorsCount="$(echo "${driveStatus}" | grep "UDMA_CRC_Error_Count" | awk '{print $10}')"
  # Using cut to grab the first 4 hex symbols which indicate the actual number of seek errors
  seekErrors="$(echo "${driveStatus}" | grep "Seek_Error_Rate" | awk '{print $10}' | cut -c 1-6)"
  # Using cut to grab the last 8 hex symbols which indicate the total number of seeks
  totalSeeks="$(echo "${driveStatus}" | grep "Seek_Error_Rate" | awk '{print $10}' | cut -c 1-2,7-14)"
  highFlyWrites="$(echo "${driveStatus}" | grep "High_Fly_Writes" | awk '{print $10}')"
  commandTimeout="$(echo "${driveStatus}" | grep "Command_Timeout" | awk '{print $10}')"

  # Force LC_NUMERIC because on certain non en_US systems the decimal separator is a comma and we need a dot
  # printf "%.0f" in order to round the resulting number
  # Bash doesn't support float numbers so bc is used to have a float result to a division
  testAge="$(LC_NUMERIC="en_US.UTF-8" printf "%.0f\n" "$(bc <<<"scale=6; ("${powerOnHours}" - "${lastTestHours}") / 24")")"

  # Choose the symbol to display beside the drive name
  if [ "${temperature}" -ge "${DRIVE_TEMPERATURE_CRITICAL}" ] ||
    [ "${realocatedSectors}" -gt "${DRIVE_SECTORS_CRITICAL}" ] ||
    [ "${pendingSectorsCount}" -gt "${DRIVE_SECTORS_CRITICAL}" ] ||
    [ "${uncorrectableSectorsCount}" -gt "${DRIVE_SECTORS_CRITICAL}" ]; then
    uiSymbol="${UI_CRITICAL_SYMBOL}"
  elif [ "${temperature}" -ge "${DRIVE_TEMPERATURE_WARNING}" ] ||
    [ "${realocatedSectors}" -gt "0" ] ||
    [ "${pendingSectorsCount}" -gt "0" ] ||
    [ "${uncorrectableSectorsCount}" -gt "0" ] ||
    [ "${testAge}" -ge "${SMART_TEST_AGE_WARNING}" ]; then
    uiSymbol="${UI_WARNING_SYMBOL}"
  else
    uiSymbol=" "
  fi

  # seekErrors and totalSeeks are stored as hex values, we need to convert them before comparing and displaying
  seekErrors="$(printf "%d" "${seekErrors}")"
  totalSeeks="$(printf "%d" "${totalSeeks}")"
  # If there's no seeks at all it means the parameter is not supported by the drive SMART so display "N/A"
  if [ "${totalSeeks}" = "0" ]; then
    seekErrors="N/A"
    totalSeeks="N/A"
  fi
  # Same for those two parameters
  if [ "${highFlyWrites}" = "" ]; then
    highFlyWrites="N/A"
  fi
  if [ "${commandTimeout}" = "" ]; then
    commandTimeout="N/A"
  fi

  # Print the row with all the attributes corresponding to the drive
  printf "|%-4s %1s|%-15s| %s |%5s|%5s|%5s|%7s|%7s|%8s|%6s|%6s|%6s|%7s|%4s|\n" "${driveLabel}" "${uiSymbol}" \
    "${serialNumber}" "${temperature}" "${powerOnHours}" "${startStopCount}" "${spinRetryCount}" \
    "${realocatedSectors}" "${pendingSectorsCount}" "${uncorrectableSectorsCount}" "${udmaCrcErrorsCount}" \
    "${seekErrors}" "${highFlyWrites}" "${commandTimeout}" "${testAge}" >>"${EMAIL_CONTENT}"
done
echo "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+" >>"${EMAIL_CONTENT}"

# Print a detailed SMART report for each drive
for driveLabel in ${HARD_DISK_DRIVES}; do
  # Store the SMART infos into a variable in order to limit the number of calls to smartctl
  driveInfos="$(smartctl -i /dev/"${driveLabel}")"
  brand="$(echo "${driveInfos}" | grep "Model Family" | awk '{print $3, $4, $5}')"
  serialNumber="$(echo "${driveInfos}" | grep "Serial Number" | awk '{print $3}')"
  (
    echo ""
    echo ""
    echo "<b>SMART status report for ${driveLabel} drive (${brand}: ${serialNumber}):</b>"
    # Dislpay the SMART status table
    smartctl -H -A -l error /dev/"${driveLabel}"
    # Display the status of the last selftest
    smartctl -l selftest /dev/"${driveLabel}" | grep "# 1 \|Num" | cut -c6-
  ) >>"${EMAIL_CONTENT}"
done

# Trimming unnecessary information from SMART detailed reports
sed -i '' -e '/smartctl 6.3/d' "${EMAIL_CONTENT}"
sed -i '' -e '/Copyright/d' "${EMAIL_CONTENT}"
sed -i '' -e '/=== START OF READ/d' "${EMAIL_CONTENT}"
sed -i '' -e '/SMART Attributes Data/d' "${EMAIL_CONTENT}"
sed -i '' -e '/Vendor Specific SMART/d' "${EMAIL_CONTENT}"
sed -i '' -e '/SMART Error Log Version/d' "${EMAIL_CONTENT}"

(
  echo ""
  echo "-- End of SMART status report --"
  echo "</pre>"
) >>"${EMAIL_CONTENT}"

# Send report via Email
sendmail -t <"${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
