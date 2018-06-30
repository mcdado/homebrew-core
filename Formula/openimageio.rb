class Openimageio < Formula
  desc "Library for reading, processing and writing images"
  homepage "http://openimageio.org/"
  url "https://github.com/OpenImageIO/oiio/archive/Release-1.8.12.tar.gz"
  sha256 "93e807d7c77a5c4c12598cc7932aa08239bc4198e3e31dca0998a3e0ab163386"
  revision 1
  head "https://github.com/OpenImageIO/oiio.git"

  bottle do
    sha256 "eefecd97b65f627132358950bf4aa13efafef20a3ec0beb16486eea9c6964f59" => :high_sierra
    sha256 "fd0fdfe25dfa8035951c45282df5cac8a0cb0845efcd390090f0ffe3a1511726" => :sierra
    sha256 "06618c75ccf53674cb6c8f2e30f14eed25e308294a26e57f537b7036970bad44" => :el_capitan
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "boost-python"
  depends_on "boost-python3"
  depends_on "ffmpeg"
  depends_on "freetype"
  depends_on "giflib"
  depends_on "ilmbase"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libraw"
  depends_on "libtiff"
  depends_on "opencolorio"
  depends_on "openexr"
  depends_on "python"
  depends_on "webp"

  def install
    # -DUSE_OPENSSL=OFF can be removed in 1.9, see
    # https://github.com/Homebrew/homebrew-core/pull/22522#issuecomment-364831533
    args = std_cmake_args + %w[
      -DEMBEDPLUGINS=ON
      -DUSE_FIELD3D=OFF
      -DUSE_JPEGTURBO=OFF
      -DUSE_NUKE=OFF
      -DUSE_OPENCV=OFF
      -DUSE_OPENGL=OFF
      -DUSE_OPENJPEG=OFF
      -DUSE_OPENSSL=OFF
      -DUSE_PTEX=OFF
      -DUSE_QT=OFF
    ]

    mkdir "build-with-python2" do
      system "cmake", "..", "-DBoost_PYTHON_LIBRARIES=#{Formula["boost-python"].opt_lib}/libboost_python27-mt.dylib",
                            *args
      system "make", "install"
    end

    # CMake picks up the system's python dylib, even if we have a brewed one.
    py3ver = Language::Python.major_minor_version "python3"
    py3prefix = Formula["python3"].opt_frameworks/"Python.framework/Versions/#{py3ver}"

    ENV["PYTHONPATH"] = lib/"python#{py3ver}/site-packages"

    args << "-DPYTHON_EXECUTABLE=#{py3prefix}/bin/python3"
    args << "-DPYTHON_LIBRARY=#{py3prefix}/lib/libpython#{py3ver}.dylib"
    args << "-DPYTHON_INCLUDE_DIR=#{py3prefix}/include/python#{py3ver}m"

    # CMake picks up boost-python instead of boost-python3
    args << "-DBOOST_ROOT=#{Formula["boost"].opt_prefix}"
    args << "-DBoost_PYTHON_LIBRARIES=#{Formula["boost-python3"].opt_lib}/libboost_python#{py3ver.to_s.delete(".")}-mt.dylib"

    # This is strange, but must be set to make the hack above work
    args << "-DBoost_PYTHON_LIBRARY_DEBUG=''"
    args << "-DBoost_PYTHON_LIBRARY_RELEASE=''"

    # Need to make a second build dir, otherwise cmake picks up cached files
    # and builds against `boost-python`
    mkdir "build-with-python3" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    test_image = test_fixtures("test.jpg")
    assert_match "#{test_image} :    1 x    1, 3 channel, uint8 jpeg",
                 shell_output("#{bin}/oiiotool --info #{test_image} 2>&1")

    ["python", "python3"].each do |python|
      output = <<~EOS
        from __future__ import print_function
        import OpenImageIO
        print(OpenImageIO.VERSION_STRING)
      EOS
      assert_match version.to_s, pipe_output(python, output, 0)
    end
  end
end
