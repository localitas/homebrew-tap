class LocalitasWorker < Formula
  desc "Localitas MLX inference worker — local AI on Apple Silicon"
  homepage "https://github.com/localitas"
  version "0.1.0"
  license "BSL-1.1"

  on_macos do
    on_arm do
      url "https://github.com/localitas/releases/releases/download/v#{version}/localitas-worker-#{version}-darwin-arm64.tar.gz"
      # sha256 "" # Update with actual checksum after first release
    end
  end

  depends_on "python@3.12"
  depends_on "localitas/tap/localitas-core"
  depends_on :macos

  def install
    libexec.install Dir["*"]

    (bin/"localitas-worker").write <<~SH
      #!/bin/bash
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/mlx_worker.py" "$@"
    SH
    chmod 0755, bin/"localitas-worker"
  end

  def post_install
    (var/"log/localitas").mkpath
  end

  service do
    run [
      opt_bin/"localitas-worker",
      "--port", "8091",
      "--manager-url", "http://localhost:8090",
    ]
    keep_alive crashed: true
    log_path var/"log/localitas/worker-stdout.log"
    error_log_path var/"log/localitas/worker-stderr.log"
    working_dir var/"localitas"
  end

  def caveats
    <<~EOS
      Start (after core is running):
        brew services start localitas-worker

      The worker registers with the core daemon automatically.

      Logs:
        tail -f #{var}/log/localitas/worker-stdout.log

      Models download automatically on first use.
    EOS
  end

  test do
    assert_predicate bin/"localitas-worker", :exist?
  end
end
