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
  manufacturer="$(upsc "${ups}" ups.mfr)"
  model="$(upsc "${ups}" ups.model)"
  serial_number="$(upsc "${ups}" ups.serial)"
  firmware_version="$(upsc "${ups}" ups.firmware)"
  status="$(upsc "${ups}" ups.status)"
  beeper_status="$(upsc "${ups}" ups.beeper.status)"
  timer_shutdown="$(upsc "${ups}" ups.timer.shutdown)"
  timer_start="$(upsc "${ups}" ups.timer.start)"
  delay_shutdown="$(upsc "${ups}" ups.delay.shutdown)"
  delay_start="$(upsc "${ups}" ups.delay.start)"
  power="$(upsc "${ups}" ups.power)"
  power_nominal="$(upsc "${ups}" ups.power.nominal)"
  real_power="$(upsc "${ups}" ups.realpower)"
  real_power_nominal="$(upsc "${ups}" ups.realpower.nominal)"
  output_frequency="$(upsc "${ups}" output.frequency)"
  output_frequency_nominal="$(upsc "${ups}" output.frequency.nominal)"
  output_load="$(upsc "${ups}" ups.load)"
  output_voltage="$(upsc "${ups}" output.voltage)"
  output_volatage_nominal="$(upsc "${ups}" output.voltage.nominal)"
  input_frequency="$(upsc "${ups}" input.frequency)"
  input_voltage="$(upsc "${ups}" input.voltage)"
  battery_type="$(upsc "${ups}" battery.type)"
  battery_runtime="$(upsc "${ups}" battery.runtime)"
  battery_charge="$(upsc "${ups}" battery.charge)"

  (
    echo "UPS: ${manufacturer} ${model}"
    echo "Serial: ${serial_number}"
    echo "Status: ${status}"
    echo "Output Load: ${output_load}%"
    echo "Output Voltage: ${output_voltage}V"
    echo "Battery Runtime: ${battery_runtime}s"
    echo "Battery Charge: ${battery_charge}%"
  ) >> "${EMAIL_CONTENT}"
done

(
  echo ""
  echo "-- End of UPS status report --"
  echo "</pre>"
) >> "${EMAIL_CONTENT}"

sendmail -t < "${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
