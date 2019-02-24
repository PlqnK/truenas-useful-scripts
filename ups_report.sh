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

  printf "|%-14s|%-6s|%4s|%6s|%7s|%7s|%7s|%7s|%-10s|%-10s|\n" "${ups}" "${status}" "${load}" "${real_power}" \
    "${battery_charge}" "${battery_voltage}" "${battery_temperature}" "${battery_runtime}" "${battery_change_date}" \
    "${last_test_date}" >> "${EMAIL_CONTENT}"
done
echo "+--------------+------+----+------+-------+-------+-------+-------+----------+----------+" >> "${EMAIL_CONTENT}"

# Print a detailed UPS report for each UPS.
for ups in ${UPS_LIST}; do
  model="$(upsc "${ups}" device.model | sed -e 's/[[:space:]]*$//')"
  manufacturer="$(upsc "${ups}" device.mfr)"
  serial_number="$(upsc "${ups}" device.serial)"
  uptime="$(upsc "${ups}" device.uptime)"
  status="$(upsc "${ups}" ups.status)"
  firmware_version="$(upsc "${ups}" ups.firmware)"
  temperature="$(upsc "${ups}" ups.temperature)"
  load="$(upsc "${ups}" ups.load)"
  delay_shutdown="$(upsc "${ups}" ups.delay.shutdown)"
  delay_start="$(upsc "${ups}" ups.delay.start)"
  timer_shutdown="$(upsc "${ups}" ups.timer.shutdown)"
  timer_start="$(upsc "${ups}" ups.timer.start)"
  test_interval="$(upsc "${ups}" ups.test.interval)"
  last_test_result="$(upsc "${ups}" ups.test.result)"
  last_test_date="$(upsc "${ups}" ups.test.date)"
  efficiency="$(upsc "${ups}" ups.efficiency)"
  power="$(upsc "${ups}" ups.power)"
  power_nominal="$(upsc "${ups}" ups.power.nominal)"
  real_power="$(upsc "${ups}" ups.realpower)"
  real_power_nominal="$(upsc "${ups}" ups.realpower.nominal)"
  beeper_status="$(upsc "${ups}" ups.beeper.status)"
  output_voltage="$(upsc "${ups}" output.voltage)"
  output_voltage_nominal="$(upsc "${ups}" output.voltage.nominal)"
  output_current="$(upsc "${ups}" output.current.nominal)"
  output_current_nominal="$(upsc "${ups}" output.current)"
  output_frequency="$(upsc "${ups}" output.frequency)"
  output_frequency_nominal="$(upsc "${ups}" output.frequency.nominal)"
  input_voltage="$(upsc "${ups}" input.voltage)"
  input_current="$(upsc "${ups}" input.current)"
  input_frequency="$(upsc "${ups}" input.frequency)"
  input_power="$(upsc "${ups}" input.power)"
  input_real_power="$(upsc "${ups}" input.realpower)"
  battery_charge="$(upsc "${ups}" battery.charge)"
  battery_voltage="$(upsc "${ups}" battery.voltage)"
  battery_voltage_nominal="$(upsc "${ups}" battery.voltage.nominal)"
  battery_capacity="$(upsc "${ups}" battery.capacity)"
  battery_current="$(upsc "${ups}" battery.current)"
  battery_temperature="$(upsc "${ups}" battery.temperature)"
  battery_runtime="$(upsc "${ups}" battery.runtime)"
  battery_change_date="$(upsc "${ups}" battery.date)"
  battery_manufacturing_date="$(upsc "${ups}" battery.mfr.date)"
  battery_type="$(upsc "${ups}" battery.type)"

  (
    echo ""
    echo ""
    echo "<b>UPS status report for ${ups} UPS (${manufacturer} ${model}: ${serial_number}):</b>"
    if [[ -n "${firmware_version}" ]]; then
      echo "Firmware version: ${firmware_version}"
    fi
    if [[ -n "${battery_change_date}" ]]; then
      echo "Battery Change Date: ${battery_change_date}"
    fi
    if [[ -n "${battery_manufacturing_date}" ]]; then
      echo "Battery Manufacturing Date: ${battery_manufacturing_date}"
    fi
    if [[ -n "${last_test_result}" ]]; then
      echo "Last Self-Test Result: ${last_test_result}"
    fi
    if [[ -n "${last_test_date}" ]]; then
      echo "Last Self-Test Date: ${last_test_date}"
    fi

    echo ""
    if [[ -n "${uptime}" ]]; then
      echo "Uptime: ${uptime} s"
    fi
    echo "Status: ${status}"
    if [[ -n "${temperature}" ]]; then
      echo "Temperature: ${temperature} °C"
    fi
    if [[ -n "${load}" ]]; then
      echo "Load: ${load} %"
    fi
    if [[ -n "${efficiency}" ]]; then
      echo "Efficiency: ${efficiency} %"
    fi

    echo ""
    if [[ -n "${input_voltage}" ]]; then
      echo "Input Voltage: ${input_voltage} V"
    fi
    if [[ -n "${input_current}" ]]; then
      echo "Input Current: ${input_current} A"
    fi
    if [[ -n "${input_frequency}" ]]; then
      echo "Input Frequency: ${input_frequency} Hz"
    fi
    if [[ -n "${input_power}" ]]; then
      echo "Input Apparent Power: ${input_power} VA"
    fi
    if [[ -n "${input_real_power}" ]]; then
      echo "Input Real Power: ${input_real_power} W"
    fi

    echo ""
    if [[ -n "${output_voltage}" ]]; then
      echo "Output Voltage: ${output_voltage} V"
    fi
    if [[ -n "${output_voltage_nominal}" ]]; then
      echo "Output Voltage (nominal): ${output_voltage_nominal} V"
    fi
    if [[ -n "${output_current}" ]]; then
      echo "Output Current: ${output_current} A"
    fi
    if [[ -n "${output_current_nominal}" ]]; then
      echo "Output Current (nominal): ${output_current_nominal} A"
    fi
    if [[ -n "${output_frequency}" ]]; then
      echo "Output Frequency: ${output_frequency} Hz"
    fi
    if [[ -n "${output_frequency_nominal}" ]]; then
      echo "Output Frequency (nominal): ${output_frequency_nominal} Hz"
    fi
    if [[ -n "${power}" ]]; then
      echo "Output Apparent Power: ${power} VA"
    fi
    if [[ -n "${power_nominal}" ]]; then
      echo "Output Apparent Power (nominal): ${power_nominal} VA"
    fi
    if [[ -n "${real_power}" ]]; then
      echo "Output Real Power: ${real_power} W"
    fi
    if [[ -n "${real_power_nominal}" ]]; then
      echo "Output Real Power (nominal): ${real_power_nominal} W"
    fi

    echo ""
    if [[ -n "${battery_charge}" ]]; then
      echo "Battery Charge: ${battery_charge} %"
    fi
    if [[ -n "${battery_voltage}" ]]; then
      echo "Battery Voltage: ${battery_voltage} V"
    fi
    if [[ -n "${battery_voltage_nominal}" ]]; then
      echo "Battery Voltage (nominal): ${battery_voltage_nominal} V"
    fi
    if [[ -n "${battery_current}" ]]; then
      echo "Battery Current: ${battery_current} A"
    fi
    if [[ -n "${battery_capacity}" ]]; then
      echo "Battery Capacity: ${battery_capacity} Ah"
    fi
    if [[ -n "${battery_temperature}" ]]; then
      echo "Battery Temperature: ${battery_temperature} °C"
    fi
    if [[ -n "${battery_runtime}" ]]; then
      echo "Battery Runtime: ${battery_runtime} s"
    fi
    if [[ -n "${battery_type}" ]]; then
      echo "Battery Type: ${battery_type}"
    fi

    echo ""
    if [[ -n "${beeper_status}" ]]; then
      echo "Beeper Status: ${beeper_status}"
    fi
    if [[ -n "${delay_shutdown}" ]]; then
      echo "Shutdown Delay: ${delay_shutdown} s"
    fi
    if [[ -n "${delay_start}" ]]; then
      echo "Start Delay: ${delay_start} s"
    fi
    if [[ -n "${timer_shutdown}" ]]; then
      echo "Shutdown Timer: ${timer_shutdown} s"
    fi
    if [[ -n "${timer_start}" ]]; then
      echo "Start Timer: ${timer_start} s"
    fi
    if [[ -n "${test_interval}" ]]; then
      echo "Self-Test Interval: ${test_interval} s"
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
