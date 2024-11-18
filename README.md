# PowerPC Ports

This fork of MacPorts repo has fixes specific for macOS 10.6 PowerPC (10A190).
While most of these are compatible with 10.5.8 and 10.6.8 Rosetta, only 10.6 PPC is supported here.

There is no implication of all broken ports to be fixed, however this is intended to be a fully-functional set-up.

## What software is available

See: <https://ports.macports.org/>

Or: `port search <somename>`

Available pre-built ports for 10.6 PPC: <http://macos-powerpc.org/packages/>

## How to install ports

Install MacPorts: <https://www.macports.org/install.php>

For 10.6 PPC: install [bootstrap curl](http://macos-powerpc.org/MacPorts/bootstrap_curl.zip)
and then MacPorts from [MacOS-PowerPC](http://macos-powerpc.org/MacPorts/MacPorts-2.10.4.pkg.zip).
Alternatively, you could try building from source from <https://github.com/barracuda156/macports-base-10A190>

In Terminal, enter `sudo port install <someport>`

NOTE: The following ports, if needed, should presently be installed as -devel subports:
`eigen-devel`  (non-devel version has broken AltiVec module);
`emacs-devel`  (non-devel version fails to build).
Some ports have dedicated versions for legacy macOS or PowerPC in MacPorts upstream.
At the moment, they are preserved here under the same names (i.e. `openjdk8-powerpc`, `mpv-legacy` etc.).

## For developers

1. This repo does not preserve commit history, since it keeps being rebased against upstream
with local fixes added on top. To see the history of PowerPC-specific changes,
please refer to <https://github.com/macos-powerpc/powerpc-ports>.

2. It is advised not to use any other branch here besides the default (Snow-PowerPC) one.

3. Contribution is very welcome; please open PRs to <https://github.com/macos-powerpc/powerpc-ports>.

## Diagnosing Problems

Try `sudo port diagnose`

Check the [Problem Hotlist](https://trac.macports.org/wiki/ProblemHotlist) and
[FAQ](https://trac.macports.org/wiki/FAQ) to see if your problem is mentioned, and
[search Trac](https://trac.macports.org/search?q=&portsummarysearch=on) to see if there are
any open tickets.

This fork is unrelated to Macports upstream; please do not report on Macports Trac any related issues.

Any bugs and questions related to macOS PowerPC and ports in this repo
can be discussed here: https://github.com/barracuda156/powerpc-ports/discussions
It would be helpful to know if something fails for you on 10.6 PPC,
and I will try to address such issues. 10.5.8 is not actively supported,
but that can be discussed. (Sorry, no 10.4.)

## Documentation

See `man port`

Official documentation:  <https://guide.macports.org/>
