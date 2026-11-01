Name:       skipjack-sensorhelper
Summary:    TicWatch C2 raise to wake and heart rate
Version:    0.1.1
Release:    1
License:    LGPLv2
Source0:    %{name}-%{version}.tar.bz2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5DBus)
BuildRequires: pkgconfig(libhardware)
BuildRequires: pkgconfig(android-headers)
Requires(post): systemd

%description
Raise to wake (sensor hub wrist tilt gesture -> MCE display on) and a D-Bus
heart rate service for the TicWatch C2 (skipjack).

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
make %{?_smp_mflags}

%install
%qmake5_install
mkdir -p %{buildroot}%{_unitdir}/graphical.target.wants
ln -s ../skipjack-sensorhelper.service %{buildroot}%{_unitdir}/graphical.target.wants/

%post
systemctl daemon-reload || :
systemctl try-restart skipjack-sensorhelper.service || :

%files
%{_libexecdir}/skipjack/skipjack-sensorhelper
%{_unitdir}/skipjack-sensorhelper.service
%{_unitdir}/graphical.target.wants/skipjack-sensorhelper.service
%{_datadir}/dbus-1/system.d/org.sailfishos.skipjack.Sensors.conf
