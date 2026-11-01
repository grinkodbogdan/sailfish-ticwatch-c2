Name:       watch-btsyncd
Summary:    Gadgetbridge sync over Bluetooth LE (AsteroidOS protocol)
Version:    0.1.0
Release:    1
License:    GPLv3
Source0:    %{name}-%{version}.tar.bz2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5DBus)
BuildRequires: pkgconfig(mpris-qt5)
BuildRequires: pkgconfig(mlite5)
Requires:   mpris-qt5
Requires:   skipjack-sensorhelper >= 0.1.1

%description
asteroid-btsyncd for Sailfish OS: notifications, music control, weather,
time and battery shared with the Gadgetbridge Android app.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
make %{?_smp_mflags}

%install
%qmake5_install
mkdir -p %{buildroot}%{_userunitdir}/user-session.target.wants
ln -s ../watch-btsyncd.service %{buildroot}%{_userunitdir}/user-session.target.wants/

%files
%license LICENSE
%{_bindir}/watch-btsyncd
%{_userunitdir}/watch-btsyncd.service
%{_userunitdir}/user-session.target.wants/watch-btsyncd.service
