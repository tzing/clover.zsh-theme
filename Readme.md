# Clover

🍀 a configurable theme for [oh-my-zsh], inspired by [zeta-zsh-theme] and [pure].

![screenshot](./screenshot.png)

[oh-my-zsh]: https://github.com/robbyrussell/oh-my-zsh
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
- Execution time
- Current time
- Python virtualenv
- Prompt indicator changes if the last run fails (🍀/🔥)


## Dependency

- [oh-my-zsh]


## Installition

```sh
cd ${ZSH_CUSTOM:-"~/.oh-my-zsh/custom"}/themes
git clone git@github.com:tzing/clover.zsh-theme.git clover --recursive
```

then change the theme to Clover.

```zsh
ZSH_THEME="clover/clover"
```
