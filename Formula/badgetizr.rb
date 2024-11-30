class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.2.0.tar.gz"
    sha256 "024892da67071348af9b4bef84be76c121ab8b0779dd099ae0c8478f9aec59a3"
    license "MIT"
  
    depends_on "yq"
    depends_on "gh"

    def install
      bin.install "badgetizr.sh" => "badgetizr"
    end
    
  end
  
