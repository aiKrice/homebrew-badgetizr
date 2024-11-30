class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.1.3.tar.gz"
    sha256 "7161e53d6b455d824fa8f622dacd89a4bdedc98f90f8798de2ff62cabc92a951"
    license "MIT"
  
    depends_on "yq"
    depends_on "gh"

    def install
      bin.install "badgetizr.sh" => "badgetizr"
    end
    
  end
  
