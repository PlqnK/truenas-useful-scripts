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
  echo "<b>UPS status report:</b>"
  date "+Time: %Y-%m-%d %H:%M:%S"
) > "${EMAIL_CONTENT}"

for ups in ${UPS_LIST}; do
  manufacturer="$(upsc "${ups}" device.mfr)"
  model="$(upsc "${ups}" device.model)"
  serial_number="$(upsc "${ups}" device.serial)"
  firmware_version="$(upsc "${ups}" ups.firmware)"
  status="$(upsc "${ups}" ups.status)"
  load="$(upsc "${ups}" ups.load)"
  uptime="$(upsc "${ups}" device.uptime)"
  temperature="$(upsc "${ups}" ups.temperature)"
  beeper_status="$(upsc "${ups}" ups.beeper.status)"
  timer_shutdown="$(upsc "${ups}" ups.timer.shutdown)"
  timer_start="$(upsc "${ups}" ups.timer.start)"
  delay_shutdown="$(upsc "${ups}" ups.delay.shutdown)"
  delay_start="$(upsc "${ups}" ups.delay.start)"
  test_interval="$(upsc "${ups}" ups.test.interval)"
  last_test_result="$(upsc "${ups}" ups.test.result)"
  last_test_date="$(upsc "${ups}" ups.test.date)"
  power="$(upsc "${ups}" ups.power)"
  power_nominal="$(upsc "${ups}" ups.power.nominal)"
  real_power="$(upsc "${ups}" ups.realpower)"
  real_power_nominal="$(upsc "${ups}" ups.realpower.nominal)"
  efficiency="$(upsc "${ups}" ups.efficiency)"
  output_frequency="$(upsc "${ups}" output.frequency)"
  output_frequency_nominal="$(upsc "${ups}" output.frequency.nominal)"
  output_voltage="$(upsc "${ups}" output.voltage)"
  output_volatage_nominal="$(upsc "${ups}" output.voltage.nominal)"
  output_current="$(upsc "${ups}" output.current.nominal)"
  output_current_nominal="$(upsc "${ups}" output.current)"
  input_frequency="$(upsc "${ups}" input.frequency)"
  input_voltage="$(upsc "${ups}" input.voltage)"
  input_current="$(upsc "${ups}" input.current)"
  input_power="$(upsc "${ups}" input.power)"
  input_real_power="$(upsc "${ups}" input.realpower)"
  battery_type="$(upsc "${ups}" battery.type)"
  battery_runtime="$(upsc "${ups}" battery.runtime)"
  battery_charge="$(upsc "${ups}" battery.charge)"
  battery_voltage="$(upsc "${ups}" battery.voltage)"
  battery_voltage_nominal="$(upsc "${ups}" battery.voltage.nominal)"
  battery_capacity="$(upsc "${ups}" battery.capacity)"
  battery_current="$(upsc "${ups}" battery.current)"
  battery_temperature="$(upsc "${ups}" battery.temperature)"
  battery_change_date="$(upsc "${ups}" battery.date)"
  battery_manufacturing_date="$(upsc "${ups}" battery.mfr.date)"

  (
    echo "UPS: ${manufacturer} ${model} (Serial #: ${serial_number} / FW: ${firmware_version})"
    echo "Status: ${status}"
    echo "Load: ${load}%"

    echo "Input Voltage: ${input_voltage}V"
    echo "Input Frequency: ${input_frequency}Hz"

    echo "Output Voltage: ${output_voltage}V"
    echo "Output Voltage (nominal): ${output_volatage_nominal}V"
    echo "Output Apparent Power: ${power}VA"
    echo "Output Apparent Power (nominal): ${power_nominal}VA"
    echo "Output Real Power: ${real_power}W"
    echo "Output Real Power (nominal): ${real_power_nominal}W"
    echo "Output Frequency: ${output_frequency}Hz"
    echo "Output Frequency (nominal): ${output_frequency_nominal}Hz"

    echo "Battery Type: ${battery_type}"
    echo "Battery Runtime: ${battery_runtime}s"
    echo "Battery Charge: ${battery_charge}%"

    echo "Beeper Status: ${beeper_status}"
    echo "Shutdown Timer: ${timer_shutdown}s"
    echo "Start Timer: ${timer_start}s"
    echo "Shutdown Delay: ${delay_shutdown}s"
    echo "Start Delay: ${delay_start}s"
  ) >> "${EMAIL_CONTENT}"
done

(
  echo ""
  echo "-- End of UPS status report --"
  echo "</pre>"
) >> "${EMAIL_CONTENT}"

sendmail -t < "${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
