#!/bin/sh
# setup a hidden (aka onion) service and point it to SSH
# can be run multiple times, doesn't override files or configs when run multiple times
# Note: It's recommended using a seperate user.
set -ue

SCRIPT_NAME="${0}"
SCRIPT_DIR="${SCRIPT_NAME%/*}"

_check_deps() {
   grep -qs '^systemd$' /proc/1/comm || { echo "no systemd detected"; exit 1; }
   tor -h >/dev/null || { echo "no tor detected"; exit 1; }
   sshd --help 2>&1 | grep -qs OpenSSH || { echo "No OpenSSH detected"; exit 1; }
}

_mktee() {
  file="${1}"
  content="${2}"

  if ! grep -qs "${content}" "${file}" 2>/dev/null; then
    printf '%s' "Append to ${file}: "
    printf '%s\n' "${content}" | tee -a "${file}"
  else
    echo "${content} in ${file} exists"
  fi
}

_log_cmd() {
   echo "$ ${*}"
   eval "${*}"
}

_mkcp() {
   from="${1}"
   to="${2}"

   mkdir -vp "${to}"
   cp -n "${from}" "${to}"
}

_install() {
   _check_deps
   _mktee /etc/tor/torrc "HiddenServiceDir /var/lib/tor/ssh_hidden_service"
   _mktee /etc/tor/torrc "HiddenServicePort 22 127.0.1.7:22"
   _mkcp ssh-tor.service "/etc/systemd/system/"
   _mkcp sshd_config "/etc/ssh_tor/"

   # Note: I'm not sure if you are supposed generating keys like this,
   # but it's the common way referred
   [ -f "/etc/ssh_tor/ssh_host_ed25519_key" ] || \
      ssh-keygen -N "" -t ed25519 -f /etc/ssh_tor/ssh_host_ed25519_key
   _log_cmd systemctl daemon-reload
   _log_cmd systemctl restart tor
   _log_cmd systemctl restart ssh-tor
   _log_cmd systemctl enable ssh-tor
   ssh-keyscan -p 22 -t "ed25519" 127.0.1.7
   cat /var/lib/tor/ssh_hidden_service/hostname
   echo "Success; Now you can proceed with https://trac.torproject.org/projects/tor/wiki/doc/TorifyHOWTO/ssh"
}

_uninstall() {
   systemctl stop ssh-tor 2>/dev/null || true
   systemctl disable ssh-tor 2>/dev/null || true
   rm -fv /etc/systemd/system/ssh-tor.service
   rm -fv /etc/ssh_tor/sshd_config
   sed -i 's|HiddenServiceDir /var/lib/tor/ssh_hidden_service||g' /etc/tor/torrc
   sed -i 's|HiddenServicePort 22 127.0.1.7:22||g' /etc/tor/torrc
}

_purge() {
   _uninstall
   rm -rfv "/etc/ssh_tor"
   rm -rfv "/var/lib/tor/ssh_hidden_service"
}

_main() {
   cd "${SCRIPT_DIR}"
   case "${1:-}" in
      install) _install
         ;;
      uninstall) _uninstall
         ;;
      purge) _purge
         ;;
      help|-h|--help|-H|*) echo "$0 install|uninstall|purge"; exit 0
   esac
}

# set EVAL=true to source
[ "${EVAL:-0}" = "1" ] || _main "${1:-}"
