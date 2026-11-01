Name:           kotilo-shell
Version:        0.3.0
Release:        1%{?dist}
Summary:        Developer-focused Wayland desktop shell for Niri and Hyprland (Quickshell)
License:        GPL-3.0-or-later
URL:            https://github.com/kotilo-dev/kotilo-shell
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz
BuildArch:      noarch

Requires:       quickshell qt6-qtdeclarative qt6-qtwayland qt6-qtsvg qt6-qt5compat
Requires:       pipewire wireplumber upower NetworkManager bluez brightnessctl playerctl wl-clipboard jq python3
Requires:       rsms-inter-fonts jetbrains-mono-fonts-all
Recommends:     cliphist swww matugen

%description
Kotilo Shell is a developer-focused desktop shell built on Quickshell for the Niri and
Hyprland Wayland compositors: git status, AI coding agents, containers and open ports in
the bar; a pluggable command palette; a theme engine with Base16 and first-class themes.

%prep
%autosetup

%build
# nothing to compile (QML)

%install
install -dm755 %{buildroot}%{_datadir}/kotilo-shell
cp -r shell.qml Shell components services plugins themes assets config scripts %{buildroot}%{_datadir}/kotilo-shell/
install -dm755 %{buildroot}%{_bindir}
ln -s ../share/kotilo-shell/scripts/kotilo-agent %{buildroot}%{_bindir}/kotilo-agent
install -Dm644 README.md %{buildroot}%{_docdir}/%{name}/README.md

%files
%{_bindir}/kotilo-agent
%{_datadir}/kotilo-shell
%doc %{_docdir}/%{name}/README.md

%changelog
* Sun Nov 01 2026 Mustafa <kotilo.dev> - 0.3.0-1
- Release 0.3.0
* Fri Oct 31 2026 Mustafa <kotilo.dev> - 0.1.0-1
- Initial package
