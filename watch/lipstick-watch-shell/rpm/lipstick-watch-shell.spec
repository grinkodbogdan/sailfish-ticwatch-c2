Name:       lipstick-watch-shell
Version:    0.1.0
Release:    1
Summary:    Round smartwatch homescreen for Sailfish OS
License:    LGPLv2
Source0:    %{name}-%{version}.tar.bz2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(lipstick-qt5) >= 0.36
BuildRequires:  pkgconfig(Qt5Compositor)
BuildRequires:  pkgconfig(mlite5)
BuildRequires:  pkgconfig(KF5BluezQt)
Requires:   lipstick-qt5
Requires:   kf5bluezqt-bluez5-declarative

%description
A lipstick-based homescreen for round smartwatches (developed on the Mobvoi
TicWatch C2, 360x360): watch face, curved app launcher, quick settings and
notifications, with edge gestures for applications. Replaces the phone
homescreen (lipstick-jolla-home-qt5) when its user service is enabled.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
make %{?_smp_mflags}

%install
%qmake5_install

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_userunitdir}/%{name}.service
