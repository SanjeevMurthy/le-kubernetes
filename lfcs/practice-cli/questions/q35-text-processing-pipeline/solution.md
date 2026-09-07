# Q35. Reports from a log with grep, sort, uniq, sed and awk (solution)

## Steps

**1. The five most frequent client addresses.**

```bash
cd /opt/course/35
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5 > top-ips.txt
cat top-ips.txt
```

**2. Every 5xx line, in log order.**

```bash
grep -E ' 5[0-9]{2} ' access.log > errors.txt
wc -l < errors.txt
```

**3. Rewrite the URLs in place, keeping a backup.**

```bash
grep -c 'http://' urls.txt          # read the file before changing it
sed 's,http://,https://,g' urls.txt # dry run, output only
sed -i.bak 's,http://,https://,g' urls.txt
grep -c 'http://' urls.txt          # expect 0
ls urls.txt urls.txt.bak
```

**4. The third field of the CSV, header excluded.**

```bash
awk -F, 'NR > 1 {print $3}' data.csv > col3.txt
```

## Why

`uniq` collapses only adjacent duplicates, so the first `sort` is mandatory and is the step most often left out. The second `sort -rn` is numeric and descending, which puts the largest count first; a plain `sort -r` would compare the counts as text and put `9` above `40`.

`grep -c` counts matching lines rather than matches, which is the right count here because one log line carries one status code. When a line can match more than once the honest form is `grep -o pattern file | wc -l`.

The spaces inside `' 5[0-9]{2} '` are what keep the pattern on the status field. Without them the same three digits match inside a byte count, a path or a timestamp. `grep -E` takes the unescaped `{2}`; basic grep needs `\{2\}` instead, so pick one dialect per command and stay in it.

`sed -i.bak` edits in place and leaves the original beside it under the new suffix. Plain `sed -i` has no undo at all. Running the expression once without `-i` and reading the output is the habit that prevents a wrong expression from destroying `/etc/fstab` or `sshd_config`.

`sed` takes any delimiter after `s`, so `s,http://,https://,g` avoids escaping every slash. `https://` does not contain the string `http://`, so a second run of the same command changes nothing, and grepping for `http://` afterwards is a real check.

In awk, `-F,` splits on a literal comma, `$3` is the third field, `NR` is the record number so `NR > 1` skips the header, and `$0` would be the whole line.

## Verify

```bash
cd /opt/course/35
cat top-ips.txt && wc -l < top-ips.txt            # expect exactly 5 lines
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5   # the same thing

wc -l < errors.txt
grep -cE ' 5[0-9]{2} ' access.log                 # the same number

grep -c 'http://' urls.txt                        # expect 0
grep -c 'http://' urls.txt.bak                    # the original count
diff <(awk -F, 'NR > 1 {print $3}' data.csv) col3.txt && echo MATCH
```

## Docs

- `man 1 grep` for `-E`, `-c`, `-o` and `-v`
- `man 1 sed` for `-i`, the `s` command and its delimiters
- `man 1 awk`, often a link to `man 1 gawk` or `man 1 mawk`, for `-F`, fields, `NR` and `NF`
- `man 1 sort` for `-n`, `-r` and `-h`, and `man 1 uniq` for `-c`
- `man 1 cut`, `man 1 tr`, `man 1 wc` and `man 1 head` for the rest of the pipeline
- `man 7 regex` for the regular expression syntax itself
