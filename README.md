# Setup opensshd and seperate onion service

Features:
 - [x] Not leaking your default sshd host keys, reducing the possibility of deanymizing you
 - [x] Warns you of missing dependencies (systemd, tor, openssh-server)
 - [x] Setups a hidden (aka onion) service and point it to your openssh port
 - [x] Starts it automatically
 - [x] Shows you public key fingerprint
 - [x] Script can be run multiple times, without overriding/changing existing files
 - [ ] Secure ssh config # FIXME, config needs review

Usage:

```
git clone https://github.com/norpol/opensshd-tor-easy-setup
sudo ./opensshd-tor-easy-setup/setup_tor_ssh.sh install
```

More:
```
setup_tor_ssh.sh help
setup_tor_ssh.sh uninstall
setup_tor_ssh.sh purge
```

Note:
 - It's recommended using a seperate tor-ssh user for your tor connection. See `sshd_config`
 - [How to connect to a hidden service](https://trac.torproject.org/projects/tor/wiki/doc/TorifyHOWTO/ssh)
