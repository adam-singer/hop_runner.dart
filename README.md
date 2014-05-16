hop_runner.dart
===============
Hop_runner.dart is a CLI runtime for distributable reusable tasks for [Dart](https://www.dartlang.org) based on [Hop](https://github.com/dart-lang/hop).

### Usage

#### Basic Usage
Call a pub package designed to run from the [hop_runner](https://github.com/toolr/hop_runner.dart) commandline.
    
    ```bash
    $ hop [<hop-options>] <pub-package-task-library> [<args>]
    ```

    #### Chained Usage
    You can also pipe task calls.
    ```bash
    $ hop <pub-task1> | <pub-task2> | <pub-task3> | ... | <pub-taskn>
    ```

### Install
Simply copy and paste this into your terminal.
    ```bash
    $ ...[to be determined]
    ```

### Example Pub Tasks
#### Dart Version Task
Determines whether your installed version is up-to-date with sdk version.
    ```bash
    $ hop version [--channel [dev | stable]]
    ```

#### Update Dart
Update dart sdk.
    ```bash
    $ hop update [--channel [dev | stable]]
    ```

#### Schedule Task
Schedule a pub task.
    ```bash
    $ hop sched --every <n>[m|h|d] | <pub-task>
    ```

#### Spawn Template
Spawn a project based on given template.
    ```bash
    $ hop web-app-startr --name foo
    ```

### Create A Pub Task

#### Create From Scratch
See wiki for how to create a pub task from scratch.

#### Spawn Pub Task Template
Span a pub task from a template
    ```bash
    $ hop pub-task-startr --name <pub-task-name>
    ```
