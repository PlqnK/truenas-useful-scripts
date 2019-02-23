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

manufacturer="$(upsc "${UPS}" ups.mfr)"
model="$(upsc "${UPS}" ups.model)"
serial_number="$(upsc "${UPS}" ups.serial)"
status="$(upsc "${UPS}" ups.status)"
output_load="$(upsc "${UPS}" ups.load)"
output_voltage="$(upsc "${UPS}" output.voltage)"
battery_runtime="$(upsc "${UPS}" battery.runtime)"
battery_charge="$(upsc "${UPS}" battery.charge)"

(
  echo "UPS: ${manufacturer} ${model}"
  echo "Serial: ${serial_number}"
  echo "Status: ${status}"
  echo "Output Load: ${output_load}%"
  echo "Output Voltage: ${output_voltage}V"
  echo "Battery Runtime: ${battery_runtime}s"
  echo "Battery Charge: ${battery_charge}%"
  echo ""
  echo "-- End of UPS status report --"
  echo "</pre>"
) >> "${EMAIL_CONTENT}"

sendmail -t < "${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
