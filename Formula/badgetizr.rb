class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/3.1.1.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "fb4642523a3f1e863b102fc2f06e19eed1489d0c8c4ea94d4fe98c29c5239302"
    license "MIT"

    depends_on "yq"
    depends_on "gh"
    depends_on "glab"

    def install
      libexec.install "badgetizr", "utils.sh"
      libexec.install "providers"
      (bin/"badgetizr").write_env_script libexec/"badgetizr", UTILS_PATH: libexec/"utils.sh"
    end

    test do
      # Test that the binary is installed and executable
      assert_match version.to_s, shell_output("#{bin}/badgetizr --version")

      # Test help output
      assert_match "Usage:", shell_output("#{bin}/badgetizr --help")

      # Test error handling when required argument is missing
      assert_match "Error", shell_output("#{bin}/badgetizr 2>&1", 1)
    end
  end
  
