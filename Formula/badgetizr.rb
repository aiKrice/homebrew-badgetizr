class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/2.0.1.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "fae4a8a52b461343f79e50761caee90db4fa0251f44f2cf3500729808041f0e3"
    license "MIT"

    depends_on "yq"
    depends_on "gh"
    depends_on "glab"

    def install
      libexec.install "badgetizr", "utils.sh"
      libexec.install "providers"
      (bin/"badgetizr").write_env_script libexec/"badgetizr", UTILS_PATH: libexec/"utils.sh"
    end
    
  end
  
