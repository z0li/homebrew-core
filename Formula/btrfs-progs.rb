class BtrfsProgs < Formula
  desc "Userspace utilities to manage btrfs filesystems"
  homepage "https://btrfs.wiki.kernel.org/index.php/Main_Page"
  url "https://mirrors.edge.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v6.3.3.tar.xz"
  sha256 "4be30015760270d081642cc0023a8bfee7cb657a2aa055644e6a56d68695b96e"
  license all_of: [
    "GPL-2.0-only",
    "LGPL-2.1-or-later", # libbtrfsutil
  ]

  livecheck do
    url "https://mirrors.edge.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/"
    regex(/href=.*?btrfs-progs[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, x86_64_linux: "b38844787c5ee0c1424ede59a128bcddc246284938347f10703c3f2b6e18149e"
  end

  depends_on "pkg-config" => :build
  depends_on "python@3.11" => [:build, :test]
  depends_on "sphinx-doc" => :build
  depends_on "e2fsprogs"
  depends_on :linux
  depends_on "lzo"
  depends_on "systemd" # for libudev
  depends_on "util-linux"
  depends_on "zlib"
  depends_on "zstd"

  def install
    system "./configure", "--disable-python", *std_configure_args
    # Override `udevdir` since Homebrew's `pkg-config udev --variable=udevdir` output
    # is #{Formula["systemd"].lib}/udev. This path is used to install udev rules.
    system "make", "install", "V=1", "udevdir=#{lib}/udev"
    bash_completion.install "btrfs-completion" => "btrfs"

    # We don't use the make target `install_python` due to Homebrew's prefix scheme patch
    cd "libbtrfsutil/python" do
      python3 = "python3.11"
      system python3, *Language::Python.setup_install_args(prefix, python3)
    end
  end

  test do
    device = testpath/"test.img"
    system "truncate", "-s", "128M", device

    output = shell_output("#{bin}/mkfs.btrfs #{device}")
    assert_match(/Filesystem size:\s*128\.00MiB/, output)
    output = shell_output("#{bin}/btrfs filesystem show #{device}")
    assert_match "Total devices 1 FS bytes used 144.00KiB", output

    system "python3.11", "-c", "import btrfsutil"
  end
end
