# TrueNAS Useful Scripts

## Disclaimer

These scripts are based on [TrueNAS forums user Bidule0hm scripts](https://www.truenas.com/community/threads/scripts-to-report-smart-zpool-and-ups-status-hdd-cpu-t%C2%B0-hdd-identification-and-backup-the-config.27365/) which are themselves based on [TrueNAS forums user joeschmuck scripts](https://www.truenas.com/community/threads/set-up-smart-reporting-via-email.6211/) and [TrueNAS forums user titan_rw scripts](https://www.truenas.com/community/threads/set-up-smart-reporting-via-email.6211/). Though I still did a lot of work, like rewriting large parts of them and doing some overall code cleaning.

## About the project

This is a collection of useful scripts for TrueNAS admins that want to have more reporting than just what's included in the OS, display useful information like HDD and CPU temperature easily in a terminal and scripting the backup of the TrueNAS config.

## Roadmap

- Change how SMART and zpool reports are displayed in order to use native HTML tables.
- Take some ideas from [Spearfoot FreeNAS scripts](https://github.com/Spearfoot/FreeNAS-scripts), in particular the encryption (but using GPG instead of a symetric algorithm like AES256) and sending of a correctly MIME-formated config backup as an email attachment.
- Add GitHub actions to lint the scripts.

## Prerequisites

- TrueNAS 12.0+ (for FreeNAS 11.3 see the `v1.0` git tag)

## Installation

```bash
git clone https://github.com/PlqnK/truenas-useful-scripts.git
cd truenas-useful-scripts
for file in *.example*; do cp $file $(echo $file | sed -e 's/.example//'); done
```

You then need to adapt the variables in the `user.conf` file according to your setup and needs.

Next, set the scripts as executable:

```bash
find . -type f -name "*.sh" -exec chmod +x {} \;
```

Finally you will need to create cron jobs in the TrueNAS WebUI in order to execute the reporting and backup script on a schedule. [The TrueNAS documentation explains how to do it.](https://www.truenas.com/docs/hub/tasks/scheduled/cron-jobs/) The command to execute should be:

```sh
/path/to/the/script.sh
```

## Contributing

Contributions in the form of issues or PR are welcome if you see any area of improvement or if you have new ideas for useful scripts!

This project is following [Google Shell style guidelines](https://google.github.io/styleguide/shell.xml) and [translate-shell AWK style guidelines](https://github.com/soimort/translate-shell/wiki/AWK-Style-Guide) but I prefer to keep AWK usage to a minimum, only when there's no really usable bash alternative.

## License

This project is released under the [BSD 3-Clause License](https://opensource.org/licenses/BSD-3-Clause). A copy of the license is available in this project folder.
