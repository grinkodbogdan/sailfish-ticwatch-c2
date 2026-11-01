# Sailfish OS hardware adaptation for the TicWatch C2 (skipjack), built from
# AsteroidOS' prebuilt hybris userspace instead of a local AOSP build:
#   hybris-o-msm8909.tar.gz  hybris-patched Android 8.1 for MSM8909W + headers
#                            (meta-asteroid android_armv7-oreo.bb)
#   system-skipjack.tar.gz   stock C2 /system + /vendor blobs
#                            (meta-skipjack android-system-data_skipjack-p.bb)
#   init.rc, *_contexts      Android init config (meta-skipjack android-init)

Name:       droid-hal-skipjack
Version:    0.1
Release:    2
Summary:    Droid HAL for Mobvoi TicWatch C2 (skipjack), from AsteroidOS prebuilts
License:    Proprietary
ExclusiveArch: armv7hl
Source0:    hybris-o-msm8909.tar.gz
Source1:    system-skipjack.tar.gz
Source2:    init.rc
Source3:    plat_property_contexts
Source4:    nonplat_property_contexts
Source5:    droid-hal-init.service
Source6:    android-boot-completed.service
Provides:   droid-hal
Provides:   droid-hal-skipjack-kernel-modules
Provides:   droid-hal-skipjack-img-boot
AutoReqProv: no

%global debug_package %{nil}
%global __strip /bin/true
%global __os_install_post %{nil}

%description
%{summary}.

%package devel
Summary:    Android headers for building libhybris and friends on skipjack
Provides:   droid-hal-devel
Provides:   android-headers
Provides:   pkgconfig(android-headers) = 8.0.0
AutoReqProv: no

%description devel
%{summary}.

%prep
%setup -q -c -T
tar xzf %{SOURCE0}
mkdir sys && tar xzf %{SOURCE1} -C sys

%build

%install
# Hybris Android userspace. AsteroidOS' init.rc uses /usr/libexec/hal-droid;
# Sailfish packages look in /usr/libexec/droid-hybris.
mkdir -p %{buildroot}/usr/libexec
cp -a usr/libexec/hal-droid %{buildroot}/usr/libexec/
ln -s hal-droid %{buildroot}/usr/libexec/droid-hybris

# Stock blobs, mounted nowhere else on this watch (no system partition used).
cp -a sys/system %{buildroot}/system
ln -s system/vendor %{buildroot}/vendor
# Some vendor binaries (wcnss_service) lost +x in the AsteroidOS archive.
chmod 0755 %{buildroot}/system/vendor/bin/* %{buildroot}/system/bin/* 2>/dev/null || :

# Android init configuration.
install -m 0644 %{SOURCE2} %{buildroot}/init.rc
install -m 0644 %{SOURCE3} %{SOURCE4} %{buildroot}/
mkdir -p %{buildroot}/firmware %{buildroot}/persist %{buildroot}/data
mkdir -p %{buildroot}/%{_unitdir}/graphical.target.wants
install -m 0644 %{SOURCE5} %{buildroot}/%{_unitdir}/
ln -s ../droid-hal-init.service %{buildroot}/%{_unitdir}/graphical.target.wants/
mkdir -p %{buildroot}/%{_userunitdir}/user-session.target.wants
install -m 0644 %{SOURCE6} %{buildroot}/%{_userunitdir}/
ln -s ../android-boot-completed.service %{buildroot}/%{_userunitdir}/user-session.target.wants/

# Headers for -devel.
mkdir -p %{buildroot}/usr/include/android %{buildroot}%{_libdir}/pkgconfig
cp -a include/* %{buildroot}/usr/include/android/
mv %{buildroot}/usr/include/android/android-headers.pc %{buildroot}%{_libdir}/pkgconfig/

%files
%defattr(-,root,root,-)
/usr/libexec/hal-droid
/usr/libexec/droid-hybris
/system
/vendor
/init.rc
/plat_property_contexts
/nonplat_property_contexts
%dir /firmware
%dir /persist
%dir /data
%{_unitdir}/droid-hal-init.service
%{_unitdir}/graphical.target.wants/droid-hal-init.service
%{_userunitdir}/android-boot-completed.service
%{_userunitdir}/user-session.target.wants/android-boot-completed.service

%files devel
%defattr(-,root,root,-)
/usr/include/android
%{_libdir}/pkgconfig/android-headers.pc
