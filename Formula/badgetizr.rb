class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.5.0.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "797d27a0a2614a97e4dd93fa61b8e6a16c58fb8bd0ad0f16d42a96486415b6c2"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      libexec.install "badgetizr", "utils.sh"
      bin.install_symlink libexec/"badgetizr"
    end
    
  end
  
