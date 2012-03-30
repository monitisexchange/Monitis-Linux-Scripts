#!/bin/bash
declare -r RPM_SOURCE_DIR=`rpm --eval '%{_sourcedir}'`

# $1 - prefix of module
# $2 - package name
build_rpm_from_perl_module() {
	local prefix_path=$1; shift
	local pkg_name=$1; shift
	local pkg_version=`grep 'our $VERSION' $prefix_path/lib/*.pm | cut -d"'" -f2`

	tar -czf $RPM_SOURCE_DIR/$pkg_name-$pkg_version.tar.gz $prefix_path && \
	cpanflute2 --buildall $RPM_SOURCE_DIR/$pkg_name-$pkg_version.tar.gz && \
	rm -f $RPM_SOURCE_DIR/$pkg_name-$pkg_version.tar.gz
}

# $1 - package name to use
build_monitis_m3_rpm() {
	local package_name=$1; shift
	local spec_file=$package_name.spec
	local package_version=`grep "^Version:" monitis-m3.spec | awk '{print $2}'`
	local package_release=`grep "^Release:" monitis-m3.spec | awk '{print $2}'`

	local buildroot_dir=`mktemp -d /tmp/buildroot.XXXXX`
	mkdir -p $buildroot_dir/$package_name-$package_version
	cp -av $package_name/* $buildroot_dir/$package_name-$package_version
	(cd $buildroot_dir; tar -czf $package_name-$package_version.tar.gz $package_name-$package_version)
	echo $buildroot_dir
	cp -a $buildroot_dir/$package_name-$package_version.tar.gz $RPM_SOURCE_DIR

	rm -rf $buildroot_dir

	# build src.rpm
	local rpm_buildsrc_log=`mktemp /tmp/rpmsrc.log.XXXXX`
	rpmbuild -bs monitis-m3.spec | tee $rpm_buildsrc_log
	local rpmsrc=`cat $rpm_buildsrc_log | grep 'Wrote:' | cut -d' ' -f2`

	# build binary rpm
	rpmbuild --target noarch --rebuild $rpmsrc
}

main() {
	# build the Perl-SDK module
	build_rpm_from_perl_module ../../Perl-SDK Monitis

	# build the perl module
	build_rpm_from_perl_module MonitisMonitorManager MonitisMonitorManager

	# build the m3 init.d service package
	build_monitis_m3_rpm monitis-m3
}

main "$@"

