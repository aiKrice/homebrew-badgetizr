class Badgetizr < Formula
    desc "Badgetizr is a tool to allow custom badges automatically added and updated according the content of your pull request."
    homepage "https://github.com/aiKrice/homebrew-badgetizr"
    url "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/2.2.0.tar.gz"
    head "https://github.com/aiKrice/homebrew-badgetizr.git", branch: "master"
    sha256 "5762d68b5231356049053f68faae340827c3f789d4a3fa47226c2bb0e1b44c3f"
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
  
