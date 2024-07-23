# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

# This PortGroup is used to indicate that a port builds but does not work correctly.
# It may be crashing on launch, be known to have major bugs or be unusable for a similar reason.
# These ports should not be installed by end-users. They will not work.
# However, if someone is interested to help fixing these, this is greatly appreciated.

options fixme.broken
default fixme.broken yes

proc fixme.broken_port {} {
    global os.platform \
           os.arch \
           fixme.broken
    if {${os.platform} eq "darwin" && ${os.arch} eq "powerpc" && ${fixme.broken}} {
        depends_lib
        depends_run
        archive_sites
        known_fail yes
        pre-fetch {
            ui_error "${name} is known not to work on PowerPC. If you can help fixing it, please remove fixme-1.0 PG from the portfile."
            return -code error {unsupported platform}
        }
    }
}

port::register_callback fixme.broken_port
