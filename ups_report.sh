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
  echo -e "MIME-Version: 1.0\n"                # Need a blank line between the headers and the body as per RFC 822
  echo "<pre style=\"font-family:monospace\">" # Only specify monospace font to let Email client decide of the rest
  echo "<b>UPS status report:</b>"
  date "+Time: %Y-%m-%d %H:%M:%S"
  echo "UPS Status: $(upsc "${UPS}" ups.status)"
  echo "Output Load: $(upsc "${UPS}" ups.load)%"
  echo "Output Voltage: $(upsc "${UPS}" output.voltage)V"
  echo "Battery Runtime: $(upsc "${UPS}" battery.runtime)s"
  echo "Battery Charge: $(upsc "${UPS}" battery.charge)%"
  echo ""
  echo "-- End of UPS status report --"
  echo "</pre>"
) >"${EMAIL_CONTENT}"

# Send report via Email
sendmail -t <"${EMAIL_CONTENT}"
rm "${EMAIL_CONTENT}"
