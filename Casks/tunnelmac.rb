cask "tunnelmac" do
  arch arm: "arm64", intel: "x86_64"

  version "0.5.0-rc.6"
  sha256 arm:   "194cd956d3dc34046b85479439ef57f6032a2eaab6773357595ae368794f15b5",
         intel: "65098b10b18ffbfa74879b6d256085f12531f9d567c4c495aa8058f06ee3fe42"

  url "https://github.com/luizmz94/tunnelmac/releases/download/v#{version}/TunnelMac-#{version}-#{arch}.zip"
  name "TunnelMac"
  desc "Native GUI for openfortivpn, OpenVPN and WireGuard"
  homepage "https://github.com/luizmz94/tunnelmac"

  livecheck do
    url :url
    strategy :github_releases do |json|
      json.filter_map do |release|
        next if release["draft"]

        release["tag_name"][/\Av?(\d+\.\d+\.\d+(?:-rc\.\d+)?)\z/i, 1]
      end
    end
  end

  # Updates itself in the app (Sparkle); brew upgrade stays possible.
  auto_updates true
  depends_on formula: "openfortivpn"
  depends_on macos: :ventura

  app "TunnelMac.app"

  preflight_steps do
    if_path_exists "OpenFortiDesk.app", base: :appdir do
      # Homebrew runs this in its sandbox: read-only, requires the old service removed.
      run "TunnelMac.app/Contents/MacOS/VPNGUI",
          args:         ["--prepare-for-legacy-migration"],
          base:         :staged_path,
          sudo:         false,
          must_succeed: true
      move "OpenFortiDesk.app", "~/Library/Application Support/VPNGUI/Backups/OpenFortiDesk-before-TunnelMac.app",
           source_base: :appdir,
           overwrite:   false
    end
    if_path_exists "VPNGUI.app", base: :appdir do
      # Homebrew runs this in its sandbox: read-only, requires the old service removed.
      run "TunnelMac.app/Contents/MacOS/VPNGUI",
          args:         ["--prepare-for-legacy-migration"],
          base:         :staged_path,
          sudo:         false,
          must_succeed: true
      move "VPNGUI.app", "~/Library/Application Support/VPNGUI/Backups/VPNGUI-before-TunnelMac.app",
           source_base: :appdir,
           overwrite:   false
    end
  end

  # In Homebrew's sandbox: refuses while the app runs, keeps the registration.
  uninstall_preflight_steps do
    run "TunnelMac.app/Contents/MacOS/VPNGUI",
        args:         ["--prepare-for-maintenance"],
        base:         :appdir,
        sudo:         false,
        must_succeed: true
  end

  caveats <<~EOS
    First use: open TunnelMac, activate its service, approve it in System
    Settings and approve the protected openfortivpn, OpenVPN and/or
    wireguard-go runtime.

    Updates: TunnelMac offers new versions and installs them itself
    (Atualizar agora). To use brew upgrade instead, quit TunnelMac with Sair
    first (this disconnects its VPNs). The service registration is kept for
    the upgraded app either way.

    Before brew uninstall: open the app, use Configurações… > Serviço
    privilegiado > Remover serviço, then quit with Sair. Homebrew's sandbox does
    not allow removing the registration.

    Migrating from OpenFortiDesk.app or VPNGUI.app (same product, earlier
    name): remove its service first the same way, quit it, then
    brew uninstall --cask openfortidesk (if installed) before installing.

    Release candidate: isolated root lifecycle integration is not yet validated.
    Profiles, Keychain secrets and the protected runtime survive uninstall. Do not
    reopen the app during an upgrade. See SECURITY.md before removing managed root
    files.
  EOS
end
