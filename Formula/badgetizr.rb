class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.4.0.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "2f55cf5d48a7644f8c54605a77703f0bd4a17cee1f99b88dd0459f8cbc7061e8"
    license "MIT"

    depends_on "yq"
    depends_on "gh"

    def install
      bin.install "badgetizr.sh" => "badgetizr"
    end
    
  end
  
