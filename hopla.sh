#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -r this_script=$(perl -e 'use Cwd "abs_path"; print abs_path(shift)' "$0")
declare -xgr script_dirname=$(dirname "${this_script}")
declare -xgr library_dir="$(realpath "${script_dirname}/library/")"

source "${library_dir}/api_proxy.sh"
source "${library_dir}/logging.sh"
source "${library_dir}/load_config.sh"
source "${library_dir}/load_auth.sh"

declare -i global_option_help=0
declare -a args_without_globals=()
parse_global_options() {
  debug "parse_global_options"
  for argument in "$@"; do
    case "${argument}" in
      # just set a variable, don't change other options
      "--help"|"-h")     global_option_help=1 ;;
      # don't change other options and parameters
      *)                 args_without_globals+=("${argument}")   ;;
    esac
  done
}

show_help() {
  # strip off .sh or .py with /.*
  declare help_file="${1/.*}.help"

  # couldn't find help
  if [[ ! -f "${help_file}" ]]  ; then declare help_file="${script_dirname}/hopla.help" ; fi

  debug "show_help: help_file=${help_file}"
  cat "${help_file}"
  exit 0
}

find_executable_subcmd(){
  supposed_cmd="$1"
  debug "find_script supposed_cmd=$1"

  declare -r python_cmd="${supposed_cmd}.py"
  declare -r shell_cmd="${supposed_cmd}.sh"

  if   [[ -n "${python_cmd}"   && -x "${python_cmd}" ]]   ; then echo "${python_cmd}"
  elif [[ -n "${shell_cmd}"    && -x "${shell_cmd}" ]]    ; then echo "${shell_cmd}"
  elif [[ -n "${supposed_cmd}" && -x "${supposed_cmd}" ]] ; then echo "${supposed_cmd}"
  fi
}

declare command_file="${script_dirname}/hopla"
declare -a subcmd_arguments=()
assign_subcmd_and_arguments() {
  debug "assign_subcmd_and_arguments"
  for argument in "${args_without_globals[@]}" ; do
    declare possible_cmd="${command_file}/${argument}"
    # TODO: this should be made file type agnostic
    if [[ -e "${possible_cmd}" || -e "${possible_cmd}.py" || -e "${possible_cmd}.sh" ]] ; then
      command_file+="/${argument}"
    else
      subcmd_arguments+=("${argument}")
    fi
  done

  if [[ -d "${command_file}" ]] ; then
    # User didn't finish with full command, they probably want help:
    show_help "${command_file}"
  fi

  command_file="$(find_executable_subcmd "${command_file}")"

  if [[ -z "${command_file}" ]] ; then
    echo "could not find the following command: ${command_file}"
  elif [[ ! -x "${command_file}" ]] ; then
    # User didn't finish with full command, they probably want help:
    echo "could find, but not execute the following command: ${command_file}"
  fi
}

handle_global_options() {
  if (( global_option_help )) ; then
    show_help "${command_file}"
  fi
}


main () {
  parse_global_options "$@"
  assign_subcmd_and_arguments
  handle_global_options

  "${script_dirname}/hopla.py" "${command_file}" "${subcmd_arguments[@]}"
}
main "$@"


