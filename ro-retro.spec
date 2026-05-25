Name:           ro-retro
Version:        1.0.0
Release:        1%{?dist}
Summary:        Retro oyunlar için oyun merkez uygulaması (Ro-ASD - Flutter)
BuildArch:      noarch

License:        MIT
URL:            https://github.com/Hyperinflation/Ro-Retro
Source0:        %{name}-%{version}.tar.gz

# We require python3 to run our local webserver and xdg-utils to open browser
Requires:       python3
Requires:       xdg-utils
Requires:       hicolor-icon-theme

%description
Ro-Retro, Ro-ASD ve Fedora sistemleri için özel olarak tasarlanmış, Epic Games 
Hub benzeri arayüze sahip, kapalı mor ve siyah temalı bir retro oyun merkezidir.
Kullanıcıların ROM dosyalarını içe aktarmasına, kütüphane araması yapmasına ve
EmulatorJS ile WebAssembly üzerinden doğrudan tarayıcıda oynamasına izin verir.
Bu sürüm tamamen Flutter çerçevesi (framework) kullanılarak geliştirilmiştir.

%prep
%autosetup

%build
# Nothing to compile here. The Flutter app is pre-compiled to Web assets.

%install
# Create install directories in the build root
mkdir -p %{buildroot}%{_datadir}/%{name}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/scalable/apps

# Copy compiled web assets and the Python launcher
cp -r build/web/* %{buildroot}%{_datadir}/%{name}/
cp launcher.py %{buildroot}%{_datadir}/%{name}/

# Create executable bash wrapper in /usr/bin
cat << 'EOF' > %{buildroot}%{_bindir}/%{name}
#!/bin/bash
# Executable launcher for Ro-Retro Game Hub
python3 %{_datadir}/%{name}/launcher.py "$@"
EOF
chmod +x %{buildroot}%{_bindir}/%{name}

# Copy the desktop menu entry
cp %{name}.desktop %{buildroot}%{_datadir}/applications/

# Copy the scalable application icon
cp web/assets/icon.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg

%changelog
* Mon May 25 2026 Developer <dev@ro-asd.org> - 1.0.0-1
- Initial release of Ro-Retro Game Hub (Flutter Edition)
