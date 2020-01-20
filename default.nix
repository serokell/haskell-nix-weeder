{ pkgs  # nixpkgs package set
}:

{
  # script to collect all *.dump-hi files produced by the compiler
  # into $out/dist-hi directory, preserving directory structure
  collect-dump-hi-files = ''
    mkdir $out/dist-hi
    cd dist
    find . -type f -name '*.dump-hi' -print0 | ${pkgs.cpio}/bin/cpio --pass-through --null --make-directories $out/dist-hi
  '';

  # generates a script for running weeder
  weeder-script = { local-packages, hs-pkgs }: import ./weeder-script.nix { inherit pkgs local-packages hs-pkgs; };
}
