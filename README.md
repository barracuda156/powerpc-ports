# MacPorts Ports

This branch of MacPorts repo has fixes specific for macOS 10.6 PowerPC (10A190).
While most of these are compatible with 10.5.8 and 10.6.8 Rosetta, only 10.6 PPC is supported here.

There is no implication of all broken ports to be fixed, however this is intended to be a fully-functional set-up.

NOTE: The following ports, if needed, should presently be installed as -devel subports:
`eigen-devel`  (non-devel version has broken AltiVec module);
`kokkos-devel` (non-devel version has no support for 32-bit platforms);
`libass-devel` (non-devel version lacks necessary fixes for PowerPC).

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

IMPORTANT: this repo is unrelated to Macports upstream;
please do not report on Macports Trac any possible issues with the this code.

Any bugs and questions related to macOS PowerPC and ports in this repo
can be discussed here: https://github.com/barracuda156/macports-ports/discussions
It would be helpful to know if something fails for you on 10.6 PPC,
and I will try to address such issues. 10.5.8 is not actively supported,
but that can be discussed. (Sorry, no 10.4.)

## Documentation

See `man port`

Official documentation:  <https://guide.macports.org/>
