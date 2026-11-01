# Device configuration for Sailfish OS on the TicWatch C2 (skipjack).
# Minimal replacement for sailfish-wearable/droid-config-qualcomm-msm8909w-pie,
# matched to the AsteroidOS-prebuilt droid-hal-skipjack.

Name:       droid-config-skipjack
Version:    0.1
Release:    2
Summary:    Sailfish OS configuration for Mobvoi TicWatch C2 (skipjack)
License:    BSD
BuildArch:  noarch
Source0:    sparse.tar
Requires:   droid-hal-skipjack
Provides:   droid-config
Provides:   droid-config-skipjack-sailfish
Provides:   droid-config-skipjack-policy-settings
Provides:   droid-config-skipjack-preinit-plugin
Provides:   droid-config-skipjack-pulseaudio-settings
Provides:   droid-config-skipjack-bluez5
Provides:   droid-config-skipjack-flashing

%description
%{summary}.

%prep
%setup -q -c -T
tar xf %{SOURCE0}

%install
cp -a sparse/. %{buildroot}/
mkdir -p %{buildroot}/etc
cat > %{buildroot}/etc/hw-release <<'EOF'
NAME="Mobvoi TicWatch C2"
ID=skipjack
MER_HA_DEVICE=skipjack
MER_HA_VENDOR=mobvoi
VERSION="0.1 (AsteroidOS hybris userspace)"
SAILFISH_BUILD=4.6.0.13
EOF

%post
# Pick up the vendor dconf defaults (pixel ratio).
dconf update 2>/dev/null || :

%files
%defattr(-,root,root,-)
/etc/hw-release
/etc/udev/rules.d/998-droid-skipjack.rules
/etc/dconf/db/vendor.d/silica-configs.txt
/etc/usb-moded/usb-moded.ini
/var/lib/environment/compositor/droid-hal-device.conf
%dir %attr(0700,root,root) /root/.ssh
%attr(0600,root,root) /root/.ssh/authorized_keys
