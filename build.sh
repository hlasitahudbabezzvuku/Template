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

declare IN="main.c"
declare OUT
declare CC
declare CFLAGS="${CONF_FLAGS[*]}"


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


############
### Main ###
############

main::main ()
{
    printf 'Build template version %s\n' "${CONF_VERSION}"

    declare option

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
                IN="${!i}"
                log::info "Using '${IN}' as input file"
                ;;
            '--out' | '-O')
                _="$(( i++ ))"
                OUT="${!i}"
                log::info "Using '${OUT}' as output file"
                ;;
            '--cc' | '-C')
                _="$(( i++ ))"
                CC="${!i}"
                log::info "Using '${CC}' as compiler command"
                ;;
            '--cflags' | '-F')
                _="$(( i++ ))"
                IFS="," read -ra cflags <<< "${!i}"
                CFLAGS="${cflags[*]}"
                log::info "Using '${CFLAGS[*]}' as compiler flags"
                ;;
            '--cflags-append' | '-A')
                _="$(( i++ ))"
                IFS="," read -ra cflags <<< "${!i}"
                CFLAGS+="${cflags[*]}"
                log::info "Using '${CFLAGS[*]}' as compiler flags"
                ;;
            '--'*)
                option="${!i/'--'}"
                ;;
            *)
                log::error "Unknown option ${!i}"
                ;;
        esac
    done

    if [[ -z "${OUT+set}" ]]; then
        OUT="${IN%\.c}"
    fi

    if [[ -z "${CC+set}" ]]; then
        for compiler in "${CONF_COMPILERS[@]}"; do
            if type -p "${compiler}" &>/dev/null; then
                CC="${compiler}"
                break
            fi
        done
    fi
}

main::main "${@}"

