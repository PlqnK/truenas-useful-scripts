#!/usr/bin/env bash
#
# Send a UPS status summary via Email.

readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=user.example.conf
source "${SCRIPT_PATH}/user.conf"
# shellcheck source=global.conf
source "${SCRIPT_PATH}/global.conf"
# shellcheck source=format_email.sh
source "${SCRIPT_PATH}/format_email.sh"

readonly EMAIL_SUBJECT="FreeNAS $(hostname): UPS status report"
readonly EMAIL_BODY="/tmp/ups_report.html"

# Only specify monospace font to let Email client decide of the rest.
echo "<pre style=\"font-family:monospace\">" > "${EMAIL_BODY}"

# Print a summary table of the status of all UPS.
(
  echo "<b>UPS status report summary for all UPS:</b>"
  echo "+--------------+------+-----+------+-------+-------+-------+-------+----------+----------+"
  echo "|Device        |Status|Load |Real  |Battery|Battery|Battery|Battery|Battery   |Last      |"
  echo "|              |      |     |Power |Charge |Voltage|Temp   |Runtime|Change    |Test      |"
  echo "|              |      |     |Output|       |       |       |       |Date      |Date      |"
  echo "+--------------+------+-----+------+-------+-------+-------+-------+----------+----------+"
) >> "${EMAIL_BODY}"
for ups in ${UPS_LIST}; do
  upsc="upsc ${ups}"

  # Here I can't use someting like real_power="$(upsc "${ups}" ups.realpower)"; real_power="${real_power:-N/A}" because
  # if I want to display units in the table row (with printf |%3s W| for example) I will end up with "N/A W" if the
  # 'realpower' variable isn't supported by the UPS.
  if [[ -n "$(${upsc} ups.status 2>/dev/null)" ]]; then
    status="$(${upsc} ups.status)"
  else
    status="N/A"
  fi
  if [[ -n "$(${upsc} ups.load 2>/dev/null)" ]]; then
    load="$(${upsc} ups.load) %"
  else
    load="N/A"
  fi
  if [[ -n "$(${upsc} ups.realpower 2>/dev/null)" ]]; then
    real_power="$(${upsc} ups.realpower) W"
  else
    real_power="N/A"
  fi
  if [[ -n "$(${upsc} battery.charge 2>/dev/null)" ]]; then
    battery_charge="$(${upsc} battery.charge) %"
  else
    battery_charge="N/A"
  fi
  if [[ -n "$(${upsc} battery.voltage 2>/dev/null)" ]]; then
    battery_voltage="$(${upsc} battery.voltage) V"
  else
    battery_voltage="N/A"
  fi
  if [[ -n "$(${upsc} battery.temperature 2>/dev/null)" ]]; then
    battery_temperature="$(${upsc} battery.temperature) °C"
  else
    battery_temperature="N/A"
  fi
  if [[ -n "$(${upsc} battery.runtime 2>/dev/null)" ]]; then
    battery_runtime="$(${upsc} battery.runtime) s"
  else
    battery_runtime="N/A"
  fi
  if [[ -n "$(${upsc} battery.date 2>/dev/null)" ]]; then
    battery_change_date="$(${upsc} battery.date)"
  else
    battery_change_date="N/A"
  fi
  if [[ -n "$(${upsc} ups.test.date 2>/dev/null)" ]]; then
    last_test_date="$(${upsc} ups.test.date)"
  else
    last_test_date="N/A"
  fi

  printf "|%-14s|%6s|%5s|%6s|%7s|%7s|%7s|%7s|%10s|%10s|\n" "${ups}" "${status}" "${load}" "${real_power}" \
    "${battery_charge}" "${battery_voltage}" "${battery_temperature}" "${battery_runtime}" "${battery_change_date}" \
    "${last_test_date}" >> "${EMAIL_BODY}"
done
echo "+--------------+------+-----+------+-------+-------+-------+-------+----------+----------+" >> "${EMAIL_BODY}"

# Print a detailed UPS report for each UPS.
for ups in ${UPS_LIST}; do
  upsc="upsc ${ups}"
  (
    echo ""
    echo ""
    echo "<b>UPS status report for ${ups} UPS ($(${upsc} device.mfr 2>/dev/null) $(${upsc} device.model 2>/dev/null | sed -e 's/[[:space:]]*$//'): $(${upsc} device.serial 2>/dev/null)):</b>"
    if [[ -n "$(${upsc} ups.firmware 2>/dev/null)" ]]; then
      echo "Firmware version: $(${upsc} ups.firmware)"
    fi
    if [[ -n "$(${upsc} battery.date 2>/dev/null)" ]]; then
      echo "Battery Change Date: $(${upsc} battery.date)"
    fi
    if [[ -n "$(${upsc} battery.mfr.date 2>/dev/null)" ]]; then
      echo "Battery Manufacturing Date: $(${upsc} battery.mfr.date)"
    fi
    if [[ -n "$(${upsc} ups.test.result 2>/dev/null)" ]]; then
      echo "Last Self-Test Result: $(${upsc} ups.test.result)"
    fi
    if [[ -n "$(${upsc} ups.test.date 2>/dev/null)" ]]; then
      echo "Last Self-Test Date: $(${upsc} ups.test.date)"
    fi
    echo ""
    if [[ -n "$(${upsc} device.uptime 2>/dev/null)" ]]; then
      echo "Uptime: $(${upsc} device.uptime) s"
    fi
    if [[ -n "$(${upsc} ups.status 2>/dev/null)" ]]; then
      echo "Status: $(${upsc} ups.status)"
    fi
    if [[ -n "$(${upsc} ups.temperature 2>/dev/null)" ]]; then
      echo "Temperature: $(${upsc} ups.temperature) °C"
    fi
    if [[ -n "$(${upsc} ups.load 2>/dev/null)" ]]; then
      echo "Load: $(${upsc} ups.load) %"
    fi
    if [[ -n "$(${upsc} ups.efficiency 2>/dev/null)" ]]; then
      echo "Efficiency: $(${upsc} ups.efficiency) %"
    fi
    echo ""
    if [[ -n "$(${upsc} input.voltage 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} input.voltage.nominal 2>/dev/null)" ]]; then
        echo "Input Voltage: $(${upsc} input.voltage) V ($(${upsc} input.voltage.nominal) V nominal)"
      else
        echo "Input Voltage: $(${upsc} input.voltage) V"
      fi
    fi
    if [[ -n "$(${upsc} input.current 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} input.current.nominal 2>/dev/null)" ]]; then
        echo "Input Current: $(${upsc} input.current) A ($(${upsc} input.current.nominal) A nominal)"
      else
        echo "Input Current: $(${upsc} input.current) A"
      fi
    fi
    if [[ -n "$(${upsc} input.frequency 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} input.frequency.nominal 2>/dev/null)" ]]; then
        echo "Input Frequency: $(${upsc} input.frequency) Hz ($(${upsc} input.frequency.nominal) Hz nominal)"
      else
        echo "Input Frequency: $(${upsc} input.frequency) Hz"
      fi
    fi
    if [[ -n "$(${upsc} input.power 2>/dev/null)" ]]; then
      echo "Input Apparent Power: $(${upsc} input.power) VA"
    fi
    if [[ -n "$(${upsc} input.realpower 2>/dev/null)" ]]; then
      echo "Input Real Power: $(${upsc} input.realpower) W"
    fi
    echo ""
    if [[ -n "$(${upsc} output.voltage 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} output.voltage.nominal 2>/dev/null)" ]]; then
        echo "Output Voltage: $(${upsc} output.voltage) V ($(${upsc} output.voltage.nominal) V nominal)"
      else
        echo "Output Voltage: $(${upsc} output.voltage) V"
      fi
    fi
    if [[ -n "$(${upsc} output.current 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} output.current.nominal 2>/dev/null)" ]]; then
        echo "Output Current: $(${upsc} output.current) A ($(${upsc} output.current.nominal) A nominal)"
      else
        echo "Output Current: $(${upsc} output.current) A"
      fi
    fi
    if [[ -n "$(${upsc} output.frequency 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} output.frequency.nominal 2>/dev/null)" ]]; then
        echo "Output Frequency: $(${upsc} output.frequency) Hz ($(${upsc} output.frequency.nominal) Hz nominal)"
      else
        echo "Output Frequency: $(${upsc} output.frequency) Hz"
      fi
    fi
    if [[ -n "$(${upsc} ups.power 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} ups.power.nominal 2>/dev/null)" ]]; then
        echo "Output Apparent Power: $(${upsc} ups.power) VA ($(${upsc} ups.power.nominal) VA nominal)"
      else
        echo "Output Apparent Power: $(${upsc} ups.power) VA"
      fi
    fi
    if [[ -n "$(${upsc} ups.realpower 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} ups.realpower.nominal 2>/dev/null)" ]]; then
        echo "Output Real Power: $(${upsc} ups.realpower) W ($(${upsc} ups.realpower.nominal) W nominal)"
      else
        echo "Output Real Power: $(${upsc} ups.realpower) W"
      fi
    fi
    echo ""
    if [[ -n "$(${upsc} battery.charge 2>/dev/null)" ]]; then
      echo "Battery Charge: $(${upsc} battery.charge) %"
    fi
    if [[ -n "$(${upsc} battery.voltage 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} battery.voltage.nominal 2>/dev/null)" ]]; then
        echo "Battery Voltage: $(${upsc} battery.voltage) V ($(${upsc} battery.voltage.nominal) V nominal)"
      else
        echo "Battery Voltage: $(${upsc} battery.voltage) V"
      fi
    fi
    if [[ -n "$(${upsc} battery.current 2>/dev/null)" ]]; then
      echo "Battery Current: $(${upsc} battery.current) A"
    fi
    if [[ -n "$(${upsc} battery.capacity 2>/dev/null)" ]]; then
      echo "Battery Capacity: $(${upsc} battery.capacity) Ah"
    fi
    if [[ -n "$(${upsc} battery.temperature 2>/dev/null)" ]]; then
      echo "Battery Temperature: $(${upsc} battery.temperature) °C"
    fi
    if [[ -n "$(${upsc} battery.runtime 2>/dev/null)" ]]; then
      echo "Battery Runtime: $(${upsc} battery.runtime) s"
    fi
    if [[ -n "$(${upsc} battery.type 2>/dev/null)" ]]; then
      echo "Battery Type: $(${upsc} battery.type)"
    fi
    echo ""
    if [[ -n "$(${upsc} ups.beeper.status 2>/dev/null)" ]]; then
      echo "Beeper Status: $(${upsc} ups.beeper.status)"
    fi
    if [[ -n "$(${upsc} ups.watchdog.status 2>/dev/null)" ]]; then
      echo "Watchdog Status: $(${upsc} ups.watchdog.status)"
    fi
    if [[ -n "$(${upsc} ups.delay.shutdown 2>/dev/null)" ]]; then
      echo "Shutdown Delay: $(${upsc} ups.delay.shutdown) s"
    fi
    if [[ -n "$(${upsc} ups.delay.reboot 2>/dev/null)" ]]; then
      echo "Reboot Delay: $(${upsc} ups.delay.reboot) s"
    fi
    if [[ -n "$(${upsc} ups.delay.start 2>/dev/null)" ]]; then
      echo "Start Delay: $(${upsc} ups.delay.start) s"
    fi
    if [[ -n "$(${upsc} ups.timer.shutdown 2>/dev/null)" ]]; then
      echo "Shutdown Timer: $(${upsc} ups.timer.shutdown) s"
    fi
    if [[ -n "$(${upsc} ups.timer.reboot 2>/dev/null)" ]]; then
      echo "Reboot Timer: $(${upsc} ups.timer.reboot) s"
    fi
    if [[ -n "$(${upsc} ups.timer.start 2>/dev/null)" ]]; then
      echo "Start Timer: $(${upsc} ups.timer.start) s"
    fi
    if [[ -n "$(${upsc} ups.start.auto 2>/dev/null)" ]]; then
      echo "Auto Start: $(${upsc} ups.start.auto)"
    fi
    if [[ -n "$(${upsc} ups.start.battery 2>/dev/null)" ]]; then
      echo "Start From Battery: $(${upsc} ups.start.battery)"
    fi
    if [[ -n "$(${upsc} ups.start.reboot 2>/dev/null)" ]]; then
      echo "Cold Start From Battery: $(${upsc} ups.start.reboot)"
    fi
    if [[ -n "$(${upsc} ups.shutdown 2>/dev/null)" ]]; then
      echo "Shutdown Ability: $(${upsc} ups.shutdown)"
    fi
    if [[ -n "$(${upsc} ups.test.interval 2>/dev/null)" ]]; then
      echo "Self-Test Interval: $(${upsc} ups.test.interval) s"
    fi
  ) >> "${EMAIL_BODY}"
done

(
  echo ""
  echo "-- End of UPS status report --"
  echo "</pre>"
) >> "${EMAIL_BODY}"

format_email "${EMAIL_SUBJECT}" "${EMAIL_ADDRESS}" "${EMAIL_BODY}" | sendmail -i -t
rm "${EMAIL_BODY}"
