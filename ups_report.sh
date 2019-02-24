#!/usr/bin/env bash
#
# Send a UPS status summary via Email.

source user.conf && source global.conf

readonly EMAIL_SUBJECT="$(hostname) UPS status report"
readonly EMAIL_CONTENT="/tmp/ups_report.eml"

(
  echo "To: ${EMAIL_ADDRESS}"
  echo "Subject: ${EMAIL_SUBJECT}"
  echo "Content-Type: text/html"
  echo -e "MIME-Version: 1.0\n" # Need a blank line between the headers and the body as per RFC 822.
  echo "<pre style=\"font-family:monospace\">" # Only specify monospace font to let Email client decide of the rest.
) > "${EMAIL_CONTENT}"

# Print a summary table of the status of all UPS.
(
  echo "<b>UPS status report summary for all UPS:</b>"
  echo "+--------------+------+----+------+-------+-------+-------+-------+----------+----------+"
  echo "|Device        |Status|Load|Real  |Battery|Battery|Battery|Battery|Battery   |Last      |"
  echo "|              |      |    |Power |Charge |Voltage|Temp   |Runtime|Change    |Test      |"
  echo "|              |      |    |Output|       |       |       |       |Date      |Date      |"
  echo "+--------------+------+----+------+-------+-------+-------+-------+----------+----------+"
) >> "${EMAIL_CONTENT}"
for ups in ${UPS_LIST}; do
  status="$(upsc "${ups}" ups.status)"
  status="${status:-N/A}"
  load="$(upsc "${ups}" ups.load)"
  load="${load:-N/A}"
  real_power="$(upsc "${ups}" ups.realpower)"
  real_power="${real_power:-N/A}"
  battery_charge="$(upsc "${ups}" battery.charge)"
  battery_charge="${battery_charge:-N/A}"
  battery_voltage="$(upsc "${ups}" battery.voltage)"
  battery_voltage="${battery_voltage:-N/A}"
  battery_temperature="$(upsc "${ups}" battery.temperature)"
  battery_temperature="${battery_temperature:-N/A}"
  battery_runtime="$(upsc "${ups}" battery.runtime)"
  battery_runtime="${battery_runtime:-N/A}"
  battery_change_date="$(upsc "${ups}" battery.date)"
  battery_change_date="${battery_change_date:-N/A}"
  last_test_date="$(upsc "${ups}" ups.test.date)"
  last_test_date="${last_test_date:-N/A}"

  printf "|%-14s|%6s|%4s|%6s|%7s|%7s|%7s|%7s|%10s|%10s|\n" "${ups}" "${status}" "${load}" "${real_power}" \
    "${battery_charge}" "${battery_voltage}" "${battery_temperature}" "${battery_runtime}" "${battery_change_date}" \
    "${last_test_date}" >> "${EMAIL_CONTENT}"
done
echo "+--------------+------+----+------+-------+-------+-------+-------+----------+----------+" >> "${EMAIL_CONTENT}"

# Print a detailed UPS report for each UPS.
for ups in ${UPS_LIST}; do
  upsc="upsc ${ups}"
  (
    echo ""
    echo ""
    echo "<b>UPS status report for ${ups} UPS ($(${upsc} device.mfr) $(${upsc} device.model | sed -e 's/[[:space:]]*$//'): $(${upsc} device.serial)):</b>"
    if [[ -n "$(${upsc} ups.firmware)" ]]; then
      echo "Firmware version: $(${upsc} ups.firmware)"
    fi
    if [[ -n "$(${upsc} battery.date)" ]]; then
      echo "Battery Change Date: $(${upsc} battery.date)"
    fi
    if [[ -n "$(${upsc} battery.mfr.date)" ]]; then
      echo "Battery Manufacturing Date: $(${upsc} battery.mfr.date)"
    fi
    if [[ -n "$(${upsc} ups.test.result)" ]]; then
      echo "Last Self-Test Result: $(${upsc} ups.test.result)"
    fi
    if [[ -n "$(${upsc} ups.test.date)" ]]; then
      echo "Last Self-Test Date: $(${upsc} ups.test.date)"
    fi
    echo ""
    if [[ -n "$(${upsc} device.uptime)" ]]; then
      echo "Uptime: $(${upsc} device.uptime) s"
    fi
    if [[ -n "$(${upsc} ups.status)" ]]; then
      echo "Status: $(${upsc} ups.status)"
    fi
    if [[ -n "$(${upsc} ups.temperature)" ]]; then
      echo "Temperature: $(${upsc} ups.temperature) °C"
    fi
    if [[ -n "$(${upsc} ups.load)" ]]; then
      echo "Load: $(${upsc} ups.load) %"
    fi
    if [[ -n "$(${upsc} ups.efficiency)" ]]; then
      echo "Efficiency: $(${upsc} ups.efficiency) %"
    fi
    echo ""
    if [[ -n "$(${upsc} input.voltage)" ]]; then
      if [[ -n "$(${upsc} input.voltage.nominal)" ]]; then
        echo "Input Voltage: $(${upsc} input.voltage) V ($(${upsc} input.voltage.nominal) V nominal)"
      else
        echo "Input Voltage: $(${upsc} input.voltage) V"
      fi
    fi
    if [[ -n "$(${upsc} input.current)" ]]; then
      if [[ -n "$(${upsc} input.current.nominal)" ]]; then
        echo "Input Current: $(${upsc} input.current) A ($(${upsc} input.current.nominal) A nominal)"
      else
        echo "Input Current: $(${upsc} input.current) A"
      fi
    fi
    if [[ -n "$(${upsc} input.frequency)" ]]; then
      if [[ -n "$(${upsc} input.frequency.nominal)" ]]; then
        echo "Input Frequency: $(${upsc} input.frequency) Hz ($(${upsc} input.frequency.nominal) Hz nominal)"
      else
        echo "Input Frequency: $(${upsc} input.frequency) Hz"
      fi
    fi
    if [[ -n "$(${upsc} input.power)" ]]; then
      echo "Input Apparent Power: $(${upsc} input.power) VA"
    fi
    if [[ -n "$(${upsc} input.realpower)" ]]; then
      echo "Input Real Power: $(${upsc} input.realpower) W"
    fi
    echo ""
    if [[ -n "$(${upsc} output.voltage)" ]]; then
      if [[ -n "$(${upsc} output.voltage.nominal)" ]]; then
        echo "Output Voltage: $(${upsc} output.voltage) V ($(${upsc} output.voltage.nominal) V nominal)"
      else
        echo "Output Voltage: $(${upsc} output.voltage) V"
      fi
    fi
    if [[ -n "$(${upsc} output.current)" ]]; then
      if [[ -n "$(${upsc} output.current.nominal)" ]]; then
        echo "Output Current: $(${upsc} output.current) A ($(${upsc} output.current.nominal) A nominal)"
      else
        echo "Output Current: $(${upsc} output.current) A"
      fi
    fi
    if [[ -n "$(${upsc} output.frequency)" ]]; then
      if [[ -n "$(${upsc} output.frequency.nominal)" ]]; then
        echo "Output Frequency: $(${upsc} output.frequency) Hz ($(${upsc} output.frequency.nominal) Hz nominal)"
      else
        echo "Output Frequency: $(${upsc} output.frequency) Hz"
      fi
    fi
    if [[ -n "$(${upsc} ups.power)" ]]; then
      if [[ -n "$(${upsc} ups.power.nominal)" ]]; then
        echo "Output Apparent Power: $(${upsc} ups.power) VA ($(${upsc} ups.power.nominal) VA nominal)"
      else
        echo "Output Apparent Power: $(${upsc} ups.power) VA"
      fi
    fi
    if [[ -n "$(${upsc} ups.realpower)" ]]; then
      if [[ -n "$(${upsc} ups.realpower.nominal)" ]]; then
        echo "Output Real Power: $(${upsc} ups.realpower) W ($(${upsc} ups.realpower.nominal) W nominal)"
      else
        echo "Output Real Power: $(${upsc} ups.realpower) W"
      fi
    fi
    echo ""
    if [[ -n "$(${upsc} battery.charge)" ]]; then
      echo "Battery Charge: $(${upsc} battery.charge) %"
    fi
    if [[ -n "$(${upsc} battery.voltage)" ]]; then
      if [[ -n "$(${upsc} battery.voltage.nominal)" ]]; then
        echo "Battery Voltage: $(${upsc} battery.voltage) V ($(${upsc} battery.voltage.nominal) V nominal)"
      else
        echo "Battery Voltage: $(${upsc} battery.voltage) V"
      fi
    fi
    if [[ -n "$(${upsc} battery.current)" ]]; then
      echo "Battery Current: $(${upsc} battery.current) A"
    fi
    if [[ -n "$(${upsc} battery.capacity)" ]]; then
      echo "Battery Capacity: $(${upsc} battery.capacity) Ah"
    fi
    if [[ -n "$(${upsc} battery.temperature)" ]]; then
      echo "Battery Temperature: $(${upsc} battery.temperature) °C"
    fi
    if [[ -n "$(${upsc} battery.runtime)" ]]; then
      echo "Battery Runtime: $(${upsc} battery.runtime) s"
    fi
    if [[ -n "$(${upsc} battery.type)" ]]; then
      echo "Battery Type: $(${upsc} battery.type)"
    fi
    echo ""
    if [[ -n "$(${upsc} ups.beeper.status)" ]]; then
      echo "Beeper Status: $(${upsc} ups.beeper.status)"
    fi
    if [[ -n "$(${upsc} ups.delay.shutdown)" ]]; then
      echo "Shutdown Delay: $(${upsc} ups.delay.shutdown) s"
    fi
    if [[ -n "$(${upsc} ups.delay.start)" ]]; then
      echo "Start Delay: $(${upsc} ups.delay.start) s"
    fi
    if [[ -n "$(${upsc} ups.timer.shutdown)" ]]; then
      echo "Shutdown Timer: $(${upsc} ups.timer.shutdown) s"
    fi
    if [[ -n "$(${upsc} ups.timer.start)" ]]; then
      echo "Start Timer: $("${upsc}" ups.timer.start) s"
    fi
    if [[ -n "$(${upsc} ups.test.interval)" ]]; then
      echo "Self-Test Interval: $(${upsc} ups.test.interval) s"
    fi
  ) >> "${EMAIL_CONTENT}"
done

(
  echo ""
  echo "-- End of UPS status report --"
  echo "</pre>"
) >> "${EMAIL_CONTENT}"

sendmail -t < "${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
