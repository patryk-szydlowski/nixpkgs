{ stdenv, buildGoPackage, fetchFromGitHub, makeWrapper
, git, coreutils, bash, gzip, openssh
, sqliteSupport ? true
}:

with stdenv.lib;

buildGoPackage rec {
  name = "gogs-${version}";
  version = "0.11.29";

  src = fetchFromGitHub {
    owner = "gogits";
    repo = "gogs";
    rev = "v${version}";
    sha256 = "1xn1b4dxf7r8kagps3yvp31zskfxn50k1gfic9abl4kjwpwk78c0";
  };

  patchPhase = ''
    patchShebangs .
    '';

  nativeBuildInputs = [ makeWrapper ];

  buildFlags = optionalString sqliteSupport "-tags sqlite";

  outputs = [ "bin" "out" "data" ];

  postInstall = stdenv.lib.optionalString stdenv.isDarwin ''
    install_name_tool -delete_rpath $out/lib $bin/bin/gogs
  '' + ''
    mkdir $data
    cp -R $src/{public,templates} $data

    wrapProgram $bin/bin/gogs \
      --prefix PATH : ${makeBinPath [ bash git gzip openssh ]} \
      --run 'export GOGS_WORK_DIR=''${GOGS_WORK_DIR:-$PWD}' \
      --run 'mkdir -p "$GOGS_WORK_DIR" && cd "$GOGS_WORK_DIR"' \
      --run "ln -fs $data/{public,templates} ."
  '';

  goPackagePath = "github.com/gogits/gogs";

  meta = {
    description = "A painless self-hosted Git service";
    homepage = https://gogs.io;
    license = licenses.mit;
    maintainers = [ maintainers.schneefux ];
  };
}
