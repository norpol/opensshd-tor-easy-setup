#!/usr/bin/env python3
import sh
import argparse

def main():
    ''' get args, launch seperate stages '''
    parser = argparse.ArgumentParser()
    parser.addArgument('install', action='store_true')
    parser.addArgument('uninstall', action='store_true')
    parser.addArgument('purge', action='store_true')

    args = parser.parse_args()

    pass




systemctl = sh.systemctl()


def mktee(content, target):
    pass

def cp(source, target):
    pass

def is_systemd():
    pass

def has_tor():
    pass

def has_sshd():
    pass

def install():
    ''' create confguration and restart services '''
    pass


def uninstall():
    ''' unapply configuration '''
    pass


def purge():
    ''' like uninstall, but also remove generated secrets '''


if __name__ == "__main__":
    main(args)
