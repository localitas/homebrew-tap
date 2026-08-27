class LocalitasCore < Formula
  desc "Localitas core daemon — distributed home cloud platform"
  homepage "https://github.com/localitas"
  version "0.1.0"
  license "BSL-1.1"

  # Release assets are the raw, unversioned binaries published to the localitas
  # monorepo by `make release` (gh release create localitas-core-darwin-{arch}).
  on_macos do
    on_arm do
      url "https://github.com/localitas/localitas/releases/download/v#{version}/localitas-core-darwin-arm64"
      sha256 "ARM64_SHA256_PLACEHOLDER" # filled by `make release-update-formula`
    end
    on_intel do
      url "https://github.com/localitas/localitas/releases/download/v#{version}/localitas-core-darwin-amd64"
      sha256 "AMD64_SHA256_PLACEHOLDER" # filled by `make release-update-formula`
    end
  end

  depends_on :macos

  def install
    # The downloaded asset is the raw binary named per-arch; install it as
    # `localitas-core`.
    arch = Hardware::CPU.arm? ? "arm64" : "amd64"
    bin.install "localitas-core-darwin-#{arch}" => "localitas-core"

    # Log rotation script
    (bin/"localitas-logrotate").write <<~SH
      #!/bin/bash
      LOG_DIR="#{var}/log/localitas"
      find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null
      for f in "$LOG_DIR"/*.log; do
        [ -f "$f" ] && [ "$(stat -f%z "$f" 2>/dev/null || echo 0)" -gt 104857600 ] && : > "$f"
      done
    SH
    chmod 0755, bin/"localitas-logrotate"
  end

  def post_install
    (var/"localitas").mkpath
    (var/"localitas/apps").mkpath
    (var/"log/localitas").mkpath

    config_dir = Pathname.new("#{Dir.home}/.localitas")
    config_dir.mkpath

    config_file = config_dir/"config-core.yaml"
    unless config_file.exist?
      config_file.write <<~YAML
        core:
          server:
            http_port: 8090
          cluster:
            cluster_group: "localitas"
      YAML
    end

    # Daily log rotation at 3am
    system "crontab -l 2>/dev/null | grep -v localitas-logrotate | { cat; echo '0 3 * * * #{bin}/localitas-logrotate'; } | crontab -" rescue nil
  end

  service do
    run [
      opt_bin/"localitas-core",
      "--data-dir", "#{Dir.home}/.localitas",
    ]
    keep_alive crashed: true
    log_path var/"log/localitas/core-stdout.log"
    error_log_path var/"log/localitas/core-stderr.log"
    working_dir var/"localitas"
    environment_variables LOCALITAS_ENV: "production"
  end

  def caveats
    <<~EOS
      Start:
        brew services start localitas-core

      Web UI:
        http://localhost:8090

      Logs:
        tail -f #{var}/log/localitas/core-stdout.log

      Log rotation: daily at 3am, 7 day retention, 100MB max per file.

      Config: ~/.localitas/config-core.yaml
    EOS
  end

  test do
    assert_match "localitas", shell_output("#{bin}/localitas-core --help 2>&1")
  end
end
