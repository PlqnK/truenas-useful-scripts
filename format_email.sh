#!/usr/bin/env bash
#
# Bash functions to format an email to be sent by the FreeNAS 'sendmail' program.
# FreeNAS 'sendmail' uses a "custom" mail sending program, written in Python by the FreeNAS team.
# This Python program doesn't yet, as of FreeNAS 11.3-U2, support the Content-Type 'multipart/alternative'.

# Usage: format_email_header "Email Subject" "Email Address" > /path/to/formated.eml
format_email_header () {
  email_boundary=$(head -c 24 /dev/urandom | base64)

  echo "MIME-Version: 1.0"
  echo "Subject: ${1}"
  echo "To: ${2}"
  echo "Content-Type: multipart/mixed; boundary=\"${email_boundary}\""
  echo ""
}

# Usage: format_email_body /path/to/body.html >> /path/to/formated.eml
format_email_body () {
  echo "--${email_boundary}"
  echo "Content-Type: text/html; charset=\"UTF-8\""
  echo "Content-Transfer-Encoding: quoted-printable"
  echo ""
  cat "${1}" | perl -pe 'use MIME::QuotedPrint; $_=MIME::QuotedPrint::encode($_);'
  echo ""
}

# Usage: format_email_attachment /path/to/attachment.ext >> /path/to/formated.eml
format_email_attachment () {
  echo "--${email_boundary}"
  echo "Content-Type: text/plain; charset=\"US-ASCII\"; name=\"$(basename ${1})\""
  echo "Content-Disposition: attachment; filename=\"$(basename ${1})\""
  echo "Content-Transfer-Encoding: base64"
  echo ""
  cat "${1}" | base64
}

# Usage: format_email_footer >> /path/to/formated.eml
format_email_footer () {
  echo "--${email_boundary}--"
}
