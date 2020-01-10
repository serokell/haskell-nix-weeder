A bunch of hacks making [weeder](https://github.com/ndmitchell/weeder) work for projects built with [haskell.nix](https://github.com/input-output-hk/haskell.nix/)

## Usage example

Suppose you have a project with three packages in a layout like this (note that package name and directory name may differ):

```
super-project
|-- stack.yaml
|-- super-package.cabal
|-- …
|-- prelude
    |-- super-prelude.cabal
    |-- …
|-- super-tool
    |-- super-tool.cabal
    |-- …
```

Import this library, providing nixpkgs package set:

```nix
weeder-hacks = import (builtins.fetchTarball https://github.com/serokell/haskell-nix-weeder/archive/master.tar.gz) { pkgs = import <nixpkgs> {}; };
```

In the call to `haskell-nix.stackProject` add options for each package to generate .dump-hi files used by weeder and save them to the build output:

```nix
hs-pkgs = haskell-nix.stackProject {
  …
  modules = [{
    packages.super-package = {
      # tell the compiler to generate '.dump-hi' files
      package.ghcOptions = "-ddump-to-file -ddump-hi";

      # save '.dump-hi' files to $out
      postInstall = weeder-hacks.collect-dump-hi-files;
    };

    packages.super-prelude = {
      package.ghcOptions = "-ddump-to-file -ddump-hi";
      postInstall = weeder-hacks.collect-dump-hi-files;
    };

    packages.super-tool = {
      package.ghcOptions = "-ddump-to-file -ddump-hi";
      postInstall = weeder-hacks.collect-dump-hi-files;
    };
  }];
};
```

Invoke `weeder-script` derivation which generates a script for running weeder. Provide `hs-pkgs` and `local-packages` parameters:

```nix
weeder-script = weeder-hacks.weeder-script {
  # package set returned by `haskell-nix.stackProject`
  hs-pkgs = hs-pkgs;

  # names and subdirectories of local packages
  local-packages = [
    { name = "super-package"; subdirectory = "."; }
    { name = "super-prelude"; subdirectory = "prelude"; }
    { name = "super-tool"; subdirectory = "super-tool"; }
  ];
};
```

Run nix-build on the `weeder-script` derivation to generate the script, running the script will run weeder. Note that running the script will copy '.dump-hi' files locally, polluting your local directory.

``` shell
$ nix-build -A weeder-script -o run-weeder.sh  # generates the script
$ ./run-weeder.sh  # runs weeder
```

## About Serokell

This library is maintained and funded with ❤️ by [Serokell](https://serokell.io/).
The names and logo for Serokell are trademark of Serokell OÜ.

We love open source software! See [our other projects](https://serokell.io/community?utm_source=github) or [hire us](https://serokell.io/hire-us?utm_source=github) to design, develop and grow your idea!
