
{ stdenv, pkgs, fetchurl, writeShellScript, lib }:

stdenv.mkDerivation rec {
  pname = "tachidesk-server";
  version = "0.6.6";

  src = fetchurl {
    url = "https://github.com/Suwayomi/Tachidesk-Server/releases/download/v${version}/Tachidesk-Server-v${version}-r1159.jar";
    sha256 = "sha256-onqZ+9X/cg4apzBHXRDtX2K+Z2zwzJOLSAuAg+9nNRo=";
    executable = true;
  };
  dontUnpack = true;
  dontBuild = true;
  jre = pkgs.jre;

  installPhase = let runScript = writeShellScript "tachidesk-run-script" ''
    if [ -z "$1" ];
        then
            exec ${jre}/bin/java -jar ${src}
        else
            exec ${jre}/bin/java -Dsuwayomi.tachidesk.config.server.rootDir="$1" -jar ${src}
    fi
  '';
  in ''
    mkdir -p $out/bin
    ln -s ${runScript} $out/bin/tachidesk
  '';

  meta = with lib; {
    description = "Run a server that aggregates manga from a variety of sources.";
    homepage = "https://github.com/Suwayomi/Tachidesk-Server";
    license = licenses.mpl20;
    maintainers = with maintainers; [ saggins ];
    platforms = with platforms; linux;
  };
}
