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
declare CC

declare -ar COMPILERS=(
    "gcc"
    "clang"
    "g++"
    "clang++"
)


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

    for (( i = 1; i - 1 < "${#}"; i++ )); do
        case "${!i}" in
            '--version' | '-v')
                printf 'Bash version %s\n' "${BASH_VERSINFO[*]}"
                exit 0
                ;;
            '--nocolor')
                declare -g CONF_NOCOLOR="true"
                ;;
            '--help')
                # TODO
                ;;
            *)
                log::error "Unknown option ${!i}"
                ;;
        esac
    done

    if [[ -z ${CC+x} ]]; then
        for compiler in "${COMPILERS[@]}"; do
            if type -p "${compiler}" &>/dev/null; then
                CC="${compiler}"
                break
            fi
        done
    fi
}

main::main "${@}"

