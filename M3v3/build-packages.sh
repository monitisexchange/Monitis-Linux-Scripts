#!/bin/bash

###########
### RPM ###
###########

# build a rpm from a perl module
# $1 - prefix of module
# $2 - package name
rpm_build_perl_module() {
	local prefix_path=$1; shift
	local pkg_name=$1; shift
	local pkg_version=`grep 'our $VERSION' $prefix_path/lib/*.pm | cut -d"'" -f2`

	tar -czf $RPM_SOURCE_DIR/$pkg_name-$pkg_version.tar.gz $prefix_path && \
	cpanflute2 --buildall $RPM_SOURCE_DIR/$pkg_name-$pkg_version.tar.gz && \
	rm -f $RPM_SOURCE_DIR/$pkg_name-$pkg_version.tar.gz
}

# build monitis-m3 rpm
# $1 - package name to use
rpm_build_monitis_m3() {
	local package_name=$1; shift
	local spec_file=$package_name.spec
	local package_version=`grep "^Version:" monitis-m3.spec | awk '{print $2}'`
	local package_release=`grep "^Release:" monitis-m3.spec | awk '{print $2}'`


	local buildroot_dir=`mktemp -d /tmp/buildroot.XXXXX`
	mkdir -p $buildroot_dir/$package_name-$package_version
	cp -av $package_name/* $buildroot_dir/$package_name-$package_version

	# remove the debian init service and use the rhel one
	rm -f $buildroot_dir/$package_name-$package_version/etc/init.d/deb.m3
	mv $buildroot_dir/$package_name-$package_version/etc/init.d/rpm.m3 $buildroot_dir/$package_name-$package_version/etc/init.d/m3

	(cd $buildroot_dir; tar -czf $package_name.tar.gz $package_name-$package_version)
	echo $buildroot_dir
	cp -a $buildroot_dir/$package_name.tar.gz $RPM_SOURCE_DIR

	rm -rf --preserve-root $buildroot_dir

	# build src.rpm
	local rpm_buildsrc_log=`mktemp /tmp/rpmsrc.log.XXXXX`
	rpmbuild -bs monitis-m3.spec | tee $rpm_buildsrc_log
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
	local pkg_name=$1; shift
	local pkg_version=`grep 'our $VERSION' $prefix_path/lib/*.pm | cut -d"'" -f2`

	local tmp_module_dir=`mktemp -d`
	cp -av $prefix_path/* $tmp_module_dir/
	# TODO this does not build a proper package with dependencies
	dh-make-perl --version $pkg_version $tmp_module_dir
	cd $tmp_module_dir; debuild
	rm -rf --preserve-root $tmp_module_dir/
}

# build monitis-m3 deb
# $1 - package name to use
deb_build_monitis_m3() {
	local package_name=$1; shift
	local spec_file=$package_name.spec
	local package_version=`grep "^Version:" monitis-m3.spec | awk '{print $2}'`
	local package_release=`grep "^Release:" monitis-m3.spec | awk '{print $2}'`

	local buildroot_dir=`mktemp -d /tmp/buildroot.XXXXX`
	mkdir -p $buildroot_dir
	cp -av $package_name/* $buildroot_dir/

	# remove the rhel init service and use the debian one
	rm -f $buildroot_dir/etc/init.d/rpm.m3
	mv $buildroot_dir/etc/init.d/deb.m3 $buildroot_dir/etc/init.d/m3

	# TODO a bit ugly!
	mv $buildroot_dir/etc/sysconfig $buildroot_dir/etc/default

	# export the debian control file
	mkdir -p $buildroot_dir/DEBIAN
	cp -av control $buildroot_dir/DEBIAN/

	dpkg -b $buildroot_dir ${package_name}_${package_version}-${package_release}_all.deb
	echo "Built in : $buildroot_dir"

	# clean it up
	rm -rf --preserve-root $buildroot_dir
}

##############
### COMMON ###
##############

# detetcs package manager and returns it
detect_package_manager() {
	if which rpm >& /dev/null; then
		declare -g -r RPM_SOURCE_DIR=`rpm --eval '%{_sourcedir}'`
		declare -g -r PACKAGE_MANAGER="rpm"
	elif which dpkg >& /dev/null; then
		declare -g -r PACKAGE_MANAGER="deb"
	else
		echo "Could not detect package manager!"
		exit 1
	fi
}

# main
main() {
	# avoid running `detect_package_manager` as it will run inside a subshell
	# and will not allow us to set variables on the environment
	detect_package_manager

	# build the Perl-SDK module
	${PACKAGE_MANAGER}_build_perl_module ../../Perl-SDK Monitis

	# build the perl module
	${PACKAGE_MANAGER}_build_perl_module MonitisMonitorManager MonitisMonitorManager

	# build the m3 init.d service package
	${PACKAGE_MANAGER}_build_monitis_m3 monitis-m3
}

main "$@"

