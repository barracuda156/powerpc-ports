# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

# Usage:
#
#   1. use ruby.setup and ruby.branches
#
#     PortGroup        ruby 1.0
#     ruby.branches    3.0 2.7
#     ruby.setup       module version type
#     # - adds subport "rb30-module" and "rb27-module"
#
#   2. use ruby.branch
#
#     PortGroup        ruby 1.0
#     ruby.branch      3.0
#     depends_lib      port:ruby${ruby.suffix}
#     build.cmd        ${ruby.bin}

# options:
#   ruby.branches: the ruby versions supported by this module.
#        this introduces subports such as rb30-, rb27-, ...
#   ruby.branch: select ruby version. 3.0, 2.7, ... 2.0, 1.9 or 1.8.
#   ruby.link_binaries: whether generate suffixed symlink under ${prefix}/bin
#        or not.
#   ruby.link_binaries_suffix: suffix of commands from rb-foo under
#        ${prefix}/bin. such as "-3.0" or "-2.7".
# values:
#   ruby.bin, ruby.rdoc, ruby.gem ruby.rake: fullpath to commands for ${ruby.branch}.
#   ruby.suffix: suffix of portname. port:ruby${ruby.suffix} or
#        port:rb${ruby.suffix}-foo.
#   ruby.bindir: install location of commands without suffix from rb-foo.
#   ruby.gemdir: install location of rubygems.
#        such as "${prefix}/lib/ruby3.0/gems/3.0.0".
#   (obsoleted values)
#   ruby.prog_suffix: use ruby.branch.
#   ruby.version: use ruby.api_version.
# values from ruby.setup:
#   ruby.module: port name without prefix. rb-${ruby.module}.
#   ruby.project: project name at rubygems or sourceforge.
#
# note:
#   [gem] use destroot.post_args-append begins "--" to pass options to extconf.rb
#   > ruby.setup module version gem
#   > destroot.post_args-append -- --with-any-option

options ruby.default_branch
default ruby.default_branch 1.8
options ruby.branch ruby.branches
default ruby.branches {}
options ruby.bin ruby.rdoc ruby.gem ruby.rake ruby.bindir ruby.gemdir ruby.suffix
options ruby.api_version ruby.lib ruby.archlib
# ruby.version is obsoleted. use ruby.api_version.
options ruby.version
option_proc ruby.branch ruby_set_branch
proc ruby_set_branch {option action args} {
    if {$action ne "set"} {
        return
    }
    global prefix ruby.branch \
           ruby.bin ruby.rdoc ruby.gem ruby.rake ruby.bindir ruby.gemdir \
           ruby.suffix ruby.prog_suffix ruby.api_version ruby.lib \
           ruby.archlib ruby.arch
    set ruby.bin            ${prefix}/bin/ruby${ruby.branch}
    set ruby.rdoc           ${prefix}/bin/rdoc${ruby.branch}
    set ruby.gem            ${prefix}/bin/gem${ruby.branch}
    set ruby.rake           ${prefix}/bin/rake${ruby.branch}
    set ruby.bindir         ${prefix}/libexec/ruby${ruby.branch}
    # gem, rake command for 1.8 from port:rb-rubygems, port:rb-rake
    if {${ruby.branch} eq "1.8"} {
        set ruby.gem        ${ruby.bindir}/gem
        set ruby.rake       ${ruby.bindir}/rake
    }
    set ruby.suffix         [join [split ${ruby.branch} .] {}]
    if {${ruby.branch} eq "1.8"} {
        set ruby.suffix     ""
    }
    set ruby.prog_suffix    ${ruby.branch}
    if {${ruby.branch} eq "1.8"} {
        set ruby.prog_suffix     ""
    }
    #
    set ruby.api_version ${ruby.branch}.0
    switch -exact ${ruby.branch} {
        1.9 {set ruby.api_version 1.9.1}
        1.8 {set ruby.api_version 1.8}
    }
    set ruby.gemdir         ${prefix}/lib/ruby${ruby.prog_suffix}/gems/${ruby.api_version}
    # define installation libraries as vendor location
    default ruby.lib        {[ruby.extract_config vendorlibdir ${prefix}/lib/ruby${ruby.prog_suffix}/vendor_ruby/${ruby.api_version}]}
    default ruby.archlib    {[ruby.extract_config vendorarchdir ${ruby.lib}/${ruby.arch}]}
    set ruby.version        ${ruby.api_version}
}

proc ruby.extract_config {var {default ""}} {
    global ruby.bin
    if {[catch {set val [exec ${ruby.bin} -e "require 'rbconfig';puts RbConfig::CONFIG\[\"${var}\"\]"]}]} {
        set val ${default}
    }
    return $val
}

options ruby.arch
default ruby.arch           {[ruby.extract_config arch "${os.arch}-${os.platform}${os.major}"]}

set ruby.module         ""
set ruby.filename       ""
set ruby.project        ""
set ruby.docs           {}
set ruby.srcdir         ""
set ruby.prog_suffix    ""

# detect setup.rb config option name of --rubyprog.
# some setup.rb accepts this option by other name, such as --ruby-prog.
# NOTE: set the value *before ruby.setup* to use ohter name.
options ruby.config_rubyprog_name
default ruby.config_rubyprog_name --rubyprog

ruby.branch         ${ruby.default_branch}

options ruby.link_binaries ruby.link_binaries_suffix
default ruby.link_binaries yes
default ruby.link_binaries_suffix {-${ruby.branch}}

# ruby group setup procedure; optional for ruby 1.8 if you want only
# basic variables, like ruby.lib and ruby.archlib.
proc ruby.setup {module vers {type "install.rb"} {docs {}} {source "custom"} {implementation "ruby"}} {
    global name subport ruby.branches
    global destroot prefix worksrcpath os.platform
    global ruby.bin ruby.rdoc ruby.gem ruby.rake ruby.branch
    global ruby.api_version ruby.lib ruby.suffix ruby.bindir ruby.gemdir
    global ruby.module ruby.filename ruby.project ruby.docs ruby.srcdir
    # ruby.version is obsoleted. use ruby.gemdir.
    global ruby.prog_suffix
    # from muniversal
    global universal_archs_supported
    global merger_configure_env merger_build_env merger_destroot_env
    # for setup.rb +universal
    global ruby.config_rubyprog_name

    version         ${vers}
    categories      ruby

    # define ruby global names and lists
    # check if module is a list or string
    if {[llength ${module}] > 1} {
        # if a list, first item is the module name
        set ruby.module     [lindex ${module} 0]
        # second argument is the project & file name
        set ruby.project    [lindex ${module} 1]
        set ruby.filename   [lindex ${module} 1]
    } else {
        # else, module, project, and file name are the same
        set ruby.module     ${module}
        set ruby.project    ${module}
        set ruby.filename   ${module}
    }

    if {${ruby.branches} ne ""} {
        # add subports rbXX-module from ${ruby.branches}
        if {![info exists name]} {
            name rb-[string tolower ${ruby.module}]
        }
        if {[string match rb-* $name]} {
            # stub port
            set rootname [string range $name 3 end]
            foreach v ${ruby.branches} {
                set suffix [join [split ${v} .] {}]
                subport rb${suffix}-${rootname} {
                    ruby.branch ${v}
                    depends_lib port:ruby${ruby.suffix}
                }
            }
            if {$subport eq $name} {
                ruby.link_binaries no
                distfiles
                platforms       any
                supported_archs noarch
                use_configure no
                build {}
                destroot {
                    xinstall -d -m 0755 ${destroot}${prefix}/share/doc/${name}
                    system "echo $name is a stub port > ${destroot}${prefix}/share/doc/${name}/README"
                }
                return
            }
        }
    } else {
        switch ${implementation} {
            ruby-devel { ruby.branch 3.5 }
            ruby34 { ruby.branch 3.4 }
            ruby33 { ruby.branch 3.3 }
            ruby32 { ruby.branch 3.2 }
            ruby31 { ruby.branch 3.1 }
            ruby30 { ruby.branch 3.0 }
            ruby27 { ruby.branch 2.7 }
            ruby26 { ruby.branch 2.6 }
            ruby25 { ruby.branch 2.5 }
            ruby24 { ruby.branch 2.4 }
            ruby23 { ruby.branch 2.3 }
            ruby22 { ruby.branch 2.2 }
            ruby21 { ruby.branch 2.1 }
            ruby20 { ruby.branch 2.0 }
            ruby19 { ruby.branch 1.9 }
            ruby   { ruby.branch 1.8 }
            default {
                ui_error "ruby.setup: unknown implementation '${implementation}' specified (ruby33, ruby32, ... ruby20, ruby19 or ruby possible)"
                return -code error "ruby.setup failed"
            }
        }
        name            rb${ruby.suffix}-[string tolower ${ruby.module}]
        depends_lib     port:${implementation}
    }

    set ruby.docs   ${docs}

    # set source to rubygems by default for type "gem"
    if {(${type} eq "gem") && (${source} eq "custom")} {
        set source rubygems
    }
    switch -glob ${source} {
        rubygems {
            homepage        https://www.rubygems.org/gems/${ruby.project}
            master_sites    https://www.rubygems.org/downloads/
            livecheck.type  regex
            livecheck.url   https://www.rubygems.org/gems/${ruby.project}
            livecheck.regex {<i class="page__subheading">(\d|\d[0-9.]*\d)</i>}
        }
        sourceforge:* {
            set ruby.project [lindex [split ${source} {:}] 1]
            homepage        https://sourceforge.net/projects/${ruby.project}
            master_sites    sourceforge:${ruby.project}
        }
        sourceforge {
            homepage        https://sourceforge.net/projects/${ruby.project}
            master_sites    sourceforge:${ruby.project}
        }
    }

    distname        ${ruby.filename}-${vers}
    dist_subdir     ruby

    switch -glob ${type} {
        basic_install.rb {
            post-patch {
                # create destroot setup file
                set fp [open ${worksrcpath}/destroot.rb w]
                puts $fp "
                    require 'rbconfig'
                    include Config
                    DESTROOT=ENV\['DESTROOT'\] || ''
                    CONFIG.keys.find_all { |d|
                        d.match(/dir\$/) and !d.match(/(src|build|compile)/)
                    }.each {|confdir|
                        CONFIG\[confdir\]=DESTROOT+CONFIG\[confdir\]
                    }
                    \$:.reverse.each { |d| \$:.unshift(DESTROOT+d) }
                "
                close $fp
                # adjust basic install.rb script
                reinplace "s|site_ruby|vendor_ruby|" ${worksrcpath}/install.rb
            }

            use_configure   no

            build           {}

            pre-destroot {
                xinstall -d -m 0755 ${destroot}${ruby.lib}
            }
            destroot.env    DESTROOT=${destroot}
            destroot.cmd    ${ruby.bin} -rvendor-specific -rdestroot install.rb
            destroot.target
            destroot.destdir
            post-destroot {
                foreach file [readdir ${destroot}${prefix}/bin] {
                    move [file join ${destroot}${prefix}/bin $file] ${destroot}${ruby.bindir}
                }
            }
        }
        copy_install:* {
            set ruby.srcdir [lindex [split ${type} {:}] 1]

            use_configure   no

            build           {}

            destroot {
                set root ${worksrcpath}/${ruby.srcdir}
                xinstall -d -m 0755 ${destroot}${ruby.lib}
                fs-traverse file $root {
                    set file [trimroot $root $file]
                    if {$file ne ""} {
                        set filepath [file join $root $file]
                        if {[file isdirectory $filepath]} {
                            xinstall -d -m 0755 ${destroot}${ruby.lib}/${file}
                        } else {
                            xinstall -m 0644 $filepath ${destroot}${ruby.lib}/${file}
                        }
                    }
                }
            }
        }
        install.rb {
            configure.cmd       ${ruby.bin} -rvendor-specific install.rb
            configure.pre_args  config --bin-dir=${destroot}${ruby.bindir}

            build.cmd           ${ruby.bin} -rvendor-specific install.rb
            build.target        setup

            pre-destroot {
                if {[file isfile ${worksrcpath}/config.save]} {
                    reinplace "s|^prefix=${prefix}|prefix=${destroot}${prefix}|g" \
                        ${worksrcpath}/config.save
                }
                if {[file isfile ${worksrcpath}/.config]} {
                    reinplace "s|^prefix=${prefix}|prefix=${destroot}${prefix}|g" \
                        ${worksrcpath}/.config
                }
            }
            destroot.cmd        ${ruby.bin} -rvendor-specific install.rb
            destroot.target     install
            destroot.destdir
        }
        setup.rb {
            configure.cmd       ${ruby.bin} -rvendor-specific setup.rb
            configure.pre_args  config

            build.cmd           ${ruby.bin} -rvendor-specific setup.rb
            build.target        setup

            pre-destroot {
                foreach conf {config.save .config} {
                    if {[file isfile ${worksrcpath}/${conf}]} {
                        reinplace "s|${prefix}|${destroot}${prefix}|g" \
                            ${worksrcpath}/${conf}
                    }
                    if {[variant_isset universal]  && [info exists universal_archs_supported]} {
                        foreach arch ${universal_archs_supported} {
                            if {[file isfile ${worksrcpath}-${arch}/${conf}]} {
                                reinplace "s|${prefix}|${destroot}-${arch}${prefix}|g" \
                                    ${worksrcpath}-${arch}/${conf}
                            }
                        }
                    }
                }
            }
            destroot.cmd        ${ruby.bin} -rvendor-specific setup.rb
            destroot.target     install
            destroot.destdir
            # extconf.rb|mkmf.rb of ruby-1.8 does not support universal binary.
            # to build universal extensions, write "PortGroup muniversal 1.0" in the Portfile.
            if {[variant_isset universal] && (${ruby.branch} eq "1.8") && [info exists universal_archs_supported]} {
                # generate wrapper for --rubyprog option
                pre-configure {
                    set fo [open ${worksrcpath}/_mp_arch_ruby w]
                    puts $fo "#!/bin/sh"
                    puts $fo "/usr/bin/arch ${ruby.bin} \$@"
                    close $fo
                    system "chmod +x ${worksrcpath}/_mp_arch_ruby"
                }
                configure.pre_args-append \
                    ${ruby.config_rubyprog_name}=${worksrcpath}/_mp_arch_ruby
                foreach arch ${universal_archs_supported} {
                    lappend merger_configure_env(${arch}) \
                        ARCHPREFERENCE=ruby${ruby.branch}:${arch}
                    lappend merger_build_env(${arch}) \
                        ARCHPREFERENCE=ruby${ruby.branch}:${arch}
                    lappend merger_destroot_env(${arch}) \
                        ARCHPREFERENCE=ruby${ruby.branch}:${arch}
                }
                configure.cmd   /usr/bin/arch ${ruby.bin} -rvendor-specific setup.rb
                build.cmd       /usr/bin/arch ${ruby.bin} -rvendor-specific setup.rb
                destroot.cmd    /usr/bin/arch ${ruby.bin} -rvendor-specific setup.rb
            }
            post-destroot {
                foreach file [readdir ${destroot}${prefix}/bin] {
                    move [file join ${destroot}${prefix}/bin $file] ${destroot}${ruby.bindir}
                }
            }
        }
        extconf.rb {
            configure.cmd       ${ruby.bin} extconf.rb
            configure.pre_args
            configure.args      --prefix=${prefix} --vendor

            build.args          RUBY="${ruby.bin}"

            destroot.args       RUBY="${ruby.bin}"

            # extconf.rb|mkmf.rb of ruby-1.8 does not support universal binary.
            # to build universal extensions, write "PortGroup muniversal 1.0" in the Portfile.
            if {[variant_isset universal] && (${ruby.branch} eq "1.8") && [info exists universal_archs_supported]} {
                foreach arch ${universal_archs_supported} {
                    lappend merger_configure_env(${arch}) \
                        ARCHPREFERENCE=ruby${ruby.branch}:${arch}
                }
                configure.cmd   /usr/bin/arch ${ruby.bin} extconf.rb
            }
            post-destroot {
                foreach file [readdir ${destroot}${prefix}/bin] {
                    move [file join ${destroot}${prefix}/bin $file] ${destroot}${ruby.bindir}
                }
            }
        }
        gnu {
            build.args          RUBY="${ruby.bin} -rvendor-specific"

            pre-destroot {
                if {[file isfile ${worksrcpath}/config.save]} {
                    reinplace "s|${prefix}|${destroot}${prefix}|g" \
                        ${worksrcpath}/config.save
                }
                if {[file isfile ${worksrcpath}/.config]} {
                    reinplace "s|${prefix}|${destroot}${prefix}|g" \
                        ${worksrcpath}/.config
                }
            }
            destroot.args       RUBY="${ruby.bin} -rvendor-specific"
        }
        gem {
            use_configure no
            extract.suffix .gem

            if {${ruby.branch} eq "1.8"} {
                depends_lib-append  port:rb-rubygems
                if {${ruby.module} ne "rake"} {
                    depends_build-append    port:rb18-rake
                }
            }

            extract.mkdir       yes
            extract {
                copy ${distpath}/${distname}.gem ${worksrcpath}/${ruby.filename}.gem
            }
            build {}

            pre-destroot {
                xinstall -d -m 0755 ${destroot}${ruby.gemdir}
            }

            destroot.cmd    ${ruby.gem}
            destroot.target install
            destroot.args   --local --force --install-dir ${destroot}${ruby.gemdir}
            destroot.env-append rake=${ruby.rake}
            destroot.post_args ${worksrcpath}/${ruby.filename}.gem

            destroot {
                command_exec destroot

                set binDir ${destroot}${ruby.gemdir}/bin
                if {[file isdirectory $binDir]} {
                    foreach file [readdir $binDir] {
                        file copy [file join $binDir $file] ${destroot}${ruby.bindir}
                    }
                }
            }
        }
        fetch {
            # do nothing but fetch and extract - for strange installers
            build {}
        }
        default {
            ui_error "ruby.setup: unknown setup type '${type}' specified!"
            return -code error "ruby.setup failed"
        }
    }

    if {$type ne "gnu"} {
        configure.universal_args-delete  --disable-dependency-tracking
    }

    pre-destroot {
        xinstall -d -m 0755 ${destroot}${ruby.bindir}
    }

    post-destroot {
        if {${ruby.link_binaries}} {
            foreach bin [glob -nocomplain -tails -directory "${destroot}${ruby.bindir}" *] {
                if {[catch {file type "${destroot}${prefix}/bin/${bin}${ruby.link_binaries_suffix}"}]} {
                    ln -s "${ruby.bindir}/${bin}" "${destroot}${prefix}/bin/${bin}${ruby.link_binaries_suffix}"
                }
            }
        }
        # Install documentation files (if specified)
        if {[llength ${ruby.docs}] > 0} {
            if {$subport ne ""} {
                set docPath ${prefix}/share/doc/${subport}
            } else {
                set docPath ${prefix}/share/doc/${name}
            }
            xinstall -d -m 0755 ${destroot}${docPath}
            foreach docitem ${ruby.docs} {
                set docitem [file join ${worksrcpath} ${docitem}]
                if {[file isdirectory ${docitem}]} {
                    set subdir [file tail $docitem]
                    xinstall -d -m 0755 ${destroot}${docPath}/${subdir}
                    fs-traverse file $docitem {
                        set file [trimroot $docitem $file]
                        if {$file ne ""} {
                            set filepath [file join $docitem $file]
                            if {[file isdirectory $filepath]} {
                                xinstall -d -m 0755 ${destroot}${docPath}/${subdir}/${file}
                            } else {
                                xinstall -m 0644 $filepath ${destroot}${docPath}/${subdir}/${file}
                            }
                        }
                    }
                } else {
                    xinstall -m 0644 ${docitem} ${destroot}${docPath}
                }
            }
        }
    }
}

proc trimroot {root path} {
    set acc [list]
    set skiproot no
    foreach rootf [file split $root] pathf [file split $path] {
        if {$pathf eq ""} {
            # we've hit the end of the path
            break
        } elseif {$skiproot eq "yes" || $rootf eq ""} {
            lappend acc $pathf
        } elseif {$rootf ne $pathf} {
            # diverged from the root
            lappend acc $pathf
            set skiproot yes
        }
    }
    if {[llength $acc] == 0} {
        return ""
    } else {
        return [file join {*}$acc]
    }
}
