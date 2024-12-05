class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.5.2.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "a932f3a762628b50f5883d617b800a47dca90b1f899b9e0f873d5d9f4412c584"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      libexec.install "badgetizr", "utils.sh"
      bin.install_symlink libexec/"badgetizr"
    end
    
  end
  
