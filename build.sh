#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

if [[ ! "${BASH_VERSINFO[0]}" -ge 5 ]]; then
    printf 'FATAL: This script requires BASH version 5 and later. Your version is "%i"\n' "${BASH_VERSINFO[0]}" 1>&2
    exit 1
fi


##############
### Config ###
##############

declare -r CONF_VERSION="0.1.0"
declare -g CONF_NOCOLOR=false

declare -ra CONF_COMPILERS=(
    "gcc"
    "clang"
    "g++"
    "clang++"
    "cc"
)

declare -ra CONF_FLAGS=(
    "-std=c23"
    "-Wall"
    "-Wextra"
    "-pedantic"
    "-lm"
    "-g"
)

declare -A options=(
    ["clean"]=false
    ["run"]=false
    ["test"]=false
    ["valgrind"]=false
    ["watch"]=false
)

declare -A config=(
    ["in"]="main.c"
    ["out"]=""
    ["cc"]=""
    ["cflagsc"]="${#CONF_FLAGS[@]}"
)

for (( i = 0; i < "${config[cflagsc]}"; i++ )); do
    config[clflags,${i}]="${CONF_FLAGS[${i}]}"
done


###########
### Log ###
###########

log::_color ()
{
    [[ "${CONF_NOCOLOR}" == false ]] && printf '\033[1;3%im' "${1}"
}

log::_reset ()
{
    [[ "${CONF_NOCOLOR}" == false ]] && printf '\033[0m'
}

log::_print ()
{
    printf '[%s%s%s]: %s\n' "$( log::_color "${2}" )" "${1}" "$( log::_reset )" "${3}" 1>&2
}

log::info ()
{
    log::_print "INFO" 4 "${1}"
}

log::warn ()
{
    log::_print "WARNING" 3 "${1}"
}


log::error ()
{
    log::_print "ERROR" 1 "${1}"
    exit 1
}

log::trace ()
{
    printf '[%sTRACE%s]: Printing stack trace:\n' "$( tput setaf 2 )" "$( tput sgr0 )" 1>&2

    for ((i = 0; i < ${#FUNCNAME[@]} - 2; i++)); do
        printf 'Error in function %s at line %s\n' "${FUNCNAME[i + 1]}()" "${BASH_LINENO[i]}" 1>&2
    done

    unset dep
}

#############
### Build ###
#############

build::clean ()
{
    if [[ -f "${config[out]}" ]]; then
        rm "${config[out]}"
    else
        log::info "Nothing to clean"
    fi
}


############
### Main ###
############

main::main ()
{
    printf 'Build template version %s\n' "${CONF_VERSION}"

    for (( i = 1; i - 1 < "${#}"; i++ )); do
        case "${!i}" in
            '--version')
                printf 'Bash version %s\n' "${BASH_VERSINFO[*]}"
                exit 0
                ;;
            '--help')
                # TODO
                ;;
            '--nocolor')
                declare -g CONF_NOCOLOR="true"
                ;;
            '--in' | '-I')
                _="$(( i++ ))"
                config[in]="${!i}"
                log::info "Using '${config[in]}' as input file"
                ;;
            '--out' | '-O')
                _="$(( i++ ))"
                config[out]="${!i}"
                log::info "Using '${config[out]}' as output file"
                ;;
            '--cc' | '-C')
                _="$(( i++ ))"
                config[cc]="${!i}"
                log::info "Using '${config[cc]}' as compiler command"
                ;;
            '--cflags' | '-F')
                _="$(( i++ ))"

                IFS="," read -ra cflags <<< "${!i}"
                config[cflagsc]="${#cflags[@]}"

                for (( j = 0; j < config[cflagsc]; j++ )); do
                    config[clflags,${j}]="${cflags[${j}]}"
                done

                log::info "Using custom CFLAGS"
                ;;
            '--cflags-append' | '-A')
                _="$(( i++ ))"

                IFS="," read -ra cflags <<< "${!i}"

                for (( j = 0; j < ${#cflags[@]}; j++ )); do
                    config[clflags,$(( config[cflagsc] + 1 + j ))]="${cflags[${j}]}"
                done

                config[cflagsc]+="${#cflags[@]}"
                log::info "Appending custom CFLAGS"
                ;;
            '--'*)
                # TODO
                ;;
            *)
                log::error "Unknown command '${!i}'"
                ;;
        esac
    done

    if [[ -z "${config[out]}" ]]; then
        config[out]="${config[in]%\.c}"
    fi

    if [[ -z "${config[cc]}" ]]; then
        for compiler in "${CONF_COMPILERS[@]}"; do
            if type -p "${compiler}" &>/dev/null; then
                config[cc]="${compiler}"
                break
            fi
        done
    fi

    for i in "${!config[@]}"; do
        echo -e "config[$i]:\t${config[$i]}"
    done
}

main::main "${@}"

