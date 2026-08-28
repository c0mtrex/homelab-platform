# `sed` Command Guide and Cheat Sheet

## What `sed` is

`sed` means **stream editor**. It reads text one line at a time, applies editing instructions, and writes the result.

Common uses include:

- Finding and replacing text
- Previewing configuration changes
- Editing a file in place
- Printing selected lines
- Removing matching lines
- Inserting, appending, or replacing lines
- Cleaning command output
- Making controlled changes in shell scripts and CI jobs

`sed` is excellent for predictable line-oriented text changes. It is not a complete parser for JSON, YAML, XML, CSV, or programming languages.

## Basic mental model

```text
Input text -> sed instructions -> output text
```

Basic syntax:

```bash
sed [options] 'instruction' file
```

Without `-i`, `sed` prints the transformed result but does not change the original file.

Example:

```bash
sed 's/development/staging/' application.conf
```

This displays a modified version of `application.conf`. The file itself remains unchanged.

## The Kubernetes command we used

```bash
sed -i \
  's/^  replicas: "two"$/  replicas: 2/' \
  kubernetes/staging/service-health-api.yaml
```

### Command breakdown

| Part | Meaning |
|---|---|
| `sed` | Run the stream editor |
| `-i` | Edit the file in place |
| `s` | Substitute text |
| First `/` section | Pattern to find |
| Second `/` section | Replacement text |
| Final `/` | End of substitution instruction |
| File path | File that will be edited |

The search pattern was:

```text
^  replicas: "two"$
```

| Pattern part | Meaning |
|---|---|
| `^` | Beginning of the line |
| Two spaces | Exact YAML indentation |
| `replicas:` | Literal text |
| `"two"` | Literal incorrect value |
| `$` | End of the line |

The command means:

> Find a complete line containing exactly two spaces followed by `replicas: "two"`, and replace it with exactly two spaces followed by `replicas: 2`.

Because the pattern is anchored with `^` and `$`, it cannot replace the word `two` somewhere else in the file.

## Safe editing workflow

Use this process for important files.

### 1. Confirm the original text exists

```bash
grep -n '^  replicas: "two"$' \
  kubernetes/staging/service-health-api.yaml
```

### 2. Preview the substitution without `-i`

```bash
sed 's/^  replicas: "two"$/  replicas: 2/' \
  kubernetes/staging/service-health-api.yaml
```

### 3. Apply the change

```bash
sed -i \
  's/^  replicas: "two"$/  replicas: 2/' \
  kubernetes/staging/service-health-api.yaml
```

### 4. Inspect the Git diff

```bash
git diff -- kubernetes/staging/service-health-api.yaml
```

### 5. Validate the file

```bash
./scripts/validate.sh
```

### 6. Check whitespace problems

```bash
git diff --check
```

## Substitution syntax

The general form is:

```text
s/pattern/replacement/flags
```

### Replace the first match on each line

```bash
sed 's/error/warning/' application.log
```

Only the first `error` on each line is replaced.

### Replace every match on each line

```bash
sed 's/error/warning/g' application.log
```

The `g` flag means **global within each line**.

### Replace only the second match on each line

```bash
sed 's/error/warning/2' application.log
```

### Print only lines where a substitution occurred

```bash
sed -n 's/error/warning/p' application.log
```

- `-n` disables normal automatic output.
- `p` prints a line when the substitution succeeds.

### Case-insensitive replacement with GNU `sed`

```bash
sed 's/error/warning/gI' application.log
```

This matches `error`, `ERROR`, and other letter-case combinations. `I` is a GNU extension and is not fully portable to every `sed` implementation.

## Choosing a delimiter

The delimiter does not have to be `/`.

Replacing a URL with slash delimiters requires escaping:

```bash
sed 's/http:\/\/old.example.com/http:\/\/new.example.com/' config.txt
```

Using `#` is easier to read:

```bash
sed 's#http://old.example.com#http://new.example.com#' config.txt
```

Other delimiters may also be used:

```bash
sed 's|/old/path|/new/path|' config.txt
```

Choose a delimiter that does not appear frequently in the text.

## Regular-expression anchors

### Beginning of line

```bash
sed -n '/^ERROR/p' application.log
```

Print lines beginning with `ERROR`.

### End of line

```bash
sed -n '/failed$/p' application.log
```

Print lines ending with `failed`.

### Entire exact line

```bash
sed -n '/^enabled=true$/p' application.conf
```

The anchors prevent matching extra text before or after the desired value.

### Empty lines

```bash
sed -n '/^$/p' file.txt
```

### Lines containing only spaces or tabs

```bash
sed -n '/^[[:space:]]*$/p' file.txt
```

## Useful character patterns

| Pattern | Meaning |
|---|---|
| `.` | Any one character |
| `*` | Zero or more of the preceding expression |
| `[abc]` | One character: `a`, `b`, or `c` |
| `[^abc]` | One character other than `a`, `b`, or `c` |
| `[0-9]` | One digit |
| `[[:digit:]]` | One digit using a portable character class |
| `[[:space:]]` | Whitespace |
| `[[:alpha:]]` | Alphabetic character |
| `[[:alnum:]]` | Letter or digit |

Example: print lines containing an IPv4-looking address:

```bash
sed -n '/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/p' file.txt
```

This finds the shape of an address but does not validate that every number is between 0 and 255.

## Basic versus extended regular expressions

Traditional `sed` uses Basic Regular Expressions. GNU `sed -E` enables Extended Regular Expressions, which are often easier to read.

Without `-E`:

```bash
sed -n '/\(error\|warning\)/p' application.log
```

With `-E`:

```bash
sed -n -E '/(error|warning)/p' application.log
```

Use `-E` when grouping, alternation, or repetition makes the expression clearer.

## Capture groups and backreferences

Capture groups remember part of the matched text.

Example input:

```text
version=1.2.3
```

Command:

```bash
sed -E 's/^(version=)(.*)$/\1\2-release/' file.txt
```

Meaning:

- `(version=)` is capture group 1.
- `(.*)` is capture group 2.
- `\1` inserts group 1 into the replacement.
- `\2` inserts group 2 into the replacement.

Result:

```text
version=1.2.3-release
```

## The `&` replacement symbol

In replacement text, `&` means the entire matched value.

```bash
printf '%s\n' 'status=failed' |
  sed 's/failed/[&]/'
```

Result:

```text
status=[failed]
```

To insert a literal ampersand in replacement text, escape it:

```text
\&
```

## Printing selected text

### Print one line number

```bash
sed -n '25p' file.txt
```

### Print a line range

```bash
sed -n '20,35p' file.txt
```

### Print lines matching a pattern

```bash
sed -n '/startup_failed/p' application.log
```

### Print from one pattern through another

```bash
sed -n '/^spec:/,/^status:/p' object.yaml
```

This prints every line beginning at a line matching `^spec:` and ending at a line matching `^status:`.

### Show normally invisible characters

```bash
sed -n 'l' file.txt
```

This is useful for finding:

- Tabs
- Trailing spaces
- Carriage-return characters
- Unexpected escape characters

## Deleting lines

Without `-i`, these commands only print the proposed result.

### Delete one line number

```bash
sed '10d' file.txt
```

### Delete a range

```bash
sed '10,15d' file.txt
```

### Delete matching lines

```bash
sed '/DEBUG/d' application.log
```

### Delete empty lines

```bash
sed '/^$/d' file.txt
```

### Delete blank lines containing whitespace

```bash
sed '/^[[:space:]]*$/d' file.txt
```

## Inserting, appending, and changing lines

### Insert before a matching line

```bash
sed '/^services:/i\# Managed services begin here' compose.yaml
```

### Append after a matching line

```bash
sed '/^services:/a\  # Service definitions follow' compose.yaml
```

### Replace an entire matching line

```bash
sed '/^replicas:/c\replicas: 3' deployment.yaml
```

For indentation-sensitive files, preserve the exact spaces:

```bash
sed '/^  replicas:/c\  replicas: 3' deployment.yaml
```

Complex YAML modifications are usually safer with a YAML-aware tool such as `yq`.

## Multiple instructions

Use multiple `-e` options:

```bash
sed \
  -e 's/development/staging/g' \
  -e 's/debug=true/debug=false/' \
  application.conf
```

Or separate instructions with semicolons:

```bash
sed 's/development/staging/g; s/debug=true/debug=false/' application.conf
```

Separate `-e` options are often easier to read and review.

## Reading instructions from a file

Create a reusable `sed` instruction file:

```text
s/development/staging/g
s/debug=true/debug=false/
```

Run it with:

```bash
sed -f transformations.sed application.conf
```

This is useful when a transformation has many rules.

## In-place editing and backups

### Edit without a backup

```bash
sed -i 's/old/new/' file.txt
```

### Edit and retain the original

```bash
sed -i.backup 's/old/new/' file.txt
```

The original becomes:

```text
file.txt.backup
```

Inspect both:

```bash
diff -u file.txt.backup file.txt
```

### GNU/Linux versus macOS

GNU/Linux commonly accepts:

```bash
sed -i 's/old/new/' file.txt
```

The default macOS/BSD implementation commonly requires an explicit backup suffix, including an empty suffix:

```bash
sed -i '' 's/old/new/' file.txt
```

Portable automation should account for this difference.

## Shell quoting

### Single quotes

```bash
sed 's/$HOSTNAME/server/' file.txt
```

The shell does not expand `$HOSTNAME`. `sed` receives it literally.

### Double quotes

```bash
replacement='server01'
sed "s/old-host/$replacement/" file.txt
```

The shell expands `$replacement` before running `sed`.

### Safe variable delimiter example

```bash
old_url='http://old.example.com'
new_url='http://new.example.com'

sed "s#${old_url}#${new_url}#" application.conf
```

Be careful when variable values may contain delimiter characters, backslashes, ampersands, or untrusted user input. Blindly placing untrusted input in a `sed` expression can break the command or cause an unintended replacement.

## Practical DevOps use cases

### Change an environment name

```bash
sed 's/^ENVIRONMENT=development$/ENVIRONMENT=staging/' .env
```

### Update a pinned application version

```bash
sed -E \
  's/^(APP_VERSION=).*/\11.2.4/' \
  application.env
```

### Update a simple container tag

```bash
sed -E \
  's#^(  image: example/application:).*#\11.2.4#' \
  compose.yaml
```

For digest-pinned or structurally complex YAML, prefer `yq` or a purpose-built image-update tool.

### Extract application errors from mixed output

```bash
sed -n '/"level":"error"/p' application.log
```

For actual JSON logs, `jq` is safer and more precise:

```bash
jq 'select(.level == "error")' application.jsonl
```

### Remove comments for a simplified view

```bash
sed '/^[[:space:]]*#/d' application.conf
```

This does not understand quoted values containing `#`; use it only with a file format where line-leading `#` reliably means a comment.

### Replace localhost with a service name

```bash
sed 's#http://localhost:9090#http://prometheus:9090#g' config.txt
```

### Prefix every line

```bash
sed 's/^/[service-health-api] /' application.log
```

### Add a suffix to every non-empty line

```bash
sed '/^$/!s/$/ processed/' file.txt
```

The address `/^$/!` means apply the instruction to lines that are **not** empty.

### Convert Windows CRLF endings to Linux LF endings

```bash
sed -i 's/\r$//' file.txt
```

Preview hidden characters first:

```bash
sed -n 'l' file.txt
```

### Display a configuration section

```bash
sed -n '/^\[database\]/,/^\[/p' application.ini
```

This is useful for inspection, but a format-aware INI parser is safer for automated modification.

## Addresses: controlling which lines are changed

An address tells `sed` where to apply an instruction.

### Line-number address

```bash
sed '5s/old/new/' file.txt
```

Change only line 5.

### Pattern address

```bash
sed '/production/s/debug=true/debug=false/' file.txt
```

Change `debug=true` only on lines also containing `production`.

### Range address

```bash
sed '/BEGIN CONFIG/,/END CONFIG/s/old/new/g' file.txt
```

Change matches only inside the marked section.

### Negated address

```bash
sed '/^#/!s/development/staging/' file.txt
```

Change non-comment lines only.

## When `sed` is the wrong tool

Use a structure-aware tool when the format has nested data or quoting rules.

| Data or task | Better tool |
|---|---|
| JSON fields | `jq` |
| YAML objects | `yq`, Kustomize, Helm |
| XML | `xmlstarlet` or an XML library |
| CSV containing quoted commas/newlines | Python `csv`, Miller, or another CSV parser |
| Terraform configuration | Terraform tooling or an HCL parser |
| Complex programming-language refactoring | Language-aware formatter or refactoring tool |
| Binary files | Format-specific tool |

Why this matters:

```yaml
replicas: 2
```

is easy to change with an exact `sed` expression. However, finding the correct `replicas` field among many nested Deployments is a structural problem, not merely a text problem.

## Common mistakes

### Forgetting `-i`

Symptom: the terminal shows the desired change, but the file is unchanged.

Reason: without `-i`, `sed` writes to standard output.

### Using an overly broad pattern

Risky:

```bash
sed -i 's/2/3/g' deployment.yaml
```

This changes every `2`, including ports, versions, limits, and addresses.

Safer:

```bash
sed -i 's/^  replicas: 2$/  replicas: 3/' deployment.yaml
```

### Forgetting the `g` flag

```bash
sed 's/error/warning/' file.txt
```

Only changes the first match on each line.

### Matching indentation incorrectly

YAML indentation is meaningful. This pattern:

```text
^replicas:
```

will not match:

```text
  replicas:
```

### Confusing shell `$?` with a `sed` end anchor

In a `sed` pattern:

```text
$
```

means end of line.

In the shell:

```bash
echo "$?"
```

means print the previous command's exit code.

The meaning depends on which program interprets the character.

### Editing generated files

If a file is created by Terraform, Helm, a build, or another generator, edit the source template instead of repeatedly changing the generated output.

### Forgetting validation

A successful `sed` exit code means the command ran. It does not necessarily mean:

- A match was found
- The intended line changed
- The result is valid YAML
- Kubernetes accepts the resource
- The application still works

Always inspect and validate.

## Confirming whether a substitution matched

This command prints changed lines:

```bash
sed -n 's/^  replicas: "two"$/  replicas: 2/p' deployment.yaml
```

For automation, explicitly test the original pattern first:

```bash
if grep -q '^  replicas: "two"$' deployment.yaml; then
    sed -i 's/^  replicas: "two"$/  replicas: 2/' deployment.yaml
else
    printf '%s\n' 'Expected replica line was not found' >&2
    exit 1
fi
```

This prevents a script from silently succeeding when the expected source text is absent.

## Quick-reference table

| Goal | Command pattern |
|---|---|
| Preview replacement | `sed 's/old/new/' file` |
| Edit in place | `sed -i 's/old/new/' file` |
| Edit with backup | `sed -i.backup 's/old/new/' file` |
| Replace all matches per line | `sed 's/old/new/g' file` |
| Print matching lines | `sed -n '/pattern/p' file` |
| Print lines 10 through 20 | `sed -n '10,20p' file` |
| Delete matching lines | `sed '/pattern/d' file` |
| Insert before a match | `sed '/pattern/i\new line' file` |
| Append after a match | `sed '/pattern/a\new line' file` |
| Replace an entire line | `sed '/pattern/c\new line' file` |
| Use extended regex | `sed -E 's/(group)/\1/' file` |
| Use several instructions | `sed -e 'script1' -e 'script2' file` |
| Read instructions from a file | `sed -f rules.sed file` |
| Display hidden characters | `sed -n 'l' file` |
| Remove CRLF carriage returns | `sed -i 's/\r$//' file` |

## Recommended habit

For Git-managed configuration:

```text
Find exact source text
    -> preview without -i
    -> apply the narrow substitution
    -> inspect git diff
    -> run format/schema validation
    -> test behavior
    -> commit through CI
```

## Interview-sized explanation

> `sed` is a line-oriented stream editor commonly used in shell automation for predictable text transformations. I preview changes before using in-place mode, anchor patterns to avoid broad replacements, inspect the Git diff, and run format or schema validation afterward. For nested formats such as YAML or JSON, I use `sed` only for tightly controlled text changes and prefer structure-aware tools such as `yq` or `jq` for complex modifications.
