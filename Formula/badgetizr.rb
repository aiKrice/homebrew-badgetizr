class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.5.3.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "dfb861408f36540f35c6b9f190cf96745eae577880b6e2c1a15b7212431c9fe8"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      libexec.install "badgetizr", "utils.sh"
      bin.install_symlink libexec/"badgetizr"
    end
    
  end
  
