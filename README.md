hop_runner.dart
===============
Hop_runner.dart is a CLI runtime for distributable reusable tasks for [Dart](https://www.dartlang.org) based on [Hop](https://github.com/dart-lang/hop).

# Usage

## Basic Usage
Call a pub package designed to run from the [hop_runner](https://github.com/toolr/hop_runner.dart) commandline.
```bash
$ hop [<hop-options>] <task-lib> [<args>]
```

`<task-lib>` can be a pub repository, hosted or git repository or local path.
```
<task-lib>: [<pub-task-options>] [<name>, <url>, <path>]
-t, --type       [pub (default), path, git, hosted]                                                                                                                                                
-n, --name
-v, --version    (defaults to "any")
-r, --ref 
```

## Chained Usage
You can also chain task calls separated by comma.  Output from prior task is piped into subsequent task.
```bash
$ hop [<hop-options>] <task-lib> [<args>], <task-lib> [<args>], ...
```

## Autocompletion
Not currently implemented.  See [#5](https://github.com/toolr/hop_runner.dart/issues/5).

# Install
Simply copy and paste this into your terminal.
```bash
sudo mkdir /usr/local/hop && cd /usr/local/hop && sudo curl -O https://raw.githubusercontent.com/toolr/hop_runner.dart/master/hop && sudo curl -O https://raw.githubusercontent.com/toolr/hop_runner.dart/master/bin/hopsnapshot && sudo chmod +x hop && sudo printf '\n\n#Added By hop_runner\nexport PATH="/usr/local/hop":$PATH' >> ~/.bash_profile && . ~/.bash_profile && cd ~ && echo "Running: hop echo" && echo "First time takes a while..." && hop echo
```

OR

```bash
sudo mkdir /usr/local/hop
cd /usr/local/hop
sudo curl -O https://raw.githubusercontent.com/toolr/hop_runner.dart/master/hop
sudo curl -O https://raw.githubusercontent.com/toolr/hop_runner.dart/master/bin/hopsnapshot
sudo chmod +x hop
sudo printf '\n\n#Added By hop_runner\nexport PATH="/usr/local/hop":$PATH' >> ~/.bash_profile
. ~/.bash_profile
cd ~
hop echo
```

# Example Pub Tasks
## Dart Version Task
Determines whether your installed version is up-to-date with sdk version.
```bash
$ hop version [--channel [dev | stable]]
```

## Update Dart
Update dart sdk.
```bash
$ hop update [--channel [dev | stable]]
```

## Schedule Task
Schedule a pub task.
```bash
$ hop sched --every <n>[m|h|d], <task-lib> [<args>]
```

## Spawn Template
Spawn a project based on given template.
```bash
$ hop web-app-startr --name foo
```

# Create A Pub Task

## Create From Scratch
See wiki for how to create a pub task from scratch.

## Spawn Pub Task Template
Span a pub task from a template
```bash
$ hop pub-task-startr --name <pub-task-name>
```
