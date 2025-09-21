# Part 1


## 1. Basic security

According to the instructions, I should have access to the `trainee` account, but I only have access to `trainee-one`. All actions were performed using the `trainee-one` account.

While inspecting the `/home` directory, I found a suspicious folder named `trainnee`:

```zsh
drwx------ 5 trainee     trainee     4096 Sep 17 14:19 trainee
drwx------ 5 trainee-one trainee-one 4096 Sep 19 09:02 trainee-one
drwxr-xr-x 3 root        root        4096 Sep 17 14:34 trainnee
```

- The `trainnee` folder is owned by `root` and has different permissions compared to the other home folders.
- TODO: There is **no user account named `trainnee`** in `/etc/passwd`, only the folder exists.

I ran the following command to verify that the `trainnee` user has not signed in:

```zsh
who -a
w
last -n 50
```

I have also listed all the processes:

```zsh
trainee-one@box-three:~$ ps aux
```

I noticed something interesting when inspecting recently modified files:

```zsh
trainee-one@box-three:~$ find / -type f -mtime -2 2>/dev/null | head -n 50
/run/motd.dynamic
/run/sshd.pid
/run/user/1001/systemd/generator.late/app-xdg\x2duser\x2ddirs@autostart.service
/run/user/1001/systemd/inaccessible/reg
/run/resolvconf/run-lock
/run/systemd/timesync/synchronized
/run/systemd/transient/session-246.scope
/run/systemd/transient/session-244.scope
/run/systemd/users/1001
/run/systemd/sessions/246
/run/systemd/sessions/244
/run/systemd/sessions/245
/run/systemd/journal/streams/9:74275874
/run/systemd/journal/streams/9:72767252
/etc/passwd
/etc/group
/etc/shadow
/etc/subuid
/etc/subgid
/etc/gshadow
/proc/fb
/proc/fs/ext4/sda1/fc_info
/proc/fs/ext4/sda1/options
/proc/fs/ext4/sda1/mb_stats
/proc/fs/ext4/sda1/mb_groups
/proc/fs/ext4/sda1/es_shrinker_info
/proc/fs/ext4/sda1/mb_structs_summary
/proc/fs/jbd2/sda1-8/info
/proc/bus/pci/00/00.0
/proc/bus/pci/00/01.0
/proc/bus/pci/00/02.0
/proc/bus/pci/00/02.1
/proc/bus/pci/00/02.2
/proc/bus/pci/00/02.3
/proc/bus/pci/00/02.4
/proc/bus/pci/00/02.5
/proc/bus/pci/00/02.6
/proc/bus/pci/00/02.7
/proc/bus/pci/00/03.0
/proc/bus/pci/00/1f.0
/proc/bus/pci/00/1f.2
/proc/bus/pci/00/1f.3
/proc/bus/pci/01/00.0
/proc/bus/pci/02/00.0
/proc/bus/pci/03/00.0
/proc/bus/pci/04/00.0
/proc/bus/pci/05/00.0
/proc/bus/pci/06/00.0
/proc/bus/pci/devices
/proc/bus/input/devices
```

I also inspected some crons:

```zsh
trainee-one@box-three:~$ ls -la /etc/cron.d /etc/cron.daily /etc/cron.hourly
/etc/cron.d:
total 16
drwxr-xr-x  2 root root 4096 Aug 14 10:17 .
drwxr-xr-x 77 root root 4096 Sep 19 09:00 ..
-rw-r--r--  1 root root  188 Jul 30 19:39 e2scrub_all
-rw-r--r--  1 root root  102 Jun 13 08:30 .placeholder

/etc/cron.daily:
total 32
drwxr-xr-x  2 root root 4096 Aug 14 10:18 .
drwxr-xr-x 77 root root 4096 Sep 19 09:00 ..
-rwxr-xr-x  1 root root 1478 Jun 24 17:02 apt-compat
-rwxr-xr-x  1 root root  314 Feb 15  2025 aptitude
-rwxr-xr-x  1 root root  123 May 27 18:07 dpkg
-rwxr-xr-x  1 root root  377 Jul 14  2024 logrotate
-rwxr-xr-x  1 root root 1395 May  2 13:24 man-db
-rw-r--r--  1 root root  102 Jun 13 08:30 .placeholder

/etc/cron.hourly:
total 12
drwxr-xr-x  2 root root 4096 Aug 14 10:16 .
drwxr-xr-x 77 root root 4096 Sep 19 09:00 ..
-rw-r--r--  1 root root  102 Jun 13 08:30 .placeholder
```

**Conclusions:**

- I identified `/home/trainnee` as a potential backdoor due to its suspicious name and ownership.
- I removed the folder to eliminate any possible backdoor:

  ```zsh
  sudo rm -rf /home/trainnee
  ```
  
  Not applicable due to `trainee-one` is not in the sudoers file.

- I verified that only the expected user accounts (`trainee` and `trainee-one`) exist.
- Suspicious `psimon` process. Looks like a disguised rootkit process.
- I saw prior logins from unknown IPs under trainee, and evidence that `/etc/passwd` and `/etc/shadow` were recently modified
- I found a single SSH key in my own account’s ~/.ssh/authorized_keys that belonged to an external user (kristjan.voje@mobik.com), likely added by a malicious actor.
  Using nano ~/.ssh/authorized_keys, I removed the malicious key line, leaving the file otherwise intact,
  ensuring the attacker cannot access my account via that key. Password-based SSH login still works for my account,
  so removing the key did not lock me out. Any active attacker sessions remain until terminated,
  but future logins using the removed key are blocked.

**Note:**  
If access to the `trainee` account is required, please clarify, as only `trainee-one` was accessible during the exam.

## 2. Capture the flags

According to the instructions, the flags should be inside `/home/user/trainee`, but I only have access to `/home/trainee-one`.

I searched for flags using:

```zsh
grep -r 'FLAG{' /home/trainee-one/
grep -a -r 'FLAG{' /home/trainee-one/
```

**Flags found:**

- `/home/trainee-one/.opt/myapp/bin/flag.txt`: `FLAG{Nice job. Good luck with the rest!}`
- (Binary file match) `/home/trainee-one/hello`: `FLAG{Contrats on the find!}`

I ran the binary `/home/trainee-one/hello` and it printed:

```zsh
I'm hiding a flag, can you find it?
```

I also tried running it with possible arguments (e.g., `secret_flag`), but no additional flag was revealed. Only two flags were found in my accessible user account.

## 3. Fix corrupted files

### 3.1 Find the corrupted .csv files

I wanted to scan all CSV files under ~/capture/data, including subfolders, and check for structural issues. So I used find to locate every .csv file recursively.
For each file, I extracted the expected column count from the header and used awk to compare it against the rest of the rows. If any row didn’t match,
I logged the file path to a text file. This way, I could silently detect and record corrupted files based on inconsistent structure.

```bash
find "$HOME/capture/data" -type f -name "*.csv"
head -n 1 "$file" | awk -F',' '{print NF}'
awk -F',' -v cols="$expected_columns" 'NR > 1 && NF != cols { print FILENAME " - inconsistent columns at line " NR; exit 1 }' "$file"
```

### 3.2 Fix the issue

I wrote a bash script that cleans up all the CSV files in my dataset by removing structurally corrupted lines — rows that don’t match the column count defined in the header.
The script scans every CSV file under ```~/capture/data```, figures out the expected number of columns from the header, and checks each row against it.
If a row is corrupted, I save it to ```~/capture/corrupted.csv``` for review. Valid rows are written to a temporary file, 
swhich then replaces the original — so each CSV ends up cleaned, and I still keep track of what was removed.

```bash
head -n 1 "$file" | awk -F',' '{print NF}'
mktemp
awk -F',' -v cols="$expected" -v out="$CORRUPTED_OUTPUT" '
  NR == 1 { print $0 > "'"$tmp_clean"'"; next }
  NF == cols { print $0 >> "'"$tmp_clean"'" }
  NF != cols { print $0 >> out }
' "$file"
mv "$tmp_clean" "$file"

```

## 3.3 Scheduled run

1. Opened my crontab editor

    ```zsh
    crontab -e
    ```

2. Added the cron job

    ```zsh
    0 * * * * /bin/bash ~/capture/scripts/remove_corrupted_lines.sh
    ```

  This runs the script at minute 0 of every hour. I implemented error and failure checking by adding timestamped logging to ~/capture/logs/cleanup.log,
  which records each file processed, any issues encountered (like unreadable headers or failed file replacements),
  and the overall status of each run. I also used conditional checks and continue to safely skip problematic files without interrupting the script.