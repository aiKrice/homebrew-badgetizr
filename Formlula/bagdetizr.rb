class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.1.1.tar.gz"
    sha256 "42b29df7ee939ce597bb75d8c175d647fc15ca4f42c25d19ee2add5d328fb63c"
    license "MIT"
  
    depends_on "yq"
    depends_on "gh"

    def install
      bin.install "badgetizr.sh" => "badgetizr"
    end
    
  end
  
