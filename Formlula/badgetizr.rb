class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.1.3.tar.gz"
    sha256 "75a2b06a34aac9ceade8da317f5cc10a2432f6d4d015b3248d1e5f2d5dde5e57"
    license "MIT"
  
    depends_on "yq"
    depends_on "gh"

    def install
      bin.install "badgetizr.sh" => "badgetizr"
    end
    
  end
  
