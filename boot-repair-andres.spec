Name:           boot-repair-andres
Version:        0.1.2.1
Release:        1%{?dist}
Summary:        Swiss-army live rescue tool: GRUB repair, display reset, initramfs, kernel, system update, boot freedom, diagnostics.
License:        MIT
URL:            https://github.com/AndresDev859674/boot-repair

Source1:        boot-repair-andres.desktop
Source2:        com.andresdev859674.boot-repair.policy
Source3:        boot-repair-andres-512.png
Source4:        boot-repair-andres-128.png

BuildRequires:  bash, git 

Requires:       bash, git
BuildArch:      noarch 

%description
%{summary}

%prep
%setup -q -T -n boot-repair

%install

install -Dm755 boot-repair.sh %{buildroot}/usr/bin/boot-repair

install -d -m755 %{buildroot}/usr/share/boot-repair-andres
cp -r art %{buildroot}/usr/share/boot-repair-andres/

%files
/usr/bin/boot-repair
/usr/share/boot-repair-andres/art
/usr/share/icons/hicolor/128x128/apps/boot-repair-andres.png
/usr/share/icons/hicolor/512x512/apps/boot-repair-andres.png
/usr/share/applications/boot-repair-andres.desktop
/usr/share/polkit-1/actions/com.andresdev859674.boot-repair.policy

%changelog
* Mon Oct 06 2025 andres8596 <andresdiazcraft@gmail.com> - 0.1.2.1-1
- Initial release for fedora.
