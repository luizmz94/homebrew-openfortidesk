cask "openfortidesk" do
  version "0.3.0-rc.2"
  sha256 "16dc6088fdcbfd8db230aaabf1bfe819e4989e3209a65f95454ce68e07c9d34d"

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
      run "OpenFortiDesk.app/Contents/MacOS/VPNGUI",
          args:         ["--prepare-for-maintenance"],
          base:         :staged_path,
          sudo:         false,
          must_succeed: true
      move "VPNGUI.app", "~/Library/Application Support/VPNGUI/Backups/VPNGUI-before-OpenFortiDesk.app",
           source_base: :appdir,
           overwrite:   false
    end
  end

  uninstall_preflight_steps do
    run "OpenFortiDesk.app/Contents/MacOS/VPNGUI",
        args:         ["--prepare-for-maintenance"],
        base:         :appdir,
        sudo:         false,
        must_succeed: true
  end

  caveats <<~EOS
    First use: open OpenFortiDesk, activate its service, approve it in System
    Settings and approve the protected openfortivpn runtime. Release candidate:
    isolated root lifecycle integration is not yet validated. Profiles, Keychain
    secrets and the protected runtime survive uninstall. Do not reopen the app
    during an upgrade. See SECURITY.md before removing managed root files.
  EOS
end
