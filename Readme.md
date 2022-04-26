# Clover

🍀 a configurable theme for [zsh], inspired by [zeta-zsh-theme] and [pure].

![screenshot](./screenshot.png)

[zsh]: https://en.wikipedia.org/wiki/Z_shell
[zeta-zsh-theme]: https://github.com/skylerlee/zeta-zsh-theme
[pure]: https://github.com/sindresorhus/pure


## Features

- User name and hostname changes the color for root user and remote session
- Git status is provided **and work asynchronously**
    - current branch
    - status
        * `✔` — clean branch
        * `✘` — dirty branch
        * `+` — added files
        * `-` — deleted files
        * `*` — modified files
        * `>` — renamed files
        * `=` — unmerged changes
        * `?` — untracked changes
        * `⇡` — ahead of remote branch
        * `⇣` — behind of remote branch
        * `⇕` — diverged changes
- Last execution time for long-run programs
- Python virtual environment name
- Prompt indicator changes whether the last run success (🍀/🔥)
- Symbols and colours are configurable, see [clover.zsh-theme](clover.zsh-theme).


## Environment

This script is tested on zsh 5.0.2.


## Installation

#### [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)

clone this repo into `$ZSH_CUSTOM`:

```bash
cd ${ZSH_CUSTOM:-"~/.oh-my-zsh/custom"}/themes
git clone git@github.com:tzing/clover.zsh-theme.git clover
```

then change the theme:

```zsh
ZSH_THEME="clover/clover"
```

#### [zinit](https://github.com/zdharma-continuum/zinit)

```zsh
zinit light tzing/clover.zsh-theme
```

#### Manual

clone this repo to somewhere you like:

```sh
git clone git@github.com:tzing/clover.zsh-theme.git <PATH>
```

and source the main script in your `.zshrc`

```zsh
source <PATH>/clover.zsh-theme
```
