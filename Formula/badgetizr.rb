class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.3.0.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "aafd3c410792cc32fa6903ba74619891f6a7b197a01609b3d8f44cbfa79d8038"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      bin.install "badgetizr.sh" => "badgetizr"
    end
    
  end
  
