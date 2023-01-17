#! /usr/bin/env zsh
# Clover 🍀
# - a configurable theme for zsh
#
# MIT license 2023 tzing

typeset -gA prompt_clover_styles prompt_clover_symbols prompt_clover_params
prompt_clover_styles=(
	current-time            '%F{blue}'
	execution-time          '%F{242}'
	host:default            '%B%F{cyan}'
	host:container          '%B%F{white}%K{magenta}'
	host:remote             '%B%F{white}%K{blue}'
	path                    '%B%F{yellow}'
	prompt:default          '%F{green}'
	prompt:fail             '%F{red}'
	symbol:prefix           '%F{blue}'
	user:default            '%B%F{green}'
	user:root               '%B%F{white}%K{red}'
	vcs:action              '%F{red}'
	vcs:branch              '%B%F{blue}'
	vcs:status:ahead        '%F{cyan}'
	vcs:status:behind       '%F{magenta}'
	vcs:status:clean        '%F{green}'
	vcs:status:diverge      '%F{red}'
	vcs:status:staged       '%F{green}'
	vcs:status:unstaged     '%F{magenta}'
	vcs:status:untracked    '%F{242}'
	virtualenv              '%F{242}'
)

prompt_clover_symbols=(
	current-time:prefix     '('
	current-time:suffix     ')'
	host:prefix             '@'
	path:prefix             ': '
	prompt:default          '%2{🍀%} '
	prompt:fail             '%2{🔥%} '
	user:prefix             '#  '
	vcs:prefix              ' <'
	vcs:status:ahead        '⇡'
	vcs:status:behind       '⇣'
	vcs:status:clean        '✔'
	vcs:status:diverge      '⇕'
	vcs:status:staged       '≡'
	vcs:status:unstaged     '✱'
	vcs:status:untracked    '?'
	vcs:suffix              '>'
	venv:prefix             '('
	venv:suffix             ') '
)

prompt_clover_params=(
	basedir                 "${0:A:h}"
	date-format             '%H:%M:%S %z'
	min-exec-display-sec    '5'
	reset                   '%b%u%f%k'
	zstyle-prefix           ':prompt:clover:'
)

prompt_clover:setup() {
	autoload -U add-zsh-hook
	autoload -U vcs_info

	# vendoring
	fpath+=("${prompt_clover_params[basedir]}")
	autoload -Uz async && async

	# hooks
	add-zsh-hook precmd prompt_clover:precmd
	add-zsh-hook preexec prompt_clover:preexec

	# some env setup
	if [[ -z $prompt_newline ]]; then
		typeset -g prompt_newline=$'\n%{\r%}'
	fi

	export PROMPT_EOL_MARK=''
	export VIRTUAL_ENV_DISABLE_PROMPT=1
	export CONDA_CHANGEPS1=no
}

prompt_clover:precmd() {
	local exit_code=$?

	# init async
	if [[ -z "${prompt_clover_params[async-init]}" ]]; then
		async_start_worker prompt_clover_vcs -n
		async_register_callback prompt_clover_vcs prompt_clover:render-prompt
		prompt_clover_params[async-init]='true'
	fi

	# reset background job
	async_flush_jobs prompt_clover_vcs

	# flags
	local flag
	if prompt_clover:helper:check-style-changed main; then
		# rebuild prompt template on style changed
		flag+='-rebuild '
	fi
	if [[ -n ${prompt_clover_params[lastcmd]} ]]; then
		# calculate execution time when last command is not empty
		prompt_clover_params[lastcmd]=
		flag+='-exec-time '
	fi

	# build
	prompt_clover:build-lprompt0 "$flag"
	prompt_clover:build-lprompt1 "$exit_code" "$flag"
	prompt_clover:build-rprompt "$flag"

	# check vcs info
	prompt_clover_params[prompt-vcs-info]=

	async_worker_eval prompt_clover_vcs builtin cd -q "$PWD"
	async_job prompt_clover_vcs prompt_clover:build-vcs-info

	# draw
	prompt_clover:render-prompt precmd
}

prompt_clover:preexec() {
	# preexec is not called on empty command, so this var will not set to empty
	prompt_clover_params[lastcmd]="$1"
	(( prompt_clover_params[lastcmd-start-epoch] = $EPOCHSECONDS ))
}

prompt_clover:render-prompt() {
	# NOTE: this is a shared callback for precmd and async tasks
	local job="$1" output="$3"

	# save output
	if [[ "x$job" == 'xprompt_clover:build-vcs-info' ]]; then
		prompt_clover_params[prompt-vcs-info]="$output"
	fi

	# get templates
	local lprompt0="${prompt_clover_params[lprompt0]}${prompt_clover_params[prompt-vcs-info]}"
	local lprompt1="${prompt_clover_params[lprompt1]}"
	local rprompt="${prompt_clover_params[rprompt]}"

	# calculate prompt size
	prompt_clover:helper:strlen "$lprompt0" 'prompt_clover_params[lwidth]'
	prompt_clover:helper:strlen "$rprompt" 'prompt_clover_params[rwidth]'

	# calculate space between left prompt and right prompt
	local n_space space
	(( n_space = $COLUMNS -1 -${prompt_clover_params[lwidth]} -${prompt_clover_params[rwidth]} ))
	(( $n_space >= 0 )) && space=$(builtin printf "%${n_space}s")

	# render
	local -a components
	components=(
		"$lprompt0"
		"$space"
		"$rprompt"
		"$prompt_newline"
		"$lprompt1"
	)
	local ps="${(j..)components}"
	if [[ "x$job" == 'xprecmd' ]] || [[ "x$ps" != "x${prompt_clover_params[last-prompt]}" ]]; then
		typeset -g PROMPT="$ps"
		zle && zle .reset-prompt
		prompt_clover_params[last-prompt]="$ps"
	fi
}

prompt_clover:build-lprompt0() {
	local flag="$1"

	# use cache
	[[ ! "x$flag" =~ '-rebuild ' ]] \
	&& [[ -n "${prompt_clover_params[lprompt0]}" ]] \
	&& return

	# changes style for root user
	local user_style
	if [[ $UID -eq 0 ]]; then
		user_style="${prompt_clover_styles[user:root]}"
	else
		user_style="${prompt_clover_styles[user:default]}"
	fi

	# change style for non-local host
	local host_style
	if prompt_clover:helper:is-inside-container; then
		host_style="${prompt_clover_styles[host:container]}"
	elif [[ -n "$SSH_CONNECTION" ]]; then
		host_style="${prompt_clover_styles[host:remote]}"
	else
		host_style="${prompt_clover_styles[host:default]}"
	fi

	# build
	local -a components
	components=(
		# `#` symbol before user
		"${prompt_clover_styles[symbol:prefix]}"
		"${prompt_clover_symbols[user:prefix]}"
		"${prompt_clover_params[reset]}"

		# user
		"$user_style"
		'%n'
		"${prompt_clover_params[reset]}"

		# `@` symbol before host
		"${prompt_clover_styles[symbol:prefix]}"
		"${prompt_clover_symbols[host:prefix]}"
		"${prompt_clover_params[reset]}"

		# host
		"$host_style"
		'%m'
		"${prompt_clover_params[reset]}"

		# `:` symbol before path
		"${prompt_clover_styles[symbol:prefix]}"
		"${prompt_clover_symbols[path:prefix]}"
		"${prompt_clover_params[reset]}"

		# path
		"${prompt_clover_styles[path]}"
		'%~'
		"${prompt_clover_params[reset]}"
	)

	prompt_clover_params[lprompt0]="${(j..)components}"
}

prompt_clover:build-lprompt1() {
	local exit_code="$1" flag="$2"
	local -a components

	# venv
	if prompt_clover:python:get-virtualenv-name; then
		# build
		if [[ "x$flag" =~ '-rebuild ' ]] || [[ -z "${prompt_clover_params[venv:prompt]}" ]]; then
			local -a venv_components
			venv_components=(
				"${prompt_clover_styles[virtualenv]}"
				"${prompt_clover_symbols[venv:prefix]}"
				"${prompt_clover_params[venv:name]}"
				"${prompt_clover_symbols[venv:suffix]}"
				"${prompt_clover_params[reset]}"
			)
			prompt_clover_params[venv:prompt]="${(j..)venv_components}"
		fi

		# append
		components+=("${prompt_clover_params[venv:prompt]}")
	fi

	# prompt
	if (( ! $exit_code )); then
		components+=(
			"${prompt_clover_styles[prompt:default]}"
			"${prompt_clover_symbols[prompt:default]}"
			"${prompt_clover_params[reset]}"
		)
	else
		components+=(
			"${prompt_clover_styles[prompt:fail]}"
			"${prompt_clover_symbols[prompt:fail]}"
			"${prompt_clover_params[reset]}"
		)
	fi

	prompt_clover_params[lprompt1]="${(j..)components}"
}

prompt_clover:build-rprompt() {
	local flag="$1"
	local -a components

	# execution time
	if [[ "x$flag" =~ '-exec-time ' ]]; then
		local execution_time
		(( execution_time = $EPOCHSECONDS - ${prompt_clover_params[lastcmd-start-epoch]:-EPOCHSECONDS} ))
		if (( $execution_time > ${prompt_clover_params[min-exec-display-sec]} )); then
			prompt_clover:helper:to-readable-time "$execution_time" 'prompt_clover_params[execution-time]'
			components+=(
				"${prompt_clover_styles[execution-time]}"
				"${prompt_clover_params[execution-time]}"
				"${prompt_clover_params[reset]}"
				' '
			)
		fi
	fi

	# time
	components+=(
		"${prompt_clover_styles[current-time]}"
		"${prompt_clover_symbols[current-time:prefix]}"
		"%D{${prompt_clover_params[date-format]}}"
		"${prompt_clover_symbols[current-time:suffix]}"
		"${prompt_clover_params[reset]}"
	)

	prompt_clover_params[rprompt]="${(j..)components}"
}

prompt_clover:build-vcs-info() {
	# configs
	if [[ -z "${prompt_clover_params[vcs-init]}" ]]; then
		zstyle ':vcs_info:*' max-exports 4
		zstyle ':vcs_info:*' check-for-changes 'true'
		zstyle ':vcs_info:*' stagedstr 'staged'
		zstyle ':vcs_info:*' unstagedstr 'unstaged'

		# exports branch(%b), vcs type(%s), staged changes(%u), unstaged changes(%c) and action(%a)
		zstyle ':vcs_info:git*' formats '%b' '%s' '%u %c'
		zstyle ':vcs_info:git*' actionformats '%b' '%s' '' '%a'

		prompt_clover_params[vcs-init]='true'
	fi

	prompt_clover:helper:check-style-changed vcs

	# get vcs info
	vcs_info

	local branch vcs_type changes action
	branch="$vcs_info_msg_0_"
	vcs_type="$vcs_info_msg_1_"
	changes="$vcs_info_msg_2_"
	action="$vcs_info_msg_3_"

	# don't return vcs message when it is not in a repo
	[[ -z "${vcs_type}" ]] && return

	# perform extra checks when supported
	local vcs_status_str
	if [[ -n "$action" ]]; then
		# action - don't show status
		vcs_status_str="${prompt_clover_styles[vcs:action]}"
		vcs_status_str+="$action"
		vcs_status_str+="${prompt_clover_params[reset]}"
	else
		# normal mode
		# run extra check on git
		if [[ "x$vcs_type" == 'xgit' ]]; then
			changes+=" $(prompt_clover:vcs:git-status)"
		fi

		# collect state
		local -A vcs_status
		for st in ${(z)changes}; do
			vcs_status[$st]=1
		done

		# build status str in constant order
		local -a const_status_order
		const_status_order=(clean unstaged staged untracked ahead behind diverge)

		for name in $const_status_order; do
			if [[ -z "${vcs_status[$name]}" ]]; then
				continue
			fi
			vcs_status_str+="${prompt_clover_styles[vcs:status:$name]}"
			vcs_status_str+="${prompt_clover_symbols[vcs:status:$name]}"
			vcs_status_str+="${prompt_clover_params[reset]}"
		done
	fi

	# build output
	local components
	components=(
		# prefix
		"${prompt_clover_styles[vcs:prefix]}"
		"${prompt_clover_symbols[vcs:prefix]}"
		"${prompt_clover_params[reset]}"

		# branch
		"${prompt_clover_styles[vcs:branch]}"
		"$branch"
		"${prompt_clover_params[reset]}"
	)

	[[ -n "$vcs_status_str" ]] && components+=(" $vcs_status_str")

	components+=(
		# suffix
		"${prompt_clover_styles[vcs:suffix]}"
		"${prompt_clover_symbols[vcs:suffix]}"
		"${prompt_clover_params[reset]}"
	)

	echo "${(j..)components}"
}

prompt_clover:helper:check-style-changed() {
	local scope="$1" flag=1 key value

	# internal helper function to read config from `zstyle`
	__u() {
		local context="$1" style="$2" value="$3" output="$4"

		# switch scope - vcs context are process in forked process
		case "x$scope" in
			x'main')	[[ "x$context" == 'xvcs:'* ]] && return;;
			x'vcs')		[[ "x$context" != 'xvcs:'* ]] && return;;
		esac

		# check zstyle
		zstyle -t "${prompt_clover_params[zstyle-prefix]}$context" "$style" "$value"
		if [[ $? == 1 ]]; then
			# code 1 - zstyle is set
			zstyle -s "${prompt_clover_params[zstyle-prefix]}$context" "$style" "$output"
			return 0
		fi
		return 1
	}

	# styles
	for key value in ${(@kv)prompt_clover_styles}; do
		if __u "$key" style "$value" "prompt_clover_styles[$key]"; then
			flag=0
		fi
	done

	# symbols
	for key value in ${(@kv)prompt_clover_symbols}; do
		if __u "$key" symbol "$value" "prompt_clover_symbols[$key]"; then
			flag=0
		fi
	done

	# others
	if __u 'current-time' format "${prompt_clover_params[date-format]}" 'prompt_clover_params[date-format]'; then
		flag=0
	fi

	__u 'execution-time' min-display-second "${prompt_clover_params[min-exec-display-sec]}" 'prompt_clover_params[min-exec-display-sec]'

	unset -f __u
	return $flag
}

prompt_clover:helper:strlen() {
	local input="$1" output="$2"
	# https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
	local stripped=$(command -p sed 's/\x1b\[[0-9;]*[mGKHF]//g' <<< "${(%)input}")
	typeset -g "$output=${#stripped}"
}

prompt_clover:helper:is-inside-container() {
	local -r cgroup_file='/proc/1/cgroup'
	local -r nspawn_file='/run/host/container-manager'
	false \
	|| [[ -f '/.dockerenv' ]] \
	|| [[ -r "$cgroup_file" && "$(< $cgroup_file)" = *(lxc|docker)* ]] \
	|| [[ "x$container" == 'xlxc' ]] \
	|| [[ -r "$nspawn_file" ]]
}

prompt_clover:helper:to-readable-time() {
	local total_seconds="$1" output="$2"
	local days hours minutes seconds human
	(( days = total_seconds / 86400 ))
	(( hours = total_seconds / 3600 % 24 ))
	(( minutes = total_seconds / 60 % 60 ))
	(( seconds = total_seconds % 60 ))

	(( days > 0 )) && human+="${days}d "
	(( hours > 0 )) && human+="${hours}h "
	(( minutes > 0 )) && human+="${minutes}m "
	human+="${seconds}s"

	typeset -g "$output=$human"
}

prompt_clover:python:get-virtualenv-name() {
	# virtualenv & venv
	if [[ -n "$VIRTUAL_ENV" ]]; then
		# find the name defined by the user (`--prompt`)
		local virtual_env_prompt=$(
			command -p grep 'VIRTUAL_ENV_PROMPT=' "$VIRTUAL_ENV/bin/activate" \
			| command -p grep -oE '\(.+\)'
		)
		if [[ -n "$virtual_env_prompt" ]]; then
			# successfully find. use this value
			prompt_clover_params[venv:name]="${virtual_env_prompt:1:-1}"
		else
			# default: show dir name
			prompt_clover_params[venv:name]="${VIRTUAL_ENV:t}"
		fi
		return 0
	fi

	# conda
	if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
		prompt_clover_params[venv:name]="${CONDA_DEFAULT_ENV//[$'\t\r\n']}"
		return 0
	fi

	# not found
	return 1
}

prompt_clover:vcs:git-status() {
	__git() {
		GIT_OPTIONAL_LOCKS=0 command -p git "$@" 2> /dev/null
	}

	# compare with remote branch
	# note: we don't do fetch
	local remote_branch=$(__git rev-parse --abbrev-ref --symbolic-full-name @{u} | head -1)
	if [[ -n "$remote_branch" ]]; then
		local is_ahead=0 is_behind=0
		[[ -n $(__git rev-list $remote_branch..HEAD) ]] && is_ahead=1
		[[ -n $(__git rev-list HEAD..$remote_branch) ]] && is_behind=1
		if [[ $is_ahead == 1 ]] && [[ $is_behind == 1 ]]; then
			builtin echo 'diverge'
		elif [[ $is_ahead == 1 ]]; then
			builtin echo 'ahead'
		elif [[ $is_behind == 1 ]]; then
			builtin echo 'behind'
		fi
	fi

	# read git stauts for clean and untracked files
	local untracked_git_mode=$(__git config --get status.showUntrackedFiles)
	if [[ "$untracked_git_mode" != 'no' ]]; then
		untracked_git_mode='normal'
	fi

	local status_text=$(__git status --porcelain --untracked-files=${untracked_git_mode})
	if [[ -z "$status_text" ]]; then
		# `git status` no output - work tree clean
		builtin echo 'clean'
	else
		# find untracked items. tracked items are covered by vcs_info.
		local untracked_text=$(command -p grep --max-count=1 --extended-regexp '^\?\? ' <<< $status_text)
		[[ -n $untracked_text ]] && builtin echo 'untracked'
	fi

	unset -f __git
}

prompt_clover:setup
