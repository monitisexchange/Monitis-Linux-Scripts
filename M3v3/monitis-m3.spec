Summary:	Monitis M3 service
Name:		monitis-m3
Version:	3.0
Release:	1
License:	GPL
URL:		http://www.monitis.com/
Packager:	Dan Fruehauf <malkodan gmail com>
Group:		Applications/System
Source:		monitis-m3-3.0.tar.gz
Requires:	perl-MonitisMonitorManager
BuildRoot:	%{_tmppath}/%{name}-%{version}-root-%(id -u -n)

%description
Monitis Monitor Manager, or M3 in short service

%prep
%setup

%build

%install
mkdir -p %{buildroot}
if [ x"%{buildroot}" != x ] && [ "%{buildroot}" != "/" ]; then
	rm -rf %{buildroot}/*
fi
%{__cp} -a * %{buildroot}

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/bin/%{name}*
/usr/local/share/%{name}
/etc/init.d/m3
%config(noreplace) /etc/m3.d
%config(noreplace) /etc/logrotate.d/m3
%config(noreplace) /etc/sysconfig/m3

%changelog
* Fri Mar 23 2012 Dan Fruehauf <malkodan gmail com> 3.0-1
- Initial release

