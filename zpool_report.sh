#!/usr/bin/env bash
#
# Send a zpool status summary and detailed report of all pools via Email.

source user.conf && source global.conf

readonly EMAIL_SUBJECT="$(hostname) zpool status report"
readonly EMAIL_CONTENT="/tmp/zpool_report.eml"

# Set Email headers
(
  echo "To: ${EMAIL_ADDRESS}"
  echo "Subject: ${EMAIL_SUBJECT}"
  echo "Content-Type: text/html"
  echo -e "MIME-Version: 1.0\n" # Need a blank line between the headers and the body as per RFC 822.
) > "${EMAIL_CONTENT}"

# Only specify monospace font to let Email client decide of the rest.
echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_CONTENT}"

# Print a summary table of the status of all pools.
(
  echo "<b>ZPool status report summary for all pools:</b>"
  echo "+--------------+--------+------+------+------+----+--------+------+-----+"
  echo "|Pool Name     |Status  |Read  |Write |Cksum |Used|Scrub   |Scrub |Last |"
  echo "|              |        |Errors|Errors|Errors|    |Repaired|Errors|Scrub|"
  echo "|              |        |      |      |      |    |Bytes   |      |Age  |"
  echo "+--------------+--------+------+------+------+----+--------+------+-----+"
) >> "${EMAIL_CONTENT}"
for pool_name in ${ZFS_POOLS}; do
  pool_health="$(zpool list -H -o health "${pool_name}")"
  pool_status="$(zpool status "${pool_name}")"
  pool_used_capacity="$(zpool list -H -p -o capacity "${pool_name}")"
  pool_errors="$(echo "${pool_status}" | grep -E "(ONLINE|DEGRADED|FAULTED|UNAVAIL|REMOVED)[ \t]+[0-9]+")"

  # Count the number of read errors in the pool by counting the numbers in the READ column of the zpool status output.
  read_errors=0
  for error in $(echo "${pool_errors}" | awk '{print $3}'); do
    # Check if only numbers are displayed in the read errors column, zpool status will abbrieviate 1000 with 1K so if
    # there's a K in the column that means there's more than 1000 errors and we don't need to check any further because
    # if a pool gets to this point then knowing if there's 10K or 1K errors doesn't mean much and also because I'm lazy
    # and I don't want to write the code for it.
    if echo "${error}" | grep -Eq "[^0-9]+"; then
      read_errors=1000
      break
    fi
    read_errors=$((read_errors + error))
  done
  if [[ "${read_errors}" -ge 1000 ]]; then
    read_errors=">1K"
  fi
  # Do the same for the write and checksum errors.
  write_errors=0
  for error in $(echo "${pool_errors}" | awk '{print $4}'); do
    if echo "${error}" | grep -Eq "[^0-9]+"; then
      write_errors=1000
      break
    fi
    write_errors=$((write_errors + error))
  done
  if [[ "${write_errors}" -ge 1000 ]]; then
    write_errors=">1K"
  fi
  checksum_errors=0
  for error in $(echo "${pool_errors}" | awk '{print $5}'); do
    if echo "${error}" | grep -Eq "[^0-9]+"; then
      checksum_errors=1000
      break
    fi
    checksum_errors=$((checksum_errors + error))
  done
  if [[ "${checksum_errors}" -ge 1000 ]]; then
    checksum_errors=">1K"
  fi

  scrub_repaired_bytes="N/A"
  scrub_errors="N/A"
  scrub_age="N/A"
  if [[ "$(echo "${pool_status}" | grep "scan" | awk '{print $2}')" == "scrub" ]]; then
    scrub_repaired_bytes="$(echo "${pool_status}" | grep "scan" | awk '{print $4}')"
    scrub_errors="$(echo "${pool_status}" | grep "scan" | awk '{print $10}')"
    scrub_date="$(echo "${pool_status}" | grep "scan" | awk '{print $17"-"$14"-"$15"_"$16}')"
    scrub_timestamp="$(date -j -f "%Y-%b-%e_%H:%M:%S" "${scrub_date}" "+%s")"
    current_timestamp="$(date "+%s")"
    scrub_age=$((((current_timestamp - scrub_timestamp) + 43200) / 86400))
  fi

  # Choose the symbol to display beside the pool name.
  if [[ "${pool_health}" == "FAULTED" ]] ||
    [[ "${pool_used_capacity}" -ge "${ZFS_POOL_CAPACITY_CRITICAL}" ]] ||
    { [[ "${scrub_errors}" != "N/A" ]] && [[ "${scrub_errors}" != "0" ]]; }; then
    ui_symbol="${UI_CRITICAL_SYMBOL}"
  elif [[ "${pool_health}" != "ONLINE" ]] ||
    [[ "${read_errors}" != "0" ]] ||
    [[ "${write_errors}" != "0" ]] ||
    [[ "${checksum_errors}" != "0" ]] ||
    [[ "${pool_used_capacity}" -ge "${ZFS_POOL_CAPACITY_WARNING}" ]] ||
    [[ "${scrub_repaired_bytes}" != "0" ]] ||
    [[ "$(echo "${scrub_age}" | awk '{print int($1)}')" -ge "${SCRUB_AGE_WARNING}" ]]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi

  # Print the row with all the attributes corresponding to the pool.
  printf "|%-12s %1s|%-8s|%6s|%6s|%6s|%3s%%|%8s|%6s|%5s|\n" "${pool_name}" "${ui_symbol}" "${pool_health}" \
    "${read_errors}" "${write_errors}" "${checksum_errors}" "${pool_used_capacity}" "${scrub_repaired_bytes}" "${scrub_errors}" \
    "${scrub_age}" >> "${EMAIL_CONTENT}"
done
echo "+--------------+--------+------+------+------+----+--------+------+-----+" >> "${EMAIL_CONTENT}"

# Print a detailed status report for each pool.
for pool_name in ${ZFS_POOLS}; do
  (
    echo ""
    echo ""
    echo "<b>ZPool status report for ${pool_name}:</b>"
    zpool status -v "${pool_name}"
  ) >> "${EMAIL_CONTENT}"
done

(
  echo ""
  echo "-- End of ZPool status report --"
  echo "</pre>"
) >> "${EMAIL_CONTENT}"

sendmail -i -t < "${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
