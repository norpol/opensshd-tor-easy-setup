#!/bin/sh
# setup a hidden (aka onion) service and point it to SSH
# can be run multiple times, doesn't override files or configs when run multiple times
# Note: It's recommended using a seperate user.
set -ue

SCRIPT_NAME="${0}"
SCRIPT_DIR="${SCRIPT_NAME%/*}"

_stderr() {
   echo "${*}" 2>&1
}

_log_cmd() {
   _stderr "$ ${*}"
   eval "${*}"
}

_err() {
   _stderr "Error: $*"
}

_err_exit() {
   _err "$*"
   exit 1
}

_check_deps() {
   grep -qs '^systemd$' /proc/1/comm || _err_exit "Couldn't detect systemd"
   tor -h >/dev/null || _err_exit "Couldnt' detect tor"
   sshd --help 2>&1 | grep -qs OpenSSH || _err_exit "Couldn't detect OpenSSH daemon"
   which which 2>&1 >/dev/null || _err_exit "Couldn't detect which"
}

_mktee() {
  file="${1}"
  content="${2}"

  if ! grep -qs "${content}" "${file}" 2>/dev/null; then
    printf '%s' "Append to ${file}: "
    printf '%s\n' "${content}" | tee -a "${file}"
  else
    _stderr "${content} in ${file} exists"
  fi
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
   sed "s%SSHD_PATH%$(which sshd)%g" ssh-tor.service > \
	   "/etc/systemd/system/ssh-tor.service"
   _mkcp sshd_config "/etc/ssh_tor/"

   # Note: I'm not sure if you are supposed generating keys like this,
   # but it's the common way referred
   [ -f "/etc/ssh_tor/ssh_host_ed25519_key" ] || \
      ssh-keygen -N "" -t ed25519 -f /etc/ssh_tor/ssh_host_ed25519_key
   _log_cmd systemctl daemon-reload
   _log_cmd systemctl restart tor
   _log_cmd systemctl restart ssh-tor
   _log_cmd systemctl enable ssh-tor
   fingerprint="$(ssh-keyscan -p 22 -t "ed25519" 127.0.1.7 2>/dev/null)"
   # TODO Fix Workaround for
   # https://github.com/norpol/opensshd-tor-easy-setup/issues/4
   while ! [ -f /var/lib/tor/ssh_hidden_service/hostname ]; do
      _stderr "Waiting for hostname being generated"
      sleep 1s
   done
   onion_addr="$(cat /var/lib/tor/ssh_hidden_service/hostname)"
   # logging into _stderr in order to make output easier parsable
   _stderr "Success; Now you can proceed with https://trac.torproject.org/projects/tor/wiki/doc/TorifyHOWTO/ssh"
   _stderr "You can add this to your known-hosts:"
   echo "${onion_addr} ${fingerprint#* }"
}

_uninstall() {
   systemctl stop ssh-tor 2>/dev/null || true
   systemctl disable ssh-tor 2>/dev/null || true
   rm -fv /etc/systemd/system/ssh-tor.service
   systemctl daemon-reload
   rm -fv /etc/ssh_tor/sshd_config
   sed -i "/HiddenServiceDir \\/var\\/lib\\/tor\\/ssh_hidden_service/d" /etc/tor/torrc
   sed -i "/HiddenServicePort 22 127.0.1.7:22/d" /etc/tor/torrc
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

# Set environment variable to EVAL=1 in case you want to source seperate functions
[ "${EVAL:-0}" = "1" ] || _main "${1:-}"
