#!/usr/bin/env bash
#
# Send a FreeNAS config backup via Email and also store it somewhere in a data pool.

readonly repoParentDirectory="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
source "${repoParentDirectory}"/user.conf && source "${repoParentDirectory}"/global.conf

readonly EMAIL_SUBJECT="$(hostname) config backup"
readonly EMAIL_CONTENT="/tmp/config_backup_error.eml"
readonly TAR_FILE="/tmp/config_backup.tar.gz"

if [ "$(sqlite3 /data/freenas-v1.db "pragma integrity_check;")" == "ok" ]; then # Send via Email/Store config backup
  cp /data/freenas-v1.db /tmp/"${BACKUP_FILE_NAME}".db
  md5 /tmp/"${BACKUP_FILE_NAME}".db > /tmp/config_backup.md5
  sha256 /tmp/"${BACKUP_FILE_NAME}".db > /tmp/config_backup.sha256
  tar -czf "${TAR_FILE}" -C /tmp/ "${BACKUP_FILE_NAME}".db -C /tmp/ config_backup.md5 -C /tmp/ config_backup.sha256
  # Add the backup config file inline because the mail utility of FreeNAS (as of version 11.1) is an old version that
  # doesn't support the "-a" argument to attach files in MIME format
  uuencode "${TAR_FILE}" "${BACKUP_FILE_NAME}".tar.gz | mail -s "${EMAIL_SUBJECT}" "${EMAIL_ADDRESS}"
  # Also store it somewhere that will be backed up by another service
  cp "${TAR_FILE}" "${BACKUP_FILE_PATH}"/"${BACKUP_FILE_NAME}".tar.gz
  rm /tmp/"${BACKUP_FILE_NAME}".db
  rm /tmp/config_backup.md5
  rm /tmp/config_backup.sha256
  rm "${TAR_FILE}"
else # Send error message via Email
  (
    echo "To: ${EMAIL_ADDRESS}"
    echo "Subject: ${EMAIL_SUBJECT}"
    echo "Content-Type: text/html"
    echo -e "MIME-Version: 1.0\n" # Need a blank line between the headers and the body as per RFC 822
    # Only specify monospace font to let Email client decide of the rest
    echo "<pre style=\"font-family:monospace\">" >>"${EMAIL_CONTENT}"
    echo "<b>/!\ Automatic backup of FreeNAS config failed:</b>"
    echo "The config file is corrupted, you should correct this problem as soon as possible."
    echo ""
    echo "-- End of failed config backup report --"
    echo "</pre>"
  ) >>"${EMAIL_CONTENT}"
  sendmail -t <"${EMAIL_CONTENT}"
  rm "${EMAIL_CONTENT}"
fi
