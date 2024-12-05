class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.5.1.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "5590862324f8d9e902f1ae7c3b5b0a4122b707ebbbe49809f36f1a672fde3167"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      libexec.install "badgetizr", "utils.sh"
      bin.install_symlink libexec/"badgetizr"
    end
    
  end
  
