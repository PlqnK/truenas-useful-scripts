#!/usr/bin/env bash
#
# Bash functions to format an email to be sent by the TrueNAS 'sendmail' program.
# TrueNAS 'sendmail' uses a "custom" mail sending program, written in Python by the TrueNAS team.
# I can't make this program work with the Content-Type 'multipart/alternative'.
# And you are required to use the Content-Type: multipart/mixed, even when you have no attachment because the program
# will overwrite your other Content-Type/Transfer-Encoding if it's not set.

# Usage: format_email "Subject" "address@example.com" /path/to/body.html [/path/to/attachment.ext] | sendmail -i -t
format_email () {
  email_boundary=$(LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c 32)

  echo "MIME-Version: 1.0"
  echo "Subject: ${1}"
  echo "To: ${2}"
  echo "Content-Type: multipart/mixed; boundary=\"${email_boundary}\""
  echo ""
  echo "--${email_boundary}"
  echo "Content-Type: text/html; charset=\"UTF-8\""
  echo "Content-Transfer-Encoding: quoted-printable"
  echo ""
  perl -pe 'use MIME::QuotedPrint; $_=MIME::QuotedPrint::encode($_);' < "${3}"
  echo ""
  if [[ -n "${4}" ]]; then
    echo "--${email_boundary}"
    echo "Content-Type: text/plain; charset=\"US-ASCII\"; name=\"$(basename "${4}")\""
    echo "Content-Disposition: attachment; filename=\"$(basename "${4}")\""
    echo "Content-Transfer-Encoding: base64"
    echo ""
    base64 -e "${4}"
  fi
  echo "--${email_boundary}--"
}
