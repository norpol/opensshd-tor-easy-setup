#!/bin/sh
set -ue

venv_dir="venv"


create_venv() {
   python3 -m venv "${venv_dir}"
}

source_venv() {
   venv_file="${venv_dir}/bin/activate"
   [ -f "${venv_file}" ]
   # shellcheck disable=SC1090
   printf '. "%s"' "${venv_file}"
}

create_venv
source_venv
