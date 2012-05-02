#!/bin/bash

###########
### RPM ###
###########

# build a rpm from a perl module
# $1 - prefix of module
# $2 - package name
rpm_build_perl_module() {
	local prefix_path=$1; shift
	local package_name=$1; shift
	local package_version=`grep 'our $VERSION' $prefix_path/lib/*.pm | cut -d"'" -f2`

	tar -czf $RPM_SOURCE_DIR/$package_name-$package_version.tar.gz $prefix_path && \
	cpanflute2 --buildall $RPM_SOURCE_DIR/$package_name-$package_version.tar.gz && \
	rm -f $RPM_SOURCE_DIR/$package_name-$package_version.tar.gz
}

# build perl-MonitisMonitorManager rpm
# $1 - package name to use
rpm_build_MonitisMonitorManager() {
	local perl_module_name=$1; shift
	local package_name=perl-$perl_module_name; shift
	local spec_file=$package_name.spec
	local package_version=`grep "^Version:" $spec_file | awk '{print $2}'`
	local package_release=`grep "^Release:" $spec_file | awk '{print $2}'`


	local buildroot_dir=`mktemp -d /tmp/buildroot.XXXXX`
	mkdir -p $buildroot_dir/$package_name-$package_version
	cp -av $perl_module_name/* $buildroot_dir/$package_name-$package_version

	# remove the debian init service and use the rhel one
	#(cd $buildroot_dir/$package_name-$package_version && ls && rm -f etc/init.d/deb.m3 && \
	#	mv etc/init.d/rpm.m3 etc/init.d/m3)

	(cd $buildroot_dir; tar -czf $package_name.tar.gz $package_name-$package_version)
	echo $buildroot_dir
	cp -a $buildroot_dir/$package_name.tar.gz $RPM_SOURCE_DIR

	rm -rf --preserve-root $buildroot_dir

	# build src.rpm
	local rpm_buildsrc_log=`mktemp /tmp/rpmsrc.log.XXXXX`
	rpmbuild -bs $spec_file | tee $rpm_buildsrc_log
	local rpmsrc=`cat $rpm_buildsrc_log | grep 'Wrote:' | cut -d' ' -f2`

	# build binary rpm
	rpmbuild --target noarch --rebuild $rpmsrc
}

###########
### DEB ###
###########

# build a deb from a perl module
# $1 - prefix of module
# $2 - package name
deb_build_perl_module() {
	local prefix_path=$1; shift
	local package_name=$1; shift
	local package_version=`grep 'our $VERSION' $prefix_path/lib/*.pm | cut -d"'" -f2`

	local tmp_module_dir=`mktemp -d`
	cp -av $prefix_path/* $tmp_module_dir/
	# TODO this does not build a proper package with dependencies
	dh-make-perl --version $package_version $tmp_module_dir
	cd $tmp_module_dir; debuild
	rm -rf --preserve-root $tmp_module_dir/
}

# build monitis-m3 deb
# $1 - package name to use
deb_build_MonitisMonitorManager() {
	local perl_module_name=$1; shift
	local package_name=libmonitismonitormanager-perl

	local buildroot_dir=`mktemp -d /tmp/buildroot.XXXXX`
	local install_dir=`mktemp -d`
	cp -av $perl_module_name/* $buildroot_dir/
	(cd $buildroot_dir && dh-make-perl --build)
	# great, that builds it all, but without the etc directory :(
	# so this is ugly, but now we'll more or less "rebuild" it
	# again...

	# TODO VERY UGLY!!
	cp -av $buildroot_dir/debian/$package_name/* $install_dir/
	cp -av $buildroot_dir/etc $install_dir/
	mv $buildroot_dir/etc/sysconfig $install_dir/etc/default

	# remove the rhel init service and use the debian one
	rm -f $install_dir/etc/init.d/rpm.m3
	mv $install_dir/etc/init.d/deb.m3 $install_dir/etc/init.d/m3

	# ok, build (or actually just package it now)!
	local package_version_release=`grep '^Version' $install_dir/DEBIAN/control | cut -d' ' -f2`
	dpkg -b $install_dir ${package_name}_${package_version_release}_all.deb
	echo "Built in : $install_dir"

	# clean it up
	rm -rf --preserve-root $buildroot_dir $install_dir
}

##############
### COMMON ###
##############

PACKAGE_MANAGER=""
RPM_SOURCE_DIR=""
# detetcs package manager and returns it
detect_package_manager() {
	if which rpm >& /dev/null; then
		RPM_SOURCE_DIR=`rpm --eval '%{_sourcedir}'`
		PACKAGE_MANAGER="rpm"
	elif which dpkg >& /dev/null; then
		PACKAGE_MANAGER="deb"
	else
		echo "Could not detect package manager!"
		exit 1
	fi
}

# build monitis API
Monitis() {
	# build the Perl-SDK module
	${PACKAGE_MANAGER}_build_perl_module ../../Perl-SDK Monitis
}

# build MonitisMonitorManager
MonitisMonitorManager() {
	# build the perl module
	${PACKAGE_MANAGER}_build_MonitisMonitorManager MonitisMonitorManager
}

# prepare a CPAN upload
CPAN() {
	local package_name=MonitisMonitorManager
	local package_dir=MonitisMonitorManager
	local package_version=`grep 'our $VERSION' $package_dir/lib/*.pm | cut -d"'" -f2`
	local tmp_dir=`mktemp -d`
	cp -av $package_dir/* $tmp_dir

	(cd $tmp_dir && perl Makefile.PL && make dist && mv $package_name*.tar.gz /tmp)
	echo "Package is at /tmp/$package_name-$package_version.tar.gz"
	rm --preserve-root -rf $tmp_dir
}

# main
main() {
	# avoid running `detect_package_manager` as it will run inside a subshell
	# and will not allow us to set variables on the environment
	detect_package_manager
	if [ x"$PACKAGE_MANAGER" = x ]; then
		echo "Could not detect package manager"
		exit 1
	fi

	if [ x"$1" != x ] && [ "$1" == "ALL" ]; then
		Monitis && MonitisMonitorManager
	else
		$@
	fi
}

main "$@"

