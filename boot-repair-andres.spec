Name:           boot-repair-andres
Version:        0.1.2.1
Release:        1%{?dist}
Summary:        Swiss-army live rescue tool: GRUB repair, display reset, initramfs, kernel, system update, boot freedom, diagnostics.
License:        MIT
URL:            https://github.com/AndresDev859674/boot-repair
Source:         https://github.com/AndresDev859674/boot-repair/archive/v%{version}/boot-repair-v%{version}.tar.gz

BuildRequires:  bash
Requires:       bash, git
BuildArch:      noarch 

%description
%{summary}

%prep
%setup -q -n boot-repair-%{version}

%install

install -Dm755 boot-repair.sh %{buildroot}/usr/bin/boot-repair-andres


install -d -m755 %{buildroot}/usr/share/boot-repair-andres
cp -r art %{buildroot}/usr/share/boot-repair-andres/


install -Dm644 boot-repair-andres-128.png %{buildroot}/usr/share/icons/hicolor/128x128/apps/boot-repair-andres.png
install -Dm644 boot-repair-andres-512.png %{buildroot}/usr/share/icons/hicolor/512x512/apps/boot-repair-andres.png


install -Dm644 boot-repair-andres.desktop %{buildroot}/usr/share/applications/boot-repair-andres.desktop


install -Dm644 com.andresdev859674.boot-repair.policy %{buildroot}/usr/share/polkit-1/actions/com.andresdev859674.boot-repair.policy

%files
/usr/bin/boot-repair-andres
/usr/share/boot-repair-andres/art
/usr/share/icons/hicolor/128x128/apps/boot-repair-andres.png
/usr/share/icons/hicolor/512x512/apps/boot-repair-andres.png
/usr/share/applications/boot-repair-andres.desktop
/usr/share/polkit-1/actions/com.andresdev859674.boot-repair.policy

%changelog
* Mon Oct 06 2025 andres8596 <andresdiazcraft@gmail.com> - 0.1.2.1-1
- Initial release for fedora.