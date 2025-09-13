class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.5.5.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "149cb0deb7c6d2ee3b83be5c555139b8bcf35d20c380efa120ebb291994cea38"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      libexec.install "badgetizr", "utils.sh"
      (bin/"badgetizr").write_env_script libexec/"badgetizr", UTILS_PATH: libexec/"utils.sh"
    end
    
  end
  
