class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/2.1.0.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "1fd25255654afd8af5843487c39d49fc5878ba8d05e4d2acf8c695e96acc90e4"
    license "MIT"

    depends_on "yq"
    depends_on "gh"
    depends_on "glab"

    def install
      libexec.install "badgetizr", "utils.sh"
      libexec.install "providers"
      (bin/"badgetizr").write_env_script libexec/"badgetizr", UTILS_PATH: libexec/"utils.sh"
    end
    
  end
  
