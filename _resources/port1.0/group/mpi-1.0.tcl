# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# This PortGroup sets up default variants for projects that want MPI
#
# Usage:
#
#   PortGroup               mpi 1.0
#
# Available procedures:
# proc mpi_active_variant_name {depspec}
#   Returns the name of the active MPI variant of a dependency.
# proc mpi_variant_name {}
#   Returns the name of the active MPI variant of this port.
# proc mpi.enforce_variant {args}
#   Raise an error if the dependency does not have the same MPI variant
#   as this port. Also enforces that the dependency has the same C variant.
# proc mpi_variant_isset {}
#   Whether an MPI variant has been set.
# proc mpi.setup {args}
#   Creates MPI variants.
#   Available arguments: "require" means an MPI variant must be set.
#   All of the arguments for compilers.setup are available too and will be passed to that procedure.
#   "default" means an MPI variant (mpich) will be set as a default variant.
#   You can either list which MPI's can be used (e.g. mpich openmpi),
#   which cannot be used (e.g. -mpich -openmpi-devel).
#   There are three MPI variants: mpich and openmpi openmpi-devel.

PortGroup compilers 1.0

default mpi.variants {}
default mpi.require 0
default mpi.default 0
default mpi.required_variants {}

set mpi.cc   mpicc
set mpi.cxx  mpicxx
set mpi.f77  mpif77
set mpi.f90  mpif90
set mpi.fc   mpif90
set mpi.exec mpiexec
set mpi.name ""

set mpidb(mpich,variant)  mpich
set mpidb(mpich,descrip)  "MPICH"
set mpidb(mpich,name)     mpich
set mpidb(mpich,conflict) ""

set mpidb(openmpi,variant)  openmpi
set mpidb(openmpi,descrip)  "OpenMPI"
set mpidb(openmpi,name)     openmpi
set mpidb(openmpi,conflict) ""

foreach mpiname [array names mpidb *,variant] {
    lappend mpi.variants $mpidb($mpiname)
}
unset mpiname

proc mpi.get_default_mpi_compiler {} {
    global os.arch
    # No MPI variant has been selected.
    # Attempt to select the MPI port that is consistent with the compiler being used.
    lassign [split [option configure.compiler] "-"] ismacports type ver
    if {${ismacports} ne "macports"} {
        # system compiler is being used, so use {mpich,openmpi}-default
        return {mp default}
    } elseif {${os.arch} eq "powerpc"} {
        # MPI never uses Xcode gcc and there is no clang.
        # Avoid unnecessary zoo of mpich versions.
        return {mp default}
    } else {
        # macports compiler is being used, so use the corresponding MPI port
        set mpiver [join [split ${ver} "."] ""]
        if {"-${type}${mpiver}" ni ${::mpi.disabled_compilers}} {
            return "${type}${mpiver} ${type}${mpiver}"
        } else {
            return ""
        }
    }
}

proc mpi.setup_variants {variants} {
    global mpidb mpi.cc mpi.cxx mpi.f77 mpi.f90 mpi.fc

    foreach variant $variants {
        if {[variant_exists $variant]} {
            ui_debug "$variant variant already exists, so not adding the default one"
        } else {
            set i [lsearch -exact $variants $variant]
            set c [lreplace $variants $i $i]

            # only add conflicts for variants that exist
            foreach j $mpidb($variant,conflict) {
                if {[variant_exists $j]} {
                    lappend c $j
                }
            }

            variant ${variant} description "Build using the $mpidb($variant,descrip) compiler" conflicts {*}$c "

                set c_name \[c_variant_name\]
                set f_name \[fortran_variant_name\]
                set p_name \$c_name
                set d_name \$c_name
                if {\$c_name eq {}} {
                    lassign \[mpi.get_default_mpi_compiler\] p_name d_name
                } elseif {\[string match gcc* \$c_name\]} {
                    configure.cxx_stdlib macports-libstdc++
                }

                if {\$p_name eq {}} {
                    pre-configure {
                        error \"No supported MPI compiler\"
                    }
                } else {
                    set path \"etc/select/mpi/${variant}-\${p_name}\"

                    if {\$f_name ne {}} {
                        set path \"\$path-fortran\"
                    }

                    depends_lib-append path:\$path:$mpidb($variant,name)-\$d_name
                    set mpi.name $mpidb($variant,name)-\$d_name

                    foreach compiler {cc cxx f77 f90 exec} {
                        set mpi.\$compiler mpi\${compiler}-$mpidb($variant,name)-\$p_name
                    }
                    set mpi.fc mpif90-$mpidb($variant,name)-\$p_name

                    # there is no mpicpp or mpiobj
                    # if more compilers are added in compilers portgroup, need to be added here
                    foreach compiler \${compilers.list} {
                        if {\$compiler ne \"fc\" && \$compiler ne \"cpp\" && \$compiler ne \"objc\"} {
                            configure.\$compiler \${prefix}/bin/mpi\${compiler}-$mpidb($variant,name)-\$p_name
                        }
                    }
                    if {\"fc\" in \${compilers.list}} {
                        set configure.fc \${prefix}/bin/mpif90-$mpidb($variant,name)-\$p_name
                    }
                }

            "
        }
    }
}

proc mpi_active_variant_name {depspec} {
    global mpi.variants

    foreach m ${mpi.variants} {
        if {![catch {set result [active_variants $depspec $m ""]}]} {
            if {$result} {
                return $m
            }
        } else {
            ui_warn "mpi_active_variant_name: \[active_variants $depspec $m \"\"\] fails."
        }
    }

    return ""
}

proc mpi_variant_name {} {
    global mpi.variants variations

    foreach mpiv ${mpi.variants} {
        # we need to check the default_variants so we can't use variant_isset
        if {[info exists variations($mpiv)] && $variations($mpiv) eq "+"} {
            return $mpiv
        }
    }

    return ""
}

proc mpi.enforce_variant {args} {
    global mpi.required_variants
    append mpi.required_variants " $args"
}

proc mpi.action_enforce_variants {ports} {
    global name
    ui_debug "mpi.enforce_variant list: ${ports}"
    foreach depspec $ports {
        set portname [_get_dep_port $depspec]
        if {![catch {set result [active_variants $portname "" ""]}]} {
            set otmpi  [mpi_active_variant_name $portname]
            set mympi  [mpi_variant_name]

            if {$otmpi ne "" && $mympi eq ""} {
                # instead of trying to append to a default variant (which fails
                # silently for some cases), we should be explicit and tell the
                # user about the error
                ui_error "Need to select variant +$otmpi"
                return -code error "$portname +$otmpi is installed, so +$otmpi needs to be selected for $name"
            } elseif {$otmpi ne $mympi} {
                ui_error "Install $portname +$mympi"
                return -code error "$portname +$mympi not installed"
            }
        } else {
            ui_error "Internal error: '$portname' does not refer to an installed port."
        }
    }
}

pre-configure {
    # This does not needed to be done in pre-archivefetch because if the archive is already built,
    # we will not need to use the Fortran MPI compiler, and the incompatibility only matters at compile time.
    if {[fortran_variant_isset] && [mpi_variant_isset]} {
        set gcc_name ""
        regexp (gcc\[0-9\]*) ${mpi.name} gcc_name
        if {$gcc_name ne ""} {
            if {[active_variants ${mpi.name} "fortran" ""]} {
                set mpif $gcc_name
            } else {
                set mpif ""
            }
        } else {
            # this is a default, clang, or llvm subport
            set mpif [fortran_active_variant_name ${mpi.name}]
        }
        # mpif will definitely have a real compiler name, not gfortran.
        set myf [fortran_compiler_name [fortran_variant_name]]

        if {$myf ne $mpif} {
            if {$mpif eq "" && $gcc_name ne ""} {
                ui_error "${mpi.name} was built without Fortran support."
                set need "fortran"
            } else {
                if {[fortran_variant_name] eq "gfortran"} {
                    set selectedf " (via +gfortran)"
                } else {
                    set selectedf ""
                }
                ui_error "${mpi.name} has a different Fortran variant ($mpif) than the one selected, $myf$selectedf."
                set need $myf
            }
            return -code error "Install ${mpi.name} +$need"
        }
    }

    if {[mpi_variant_isset] && ([mpi_variant_name] eq "mpich" || [mpi_variant_name] eq "mpich-devel")} {
        # The new linker in Xcode 15 is buggy, causing build failures for many (but not all)
        # ports that link to mpich. The -Wl,-ld_classic option below reverts to the
        # classic linker.
        #
        # TODO: This is a temporary solution, the classic linker will be removed in a future release by Apple.
        if { ( [vercmp ${xcodeversion} 15 ] >= 0 ) || ( [vercmp ${xcodecltversion} 15 ] >= 0 ) } {
            configure.ldflags-append    -Wl,-ld_classic
        }
    }
}

proc mpi_variant_isset {} {
    return [expr {[mpi_variant_name] ne ""}]
}

proc mpi.setup {args} {
    global cdb mpidb mpi.variants mpi.require mpi.default compilers.variants \
        name os.major os.arch

    set add_list [list]
    set remove_list ${mpi.variants}
    set cl [list]

    foreach variant $args {
        # keep original commandname
        set v $variant

        # if any negated mpi (e.g. -mpich) is specified then we are
        # removing from the default, complete list
        set mode add
        if {[string first - $v] == 0} {
            set mode remove

            #strip the beginning '-' character
            set v [string range $v 1 end]
        }

        # handle special cases, such as 'require' -> makes mpi required
        switch -exact $v {
            require {
                set mpi.require 1
                set mpi.default 1
            }
            "default" {
                set mpi.default 1
            }
            require_fortran {
                set cl [add_from_list $cl "require_fortran"]
            }
            default_fortran {
                set cl [add_from_list $cl "default_fortran"]
            }
            default {
                if {[info exists mpidb($v,variant)] == 0} {
                    if {$v eq "gcc" ||
                        $v eq "fortran" ||
                        $v eq "clang" ||
                        $v eq "require_fortran" ||
                        $v eq "default_fortran" ||
                        [info exists cdb($v,variant)]} {
                        set cl [add_from_list $cl $variant]
                    } else {
                        # If removing an already not available compiler just warn, otherwise hard error
                        if { ${mode} eq "add" } {
                            return -code error "MPI package ${v} not available for Darwin${os.major} ${os.arch}"
                        } else {
                            ui_debug "MPI package ${v} not available for Darwin${os.major} ${os.arch}"
                        }
                    }
                } else {
                    set ${mode}_list [${mode}_from_list [set ${mode}_list] $mpidb($v,variant)]
                }
            }
        }
    }

    # We can't dynamically look up which variants are enabled for the mpi
    # ports. So we'll disable the ones we know aren't supported, try to keep
    # that information synced, and use active variants to detect any
    # incompatibility that may slip through.
    set cur_variant [mpi_variant_name]
    if {$cur_variant eq "" && ${mpi.default}} {
        set cur_variant mpich
    }
    set ::mpi.disabled_compilers [list]
    if {$cur_variant ne ""} {
        set is_mpich [expr {$cur_variant in {mpich}}]

        lappend ::mpi.disabled_compilers \
            -gcc43 -gcc44 -gcc45 -gcc46 -gcc47 -gcc48

        # All of the following are now obsolete for openmpi/mpich
        lappend ::mpi.disabled_compilers \
            -clang33 -clang34 -clang35 -clang37 \
            -clang50 -clang60 -clang70 -clang80 \
            -clangdevel \
            -gcc49 -gcc5 -gcc6 -gcc8 \
            -gccdevel

        # GCC 9 only supported for macOS 10.6 through 10.10
        if {${os.major} < 10 || ${os.major} > 14} {
            lappend ::mpi.disabled_compilers -gcc9
        }

        # Clang 15 and 16 only available on 10.7 and later
        if {${os.major} < 11} {
            lappend ::mpi.disabled_compilers \
                -clang15 -clang16 -clang17
        }

        if {${os.arch} eq "arm"} {
            # Disable compilers not well supported on arm. Note: clang 9 and 10
            # build on arm, but are not reliable so skip; use clang 11 instead.
            lappend ::mpi.disabled_compilers \
                -gcc7 -gcc9 \
                -clang90 -clang10
        }

        if {${os.arch} eq "powerpc"} {
            # Disable compilers not supported on powerpc.
            lappend ::mpi.disabled_compilers \
                -clang -gcc9
        }
    }

    compilers.setup {*}$cl {*}${::mpi.disabled_compilers}

    # we need to check for a removed variant early so we can exit before
    # the wrong variant is passed up the dependency chain
    set badvariant [mpi_variant_name]
    set origvariants ${mpi.variants}
    set mpi.variants [lsort [concat $remove_list $add_list]]
    set removedvariants [remove_from_list $origvariants ${mpi.variants}]
    if {$badvariant in $removedvariants} {
        ui_error "$name has disallowed +$badvariant! Please choose another mpi variant"
        return -code error "$name +$badvariant not allowed"
    }

    mpi.setup_variants ${mpi.variants}

    set mpi [mpi_variant_name]
    if {$mpi ne ""} {
        set fv [fortran_variant_name]
        set cv "[c_variant_name] $fv"
        set cl [remove_from_list ${compilers.variants} [c_variant_name]]

        # if no fortran variant is set, then we need to remove the fortran
        # variants from the list of variants that shouldn't be blacklisted
        if {$fv eq ""} {
            set cl [remove_from_list $cl {gfortran g95}]
            set cv [c_variant_name]
        }

        require_active_variants $mpi $cv $cl
    }

    if {${mpi.default} && ![mpi_variant_isset]} {
        default_variants-append +mpich
    }
}

pre-fetch {
    if {${mpi.require} && [mpi_variant_name] eq ""} {
        return -code error "must set at least one mpi variant"
    }
    mpi.action_enforce_variants ${mpi.required_variants}
}

pre-archivefetch {
    mpi.action_enforce_variants ${mpi.required_variants}
}
