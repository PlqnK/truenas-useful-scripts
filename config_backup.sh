#!/usr/bin/env bash
#
# Send a TrueNAS config backup via Email and also store it somewhere in a data pool.

readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=user.example.conf
source "${SCRIPT_PATH}/user.conf"
# shellcheck source=global.conf
source "${SCRIPT_PATH}/global.conf"
# shellcheck source=format_email.sh
source "${SCRIPT_PATH}/format_email.sh"

readonly EMAIL_SUBJECT="TrueNAS $(hostname): Config backup"
readonly EMAIL_BODY="/tmp/config_backup.html"
readonly TAR_FILE="/tmp/${BACKUP_FILE_NAME}.tar.gz"

if [[ "$(sqlite3 /data/freenas-v1.db "pragma integrity_check;")" == "ok" ]]; then # Send via Email/Store config backup.
  cp /data/freenas-v1.db /tmp/"${BACKUP_FILE_NAME}".db
  sha256 /tmp/"${BACKUP_FILE_NAME}".db > /tmp/"${BACKUP_FILE_NAME}".db.sha256
  tar -czf "${TAR_FILE}" -C /tmp/ "${BACKUP_FILE_NAME}".db -C /tmp/ "${BACKUP_FILE_NAME}".db.sha256
  (
    # Only specify monospace font to let Email client decide of the rest.
    echo "<pre style=\"font-family:monospace\">"
    echo "<b>Automatic backup of TrueNAS config succeded!</b>"
    echo ""
    echo "You will find a compressed archive attached."
    echo ""
    echo "-- End of config backup report --"
    echo "</pre>"
  ) > "${EMAIL_BODY}"
  format_email "${EMAIL_SUBJECT}" "${EMAIL_ADDRESS}" "${EMAIL_BODY}" "${TAR_FILE}" | sendmail -i -t
  rm "${EMAIL_BODY}"
  # Also store it somewhere that will be backed up by another service.
  if [[ "${BACKUP_FILE_PATH}" != "" ]]; then
    cp "${TAR_FILE}" "${BACKUP_FILE_PATH}"/"${BACKUP_FILE_NAME}".tar.gz
    if [[ "${BACKUP_FILE_OWNER}" != "" ]]; then
      chown "${BACKUP_FILE_OWNER}" "${BACKUP_FILE_PATH}"/"${BACKUP_FILE_NAME}".tar.gz
    fi
  fi
  rm /tmp/"${BACKUP_FILE_NAME}".db
  rm /tmp/"${BACKUP_FILE_NAME}".db.sha256
  rm "${TAR_FILE}"
else # Send error message via Email.
  (
    # Only specify monospace font to let Email client decide of the rest.
    echo "<pre style=\"font-family:monospace\">"
    echo "<b>/!\ Automatic backup of TrueNAS config failed /!\</b>"
    echo ""
    echo "The config file is corrupted, you should correct this problem as soon as possible."
    echo ""
    echo "-- End of config backup report --"
    echo "</pre>"
  ) > "${EMAIL_BODY}"
  format_email "${EMAIL_SUBJECT}" "${EMAIL_ADDRESS}" "${EMAIL_BODY}" | sendmail -i -t
  rm "${EMAIL_BODY}"
fi
