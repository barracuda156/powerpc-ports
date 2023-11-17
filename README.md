# MacPorts Ports

This is an experimental branch using libstdc++ and gcc on Sonoma. Multiple ports are broken at the moment, since no one ever tested this.
For instance, limits.h does not get found for a reason yet unknown. Also some SDK features are not recognized, like CoreText: https://trac.macports.org/ticket/68714
This is a WIP. Use at your own risk.

## What software is available

See: <https://ports.macports.org/>

Or: `port search <somename>`

## How to install ports

Install MacPorts: <https://www.macports.org/install.php>

In Terminal, enter `sudo port install <someport>`

## Diagnosing Problems

Try `sudo port diagnose`

Check the [Problem Hotlist](https://trac.macports.org/wiki/ProblemHotlist) and
[FAQ](https://trac.macports.org/wiki/FAQ) to see if your problem is mentioned, and
[search Trac](https://trac.macports.org/search?q=&portsummarysearch=on) to see if there are
any open tickets.

Get further help on our mailing list or via IRC: <https://www.macports.org/contact.php>

## Documentation

See `man port`

Official documentation:  <https://guide.macports.org/>
