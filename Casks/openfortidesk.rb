cask "openfortidesk" do
  version "0.3.0-rc.4"
  sha256 "31fa776e8387e8f9a197d5f9813b92a259901c8a7dc99208204685efbe6923db"

  url "https://github.com/luizmz94/openfortidesk/releases/download/v#{version}/OpenFortiDesk-#{version}-arm64.zip"
  name "OpenFortiDesk"
  desc "Native GUI for the original openfortivpn"
  homepage "https://github.com/luizmz94/openfortidesk"

  livecheck do
    url :url
    strategy :github_releases do |json|
      json.filter_map do |release|
        next if release["draft"]

        release["tag_name"][/\Av?(\d+\.\d+\.\d+(?:-rc\.\d+)?)\z/i, 1]
      end
    end
  end

  depends_on arch: :arm64
  depends_on formula: "openfortivpn"
  depends_on macos: :ventura

  app "OpenFortiDesk.app"

  preflight_steps do
    if_path_exists "VPNGUI.app", base: :appdir do
      # Homebrew runs this in its sandbox: read-only, requires the old service removed.
      run "OpenFortiDesk.app/Contents/MacOS/VPNGUI",
          args:         ["--prepare-for-legacy-migration"],
          base:         :staged_path,
          sudo:         false,
          must_succeed: true
      move "VPNGUI.app", "~/Library/Application Support/VPNGUI/Backups/VPNGUI-before-OpenFortiDesk.app",
           source_base: :appdir,
           overwrite:   false
    end
  end

  # In Homebrew's sandbox: refuses while the app runs, keeps the registration.
  uninstall_preflight_steps do
    run "OpenFortiDesk.app/Contents/MacOS/VPNGUI",
        args:         ["--prepare-for-maintenance"],
        base:         :appdir,
        sudo:         false,
        must_succeed: true
  end

  caveats <<~EOS
    First use: open OpenFortiDesk, activate its service, approve it in System
    Settings and approve the protected openfortivpn runtime.

    Before brew upgrade: quit OpenFortiDesk with Sair (this disconnects its
    VPNs). The service registration is kept for the upgraded app.

    Before brew uninstall: open the app, use Configurações… > Serviço
    privilegiado > Remover serviço, then quit with Sair. Homebrew's sandbox does
    not allow removing the registration.

    Migrating from VPNGUI.app: remove its service first the same way.

    Release candidate: isolated root lifecycle integration is not yet validated.
    Profiles, Keychain secrets and the protected runtime survive uninstall. Do not
    reopen the app during an upgrade. See SECURITY.md before removing managed root
    files.
  EOS
end
