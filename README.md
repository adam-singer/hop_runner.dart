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
   -t, --type: [pub (default), hosted, git, path]
   -n, --name: Repository name.
```

## Chained Usage
You can also chain task calls separated by comma.
```bash
$ hop [<hop-options>] <task-lib> [<args>], <task-lib> [<args>], ...
```

## Autocompletion
Not currently implemented.  See [#5](https://github.com/toolr/hop_runner.dart/issues/5).

# Install
Simply copy and paste this into your terminal.  See [#4](https://github.com/toolr/hop_runner.dart/issues/4)
```bash
$ ...[to be determined]
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
