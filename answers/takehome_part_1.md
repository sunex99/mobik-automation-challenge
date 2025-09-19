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

**Actions taken:**

- I identified `/home/trainnee` as a potential backdoor due to its suspicious name and ownership.
- I removed the folder to eliminate any possible backdoor:

  ```zsh
  sudo rm -rf /home/trainnee
  ```

- I verified that only the expected user accounts (`trainee` and `trainee-one`) exist.

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

I wanted to scan all CSV files under ~/capture/data, including subfolders, and check for structural issues. So I used find to locate every .csv file recursively. For each file, I extracted the expected column count from the header and used awk to compare it against the rest of the rows. If any row didn’t match, I logged the file path to a text file. This way, I could silently detect and record corrupted files based on inconsistent structure.

```bash
find "$HOME/capture/data" -type f -name "*.csv"
head -n 1 "$file" | awk -F',' '{print NF}'
awk -F',' -v cols="$expected_columns" 'NR > 1 && NF != cols { print FILENAME " - inconsistent columns at line " NR; exit 1 }' "$file"
```

### 3.2 Fix the issue

I wrote a bash script that cleans up all the CSV files in my dataset by removing structurally corrupted lines — rows that don’t match the column count defined in the header. The script scans every CSV file under ```~/capture/data```, figures out the expected number of columns from the header, and checks each row against it. If a row is corrupted, I save it to ```~/capture/corrupted.csv``` for review. Valid rows are written to a temporary file, which then replaces the original — so each CSV ends up cleaned, and I still keep track of what was removed.

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

    This runs the script at minute 0 of every hour. 
    TODO: Check for faliures.