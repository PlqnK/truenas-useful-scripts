#!/usr/bin/env bash
#
# Send a SMART status summary and detailed report of all SATA drives via Email.

source user.conf && source global.conf

readonly EMAIL_SUBJECT="$(hostname) SMART status report"
readonly EMAIL_CONTENT="/tmp/smart_report.eml"

# Set Email headers
(
  echo "To: ${EMAIL_ADDRESS}"
  echo "Subject: ${EMAIL_SUBJECT}"
  echo "Content-Type: text/html"
  echo -e "MIME-Version: 1.0\n" # Need a blank line between the headers and the body as per RFC 822
) > "${EMAIL_CONTENT}"

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
) >> "${EMAIL_CONTENT}"
for drive_label in ${HARD_DISK_DRIVES}; do
  # Ask smartctl to diplay the Seek_Error_Rate in raw hexadecimal so that we can extract the number of seek errors and
  # total number of seeks afterwards
  drive_status="$(smartctl -A -i -v 7,hex48 /dev/"${drive_label}")"
  drive_tests_list="$(smartctl -l selftest /dev/"${drive_label}")"

  last_test_hours="$(echo "${drive_tests_list}" | grep "# 1" | awk '{print $9}')"
  serial_number="$(echo "${drive_status}" | grep "Serial Number:" | awk '{print $3}')"
  temperature="$(echo "${drive_status}" | grep "Temperature_Celsius" | awk '{print $10}')"
  power_on_hours="$(echo "${drive_status}" | grep "Power_On_Hours" | awk '{print $10}')"
  start_stop_count="$(echo "${drive_status}" | grep "Start_Stop_Count" | awk '{print $10}')"
  spin_retry_count="$(echo "${drive_status}" | grep "Spin_Retry_Count" | awk '{print $10}')"
  realocated_sectors="$(echo "${drive_status}" | grep "Reallocated_Sector" | awk '{print $10}')"
  pending_sectors_count="$(echo "${drive_status}" | grep "Current_Pending_Sector" | awk '{print $10}')"
  uncorrectable_sectors_count="$(echo "${drive_status}" | grep "Offline_Uncorrectable" | awk '{print $10}')"
  udma_crc_errors_count="$(echo "${drive_status}" | grep "UDMA_CRC_Error_Count" | awk '{print $10}')"
  # Using cut to grab the first 4 hex symbols which indicate the actual number of seek errors
  seek_errors="$(echo "${drive_status}" | grep "Seek_Error_Rate" | awk '{print $10}' | cut -c 1-6)"
  # Using cut to grab the last 8 hex symbols which indicate the total number of seeks
  total_seeks="$(echo "${drive_status}" | grep "Seek_Error_Rate" | awk '{print $10}' | cut -c 1-2,7-14)"
  high_fly_writes="$(echo "${drive_status}" | grep "High_Fly_Writes" | awk '{print $10}')"
  command_timeout="$(echo "${drive_status}" | grep "Command_Timeout" | awk '{print $10}')"

  # Force LC_NUMERIC because on certain non en_US systems the decimal separator is a comma and we need a dot
  # printf "%.0f" in order to round the resulting number
  # Bash doesn't "natively" support float numbers so bc is used to have a float result to a division
  test_age="$(LC_NUMERIC="en_US.UTF-8" printf "%.0f\n" "$(bc <<<"scale=6; (${power_on_hours} - ${last_test_hours}) / 24")")"

  # Choose the symbol to display beside the drive name
  if [ "${temperature}" -ge "${DRIVE_TEMPERATURE_CRITICAL}" ] ||
    [ "${realocated_sectors}" -gt "${DRIVE_SECTORS_CRITICAL}" ] ||
    [ "${pending_sectors_count}" -gt "${DRIVE_SECTORS_CRITICAL}" ] ||
    [ "${uncorrectable_sectors_count}" -gt "${DRIVE_SECTORS_CRITICAL}" ]; then
    ui_symbol="${UI_CRITICAL_SYMBOL}"
  elif [ "${temperature}" -ge "${DRIVE_TEMPERATURE_WARNING}" ] ||
    [ "${realocated_sectors}" -gt "0" ] ||
    [ "${pending_sectors_count}" -gt "0" ] ||
    [ "${uncorrectable_sectors_count}" -gt "0" ] ||
    [ "${test_age}" -ge "${SMART_TEST_AGE_WARNING}" ]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi

  # seek_errors and total_seeks are stored as hex values, we need to convert them before comparing and displaying
  seek_errors="$(printf "%d" "${seek_errors}")"
  total_seeks="$(printf "%d" "${total_seeks}")"
  # If there's no seeks at all it means the parameter is not supported by the drive SMART so display "N/A"
  if [ "${total_seeks}" = "0" ]; then
    seek_errors="N/A"
    total_seeks="N/A"
  fi
  # Same for those two parameters
  if [ "${high_fly_writes}" = "" ]; then
    high_fly_writes="N/A"
  fi
  if [ "${command_timeout}" = "" ]; then
    command_timeout="N/A"
  fi

  # Print the row with all the attributes corresponding to the drive
  printf "|%-4s %1s|%-15s| %s |%5s|%5s|%5s|%7s|%7s|%8s|%6s|%6s|%6s|%7s|%4s|\n" "${drive_label}" "${ui_symbol}" \
    "${serial_number}" "${temperature}" "${power_on_hours}" "${start_stop_count}" "${spin_retry_count}" \
    "${realocated_sectors}" "${pending_sectors_count}" "${uncorrectable_sectors_count}" "${udma_crc_errors_count}" \
    "${seek_errors}" "${high_fly_writes}" "${command_timeout}" "${test_age}" >>"${EMAIL_CONTENT}"
done
echo "+------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+------+-------+----+" >> "${EMAIL_CONTENT}"

# Print a detailed SMART report for each drive
for drive_label in ${HARD_DISK_DRIVES}; do
  drive_smart_info="$(smartctl -i /dev/"${drive_label}")"
  brand="$(echo "${drive_smart_info}" | grep "Model Family" | awk '{print $3, $4, $5}')"
  serial_number="$(echo "${drive_smart_info}" | grep "Serial Number" | awk '{print $3}')"
  (
    echo ""
    echo ""
    echo "<b>SMART status report for ${drive_label} drive (${brand}: ${serial_number}):</b>"
    # Dislpay the SMART status table
    smartctl -H -A -l error /dev/"${drive_label}"
    # Display the status of the last selftest
    smartctl -l selftest /dev/"${drive_label}" | grep "# 1 \|Num" | cut -c6-
  ) >> "${EMAIL_CONTENT}"
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
) >> "${EMAIL_CONTENT}"

sendmail -t < "${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
