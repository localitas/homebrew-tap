class LocalitasWorker < Formula
  desc "Localitas MLX inference worker — local AI on Apple Silicon"
  homepage "https://github.com/localitas"
  version "0.1.0"
  license "BSL-1.1"

  depends_on "localitas/tap/localitas-core"
  depends_on :macos
  depends_on arch: :arm64

  def install
    core_bin = Formula["localitas-core"].opt_bin/"mlx-worker-swift"
    if core_bin.exist?
      bin.install_symlink core_bin => "localitas-worker"
    else
      odie "mlx-worker-swift not found in localitas-core. Reinstall localitas-core on Apple Silicon."
    end
  end

  def post_install
    (var/"log/localitas").mkpath
  end

  service do
    run [
      opt_bin/"localitas-worker",
      "--port", "8091",
      "--core-url", "http://localhost:8090",
    ]
    keep_alive crashed: true
    log_path var/"log/localitas/worker-stdout.log"
    error_log_path var/"log/localitas/worker-stderr.log"
    working_dir var/"localitas"
    environment_variables LOCALITAS_ENV: "production"
  end

  def caveats
    <<~EOS
      Start (after core is running):
        brew services start localitas-worker

      The MLX Swift worker registers with the core daemon automatically.
      Requires Apple Silicon (arm64).

      Logs:
        tail -f #{var}/log/localitas/worker-stdout.log

      Models download automatically on first use.
    EOS
  end

  test do
    assert_predicate Formula["localitas-core"].opt_bin/"mlx-worker-swift", :exist?
  end
end
