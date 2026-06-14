class LocalitasMatter < Formula
  desc "Localitas Matter sidecar — smart home device controller for Homebase"
  homepage "https://github.com/localitas"
  version "0.1.0"
  license "BSL-1.1"

  on_macos do
    on_arm do
      url "https://github.com/localitas/releases/releases/download/v#{version}/localitas-matter-#{version}-darwin-arm64.tar.gz"
      # sha256 "" # Update with actual checksum after first release
    end
  end

  depends_on "python@3.12"
  depends_on :macos

  def install
    libexec.install Dir["*"]

    # Install Python dependencies into libexec
    system Formula["python@3.12"].opt_bin/"python3", "-m", "pip", "install",
           "--target=#{libexec}/vendor",
           "-r", "#{libexec}/requirements.txt"

    (bin/"localitas-matter").write <<~SH
      #!/bin/bash
      export PYTHONPATH="#{libexec}/vendor:#{libexec}"
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/main.py" "$@"
    SH
    chmod 0755, bin/"localitas-matter"
  end

  def post_install
    (var/"log/localitas").mkpath
    (var/"localitas/homebase/matter").mkpath
  end

  service do
    run [
      opt_bin/"localitas-matter",
      "--listen", ":9222",
    ]
    keep_alive crashed: true
    log_path var/"log/localitas/matter-stdout.log"
    error_log_path var/"log/localitas/matter-stderr.log"
    working_dir var/"localitas"
    environment_variables MATTER_STORAGE_DIR: var/"localitas/homebase/matter"
  end

  def caveats
    <<~EOS
      Start the Matter sidecar:
        brew services start localitas-matter

      The sidecar listens on port 9222 and is discovered by Homebase
      automatically via mDNS.

      Logs:
        tail -f #{var}/log/localitas/matter-stdout.log

      Matter fabric state is stored in:
        #{var}/localitas/homebase/matter/
    EOS
  end

  test do
    assert_predicate bin/"localitas-matter", :exist?
  end
end
