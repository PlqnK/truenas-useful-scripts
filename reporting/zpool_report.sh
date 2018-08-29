#!/usr/bin/env bash
#
# Send a zpool status summary and detailed report of all pools via Email.

source ../user.conf && source ../global.conf

readonly EMAIL_SUBJECT="$(hostname) zpool status report"
readonly EMAIL_CONTENT="/tmp/zpool_report.eml"

# Set Email headers
(
  echo "To: ${EMAIL_ADDRESS}"
  echo "Subject: ${EMAIL_SUBJECT}"
  echo "Content-Type: text/html"
  echo -e "MIME-Version: 1.0\n" # Need a blank line between the headers and the body as per RFC 822
) >"${EMAIL_CONTENT}"

# Only specify monospace font to let Email client decide of the rest
echo "<pre style=\"font-family:monospace\">" >>"${EMAIL_CONTENT}"

# Print a summary table of the status of all pools
(
  echo "<b>ZPool status report summary for all pools:</b>"
  echo "+--------------+--------+------+------+------+----+--------+------+-----+"
  echo "|Pool Name     |Status  |Read  |Write |Cksum |Used|Scrub   |Scrub |Last |"
  echo "|              |        |Errors|Errors|Errors|    |Repaired|Errors|Scrub|"
  echo "|              |        |      |      |      |    |Bytes   |      |Age  |"
  echo "+--------------+--------+------+------+------+----+--------+------+-----+"
) >>"${EMAIL_CONTENT}"
for poolName in ${ZFS_POOLS}; do
  # Store the zpool status reports into variables in order to limit the number of use of zpool status & zpool list
  poolHealth="$(zpool list -H -o health "${poolName}")"
  poolStatus="$(zpool status "${poolName}")"
  poolErrors="$(echo "${poolStatus}" | egrep "(ONLINE|DEGRADED|FAULTED|UNAVAIL|REMOVED)[ \t]+[0-9]+")"

  # Count the number of read errors in the pool by counting the numbers in the READ column of the zpool status output
  readErrors=0
  for error in $(echo "${poolErrors}" | awk '{print $3}'); do
    # Check if only numbers are displayed in the read errors column, zpool status will abbrieviate 1000 with 1K so if
    # there's a K in the column that means there's more than 1000 errors and we don't need to check any further because
    # if a pool gets to this point then knowing if there's 10K or 1K errors doesn't mean much and also because I'm lazy
    # and I don't want to write the code for it.
    if echo "${error}" | egrep -q "[^0-9]+"; then
      readErrors=1000
      break
    fi
    readErrors=$((readErrors + error))
  done
  if [[ "${readErrors}" -ge 1000 ]]; then
    readErrors=">1K"
  fi
  # Do the same for the write and checksum errors
  writeErrors=0
  for error in $(echo "${poolErrors}" | awk '{print $4}'); do
    if echo "${error}" | egrep -q "[^0-9]+"; then
      writeErrors=1000
      break
    fi
    writeErrors=$((writeErrors + error))
  done
  if [[ "${writeErrors}" -ge 1000 ]]; then
    writeErrors=">1K"
  fi
  checksumErrors=0
  for error in $(echo "${poolErrors}" | awk '{print $5}'); do
    if echo "${error}" | egrep -q "[^0-9]+"; then
      checksumErrors=1000
      break
    fi
    checksumErrors=$((checksumErrors + error))
  done
  if [[ "${checksumErrors}" -ge 1000 ]]; then
    checksumErrors=">1K"
  fi

  # Grab all the values we need from the zpool status report
  usedCapacity="$(zpool list -H -p -o capacity "${poolName}")"
  scrubRepairedBytes="N/A"
  scrubErrors="N/A"
  scrubAge="N/A"
  if [[ "$(echo "${poolStatus}" | grep "scan" | awk '{print $2}')" = "scrub" ]]; then
    scrubRepairedBytes="$(echo "${poolStatus}" | grep "scan" | awk '{print $4}')"
    scrubErrors="$(echo "${poolStatus}" | grep "scan" | awk '{print $10}')"
    scrubDate="$(echo "${poolStatus}" | grep "scan" | awk '{print $17"-"$14"-"$15"_"$16}')"
    scrubTimestamp="$(date -j -f "%Y-%b-%e_%H:%M:%S" "${scrubDate}" "+%s")"
    currentTimestamp="$(date "+%s")"
    scrubAge=$((((currentTimestamp - scrubTimestamp) + 43200) / 86400))
  fi

  # Choose the symbol to display beside the pool name
  if [[ "${poolHealth}" = "FAULTED" ]] ||
    [[ "${usedCapacity}" -ge "${ZFS_POOL_CAPACITY_CRITICAL}" ]] ||
    ([[ "${scrubErrors}" != "N/A" ]] && [[ "${scrubErrors}" != "0" ]]); then
    uiSymbol="${UI_CRITICAL_SYMBOL}"
  elif [[ "${poolHealth}" != "ONLINE" ]] ||
    [[ "${readErrors}" != "0" ]] ||
    [[ "${writeErrors}" != "0" ]] ||
    [[ "${checksumErrors}" != "0" ]] ||
    [[ "${usedCapacity}" -ge "${ZFS_POOL_CAPACITY_WARNING}" ]] ||
    [[ "${scrubRepairedBytes}" != "0" ]] ||
    [[ "$(echo "${scrubAge}" | awk '{print int($1)}')" -ge "${SCRUB_AGE_WARNING}" ]]; then
    uiSymbol="${UI_WARNING_SYMBOL}"
  else
    uiSymbol=" "
  fi

  # Print the row with all the attributes corresponding to the pool
  printf "|%-12s %1s|%-8s|%6s|%6s|%6s|%3s%%|%8s|%6s|%5s|\n" "${poolName}" "${uiSymbol}" "${poolHealth}" \
    "${readErrors}" "${writeErrors}" "${checksumErrors}" "${usedCapacity}" "${scrubRepairedBytes}" "${scrubErrors}" \
    "${scrubAge}" >>"${EMAIL_CONTENT}"
done
echo "+--------------+--------+------+------+------+----+--------+------+-----+" >>"${EMAIL_CONTENT}"

# Print a detailed status report for each pool
for poolName in ${ZFS_POOLS}; do
  (
    echo ""
    echo ""
    echo "<b>ZPool status report for ${poolName}:</b>"
    zpool status -v "${poolName}"
  ) >>"${EMAIL_CONTENT}"
done

(
  echo ""
  echo "-- End of ZPool status report --"
  echo "</pre>"
) >>"${EMAIL_CONTENT}"

# Send report via Email
sendmail -t <"${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
