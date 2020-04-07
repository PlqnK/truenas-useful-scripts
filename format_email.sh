#!/usr/bin/env bash
#
# Bash functions to format an email to be sent by the FreeNAS 'sendmail' program.
# FreeNAS 'sendmail' uses a "custom" mail sending program, written in Python by the FreeNAS team.
# This Python program doesn't yet, as of FreeNAS 11.3-U2, support the Content-Type 'multipart/alternative'.

# Usage: format_email "Subject" "address@example.com" /path/to/body.html [/path/to/attachment.ext] | sendmail -i -t
format_email () {
  echo "MIME-Version: 1.0"
  echo "Subject: ${1}"
  echo "To: ${2}"
  if [[ -n "${4}" ]]; then
    email_boundary=$(head -c 24 /dev/urandom | base64)
    echo "Content-Type: multipart/mixed; boundary=\"${email_boundary}\""
    echo ""
    echo "--${email_boundary}"
  fi
  echo "Content-Type: text/html; charset=\"UTF-8\""
  echo "Content-Transfer-Encoding: quoted-printable"
  echo ""
  cat "${3}" | perl -pe 'use MIME::QuotedPrint; $_=MIME::QuotedPrint::encode($_);'
  echo ""
  if [[ -n "${4}" ]]; then
    echo "--${email_boundary}"
    echo "Content-Type: text/plain; charset=\"US-ASCII\"; name=\"$(basename ${4})\""
    echo "Content-Disposition: attachment; filename=\"$(basename ${4})\""
    echo "Content-Transfer-Encoding: base64"
    echo ""
    cat "${4}" | base64
    echo "--${email_boundary}--"
  fi
}
