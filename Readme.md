# Clover

🍀 a configurable theme for [zsh], inspired by [zeta-zsh-theme] and [pure].

![screenshot](./screenshot.png)

[zsh]: https://en.wikipedia.org/wiki/Z_shell
[zeta-zsh-theme]: https://github.com/skylerlee/zeta-zsh-theme
[pure]: https://github.com/sindresorhus/pure


## Feature

- User name
- Machine name
    - change color on remote session
- Current working directory
- Git
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
        * `⇕` — diverged chages
    - works async
- Last execution time
- Current time
- Python virtual environment name
- Prompt indicator changes if the last run fails (🍀/🔥)
- Symbols and colours are configurable, see `clover.zsh-theme`.


## Environment

This script is tested on zsh 5.0.2.


## Installation

#### use with oh-my-zsh

```sh
cd ${ZSH_CUSTOM:-"~/.oh-my-zsh/custom"}/themes
git clone git@github.com:tzing/clover.zsh-theme.git clover
```

then change the theme to Clover.

```zsh
ZSH_THEME="clover/clover"
```

✨🍰✨


#### manually

Clone this repo to somewhere you like.

```sh
git clone git@github.com:tzing/clover.zsh-theme.git <PATH>
```

and source this theme in your `.zshrc`

```zsh
source <PATH>/clover.zsh-theme
```

✨🍰✨
