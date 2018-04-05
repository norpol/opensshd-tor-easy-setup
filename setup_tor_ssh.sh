#!/bin/sh
# setup a hidden (aka onion) service and point it to SSH
# can be run multiple times, doesn't override files or configs when run multiple times
pidof systemd >/dev/null || { echo "no systemd detected"; exit 1; }
tor -h >/dev/null || { echo "no tor detected"; exit 1; }
sshd --help 2>&1 | grep -qs OpenSSH || { echo "No OpenSSH detected"; exit 1; }

create() {
  content="${1}"
  file="${2}"
  
  if ! grep -qs "${content}" "${file}" 2>/dev/null; then
    echo "${file}"
    printf '%s' "${content}" | tee -a "${file}"
  else
    echo "${content} in ${file} exists"
  fi
}

create "HiddenServiceDir /var/lib/tor/ssh_hidden_service/" /etc/tor/torrc
create "HiddenServicePort 22 127.0.1.7:22" /etc/tor/torrc

mkdir -vp "/etc/systemd/system"
cp -n ssh-tor.service "/etc/systemd/system/"

mkdir -vp "/etc/ssh_tor"
cp -n sshd_config "/etc/ssh_tor/"

# Note: I'm not sure if you are supposed generating keys like this,
# but it's the common way referred
[ -f "/etc/ssh_tor/ssh_host_ed25519_key" ] || ssh-keygen -N "" -t ed25519 -f /etc/ssh_tor/ssh_host_ed25519_key

systemctl daemon-reload
systemctl restart tor
systemctl restart ssh-tor
systemctl enable ssh-tor
ssh-keyscan 127.0.1.7 -p 22
echo "Success"