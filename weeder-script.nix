{ pkgs,  # nixpkgs package set
  local-packages,  # list of local haskell packages in the project and their subdirectories
  hs-pkgs  # package set returned by `haskell-nix.stackProject`
}:

with rec {
  # returns a list of all components (library + exes + tests + benchmarks) for a package
  get-package-components = pkg: with pkgs.lib;
    optional (pkg ? library) pkg.library
    ++ attrValues pkg.exes
    ++ attrValues pkg.tests
    ++ attrValues pkg.benchmarks;

  # script code that collects 'dist-hi' directories from the listed components and puts them to ${dir}/dist-hi
  get-package-dist-hi = components: dir: pkgs.lib.concatStringsSep "\n" (
    [ "mkdir -p ${dir}/dist-hi" ]
    ++ builtins.map (cmp: ''
         cp -r ${cmp}/dist-hi/. ${dir}/dist-hi/
         chmod -R u+w ${dir}/dist-hi/  # make directories writeable because subsequent components may copy to the same directories
       '') components
  );

  # a script that collects 'dist-hi' directories from all local packages
  # and puts them into corresponding subdirectories
  get-project-dist-hi = pkgs.lib.concatStringsSep "\n" (
    map ({ name, subdirectory }:
      get-package-dist-hi (get-package-components hs-pkgs.${name}.components) subdirectory
    ) local-packages
  );


  # local package list mimicking the output of `stack query locals`
  local-packages-list = pkgs.writeText "locals" (builtins.toJSON (pkgs.lib.listToAttrs (
    map ({ name, subdirectory }:
      { name = name; value = { path = subdirectory; }; }
    ) local-packages
  )));

  # fake stack binary to be used be weeder, which gives `stack query locals` output.
  # real stack would also start fetching indexes and dependencies, we use this script to avoid that
  fake-stack = pkgs.writeShellScriptBin "stack" ''
    if [ "$1" != "query" -o "$2" != "locals" ]; then
      echo "error: fake stack called with unexpected arguments:" "$@" > /dev/stderr
      exit 1
    fi
    cat ${local-packages-list}
  '';


  # derivation which generates the final script for running weeder
  weeder-script = pkgs.writeScript "run-weeder.sh" ''
    # copy directories with '*.dump-hi' files to the package subdirectories
    ${get-project-dist-hi}

    # add fake stack to the path, it will be called by weeder to get local package list
    export PATH="${fake-stack}/bin:$PATH"

    # run weeder
    ${pkgs.haskellPackages.weeder}/bin/weeder stack.yaml --dist dist-hi
  '';
};

weeder-script
