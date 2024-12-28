<!-- markdownlint-disable MD024 -->
# Pagpapanatili backup tooling

- [Introduction](#introduction)
- [Usage](#usage)
- [Getting started](#getting-started)
- [Profiles](#profiles)
- [Examples](#examples)
- [Retention and pruning](#retention-and-pruning)
- [Files](#files)

## Introduction

Pagpapanatili *(Tagalog: [noun] preservation; maintenance; retention;
perpetuation)* provides configuration files, a configuration tool, and a wrapper
for [resticprofile](https://github.com/creativeprojects/resticprofile).
Resticprofile is a configuration manager for
[restic](https://github.com/restic/restic). Resticprofile and restic do the
heavy lifting here. Pagpapanatili can also integrate with
[Ayusin](https://github.com/jamebus/ayusin) to run backup and pruning tasks
in your day-to-day workflow.

While this tool is designed to streamline the use of the Pagpapanatili backup
service, it's compatible with anything restic can talk to.

## Usage

```text
Usage: pag [options] [command]
       pag [options] [resticprofile flags] [profile name.]restic-command [restic flags]
       pag [options] [resticprofile flags] [profile name.]resticprofile-command [command specific flags]

       --version               Show version
       -v, --verbose           Enable verbose output
       -n, --dry-run           Show what would have happened
       -h, --help              Show this help
       --help-resticprofile    Show the help for resticprofile
       --help-restic           Show the help for restic

       config, configure       Configure
       version                 Show version
```

## Getting started

### Installation

#### MacOS

- Install via [Homebrew](https://brew.sh/): `brew install
  jamebus/tools/pagpapanatili`
- Install via [Homebrew](https://brew.sh/) with
  [Ayusin](https://github.com/jamebus/ayusin): `brew install --with-ayusin
  jamebus/tools/pagpapanatili`
- Install via source: `make install prefix=/foo/bar/baz`. Prefix defaults to
  `/usr/local`

#### Other operating systems

Coming soon for other operating systems. *BSD and GNU/Linux distros will be
next. Windows... probably not for a while. 😅

### Configuration

`pag configure`, or `pag config` will start the configuration wizard. You can
use this to bootstrap a new configuration or modify an existing one, respecting
your current settings.

#### Prompts

Configuration prompts use standard editing/selection features, such as arrow
keys, control sequences, enter to confirm, and escape to exit.

#### Repository configuration

Your *repository* is where the backups are stored. Repositories are stored in
*buckets*.

It is possible to have multiple repositories per bucket. For example, having
separate repositories for your personal, educational, and business machines is
helpful. Consider using a descriptive prefix in your repository URL if this is a
use case.

These will be provided during onboarding:

- **URL**, URL to the repository (example: `s3:s3.amazonaws.com/mybucket/restic`)
- **Region**, region your bucket is provisioned in (example: `us-east-1`)

#### Storage authentication configuration

Credentials used to connect to your bucket are stored in *profiles*. You can
create a new profile or use an existing one (which is helpful for a
multiple repository configuration).

The default name is usually OK. You may want to choose a different name if you
wish to use multiple buckets or regions and want to differentiate them easily.

- **Profile**, name of the profile (example: `pagpapanatili`)

These will be provided during onboarding:

- **Access key id**, your access key id (example: `foo`)
- **Secret access key**, your secret access key (example: `bar`)

**⚠ Remember to keep your credentials safe!** These allow access to your storage
system. Keeping them secure prevents undesired access, data leaks, and abuse.

#### Repository encryption configuration

Your *password* is used to encrypt and decrypt your backups. You won't need to
remember it. While it's best to auto-generate one, you can also enter one if
required. This is especially useful if you are using an existing repository.

You can auto-generate a password or enter one. The default size is good. You can
choose a different size if you have special requirements.

##### Keep your password safe

**⚠ Remember to keep your password safe!** This allows your backups to be
encrypted and decrypted. Keeping this secure prevents undesired access and
modification of your backups.

##### Consider saving your password

Your password will be saved; you won't need it again to use your backups. You
may wish to store your password elsewhere in case your saved password becomes
unavailable. This can happen during drive failures or when restoring to a fresh
machine.

☞ Losing your password means that your backups are **irrecoverably lost**. It is
recommended to save your password to your password manager or similar secure
storage.

#### Ayusin tasks

Pagpapanatili can integrate with [Ayusin](https://github.com/jamebus/ayusin) to
run backup and pruning tasks.

##### Create a home directory backup task

It's recommended to create a backup at least once a day. You can install an
`ayusin` task to back up your home directory.

##### Create a repository prune task

Pruning the repository once a month is recommended. You can install an `ayusin`
task to prune your repository. The task will run every 30 days.

## Profiles

Pagpapanatili ships with three *profiles*: `default`, `home`, `currentdir`. Each
of these represents scope and intent.

- `default` runs commands against the entire repository. This profile is helpful
  for repository maintenance or restoring from a specific snapshot.
- `home` runs commands against your home directory. This profile is helpful for
  backing up your home directory. An APFS snapshot is created, and your home
  directory is backed up from that.
- `currentdir` runs commands against the current directory. This profile helps
  you take quick backups of your project as you work on it. An APFS snapshot is
  not used.

## Examples

### List snapshots

```sh
# These are equivalent. When no profile is specified, default is used. When no
# command is given, snapshots is assumed.
pag
pag snapshots
pag default.snapshots

# List snapshots for other profiles.
pag home.snapshots
pag currentdir.snapshots
```

### Back up

```sh
# Back up home directory
pag home.backup

# Back up current directory
pag currentdir.backup
```

#### Further reading

- [Backing up — restic documentation](https://restic.readthedocs.io/en/stable/040_backup.html)

### Restore

#### Using the command line

```sh
# Restore latest Desktop directory to a temporary directory. You can use the
# special keyword, latest, to indicate the most recent snapshot.
cd "$(mktemp -d)"
pag home.restore -i ~/Desktop --target=. latest

# Restore that important document that just got accidentally auto-saved.
cd "$(mktemp -d)"
pag home.restore -i ~/Documents/'Awesome report.pdf' --target=. latest
mv -iv 'Users/fmyers/Documents/Awesome report.pdf' ~/Documents

# Restore a previous version of a project for comparison.
pag currentdir.restore --target="$(mktemp -d)" 27f29544

# Restore last week's Downloads directory to get a few things from it.
cd "$(mktemp -d)"
# Find the snapshot that you want
pag home.snapshots --latest=10
# Restore from that snapshot
pag home.restore -i ~/Downloads --target=. snapshotid
```

#### Using FUSE

You can mount snapshots using FUSE, allowing you to work with their contents
using a network-mounted filesystem. You'll first need to install
[macfuse](https://macfuse.github.io/) (available in Homebrew,
`brew install macfuse`). You can use `pag mount` to mount your snapshots. Refer
to `pag mount --help` for options.

☞ `pag mount` is mostly useful if you want to restore just a few files out of a
snapshot, or to check which files are contained in a snapshot. To restore many
files or a whole snapshot, `pag restore` is the best alternative, often it is
*significantly* faster.

#### Using third-party tools

You can use any tool that works with restic, such as
[restic-browser](https://github.com/emuell/restic-browser)
(available in Homebrew, `brew install restic-browser`), to view and restore your
backups.

When configuring third-party tools, you may find your repository details and
password files in `~/.pagpapanatili`.

#### Further reading

- [Restoring from backup — restic documentation](https://restic.readthedocs.io/en/stable/050_restore.html)

### Diff

```sh
# Compare two snapshots
pag diff 421bcd74 042ed499
```

### Find

```sh
# Search for yaml and json files in the latest snapshot of your home directory.
# If your snapshots are large, this is more efficient than something like:
# "pag home.ls latest | egrep '\.(ya?ml|json)$'"
pag home.find --snapshot=latest '*.yaml' '**/*.yaml' '*.yml' '**/*.yml' '*.json' '**/*.json'

# Find the snapshot and path of a file. Helpful if you want to restore a file
# and aren't sure where it is and which revisions are available.
pag find profiles.yaml
```

### Show configuration

```sh
pag show
pag home.show
pag currentdir.show
```

## Retention and pruning

### Retention

After a backup, old snapshots will be *forgotten* using the following strategy:

- All snapshots within 90 days
- Daily snapshots within six months
- Weekly snapshots within one year
- Monthly snapshots within three years
- Yearly snapshots are retained forever
- Snapshots tagged with `forever` are retained forever

If you have a snapshot that should be kept forever, add the tag `forever`.

```sh
pag tag --add=forever snapshotid
```

### Pruning

*Pruning* removes data from the repository that is not needed any longer.
Unneeded data will accumulate from forgotten snapshots or interrupted backups,
so pruning your repository once a month is recommended. If you installed the
`ayusin` task, the task will do this for you every 30 days. Otherwise, you can
run it yourself.

```sh
pag prune
```

☞ If you have a lot of large snapshots, pruning can become expensive or crash
the system in extreme cases. If you encounter this issue, pruning can be
offloaded to our infrastructure.

## Files

Configuration files are loaded from the following directories in lexical order,
and keys are merged. The `show` command can be used to check precedence and
merging.

- `${share_dir}/profiles.d/*.yaml`
- `${user_config_dir}/profiles.d/*.yaml`

`$share_dir` is usually `/usr/local/share/pagpapanatili` (can be overridden at
install time). `$user_config_dir` is usually `~/.pagpapanatili` (can be
overridden by `$PAGPAPANATILI_USER_CONFIG_DIR` environment variable).

If you wish to add new profiles or override existing ones, add new yaml files to
`~/.pagpapanatili/profiles.d` containing the changes you want. Remember to take
advantage of configuration merging to get the best result.

### Further reading

- [Includes :: resticprofile](https://creativeprojects.github.io/resticprofile/configuration/include/index.html)
- [Reference :: resticprofile](https://creativeprojects.github.io/resticprofile/configuration/reference/index.html)
