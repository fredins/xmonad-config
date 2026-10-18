{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in {
      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          xmonad-config = pkgs.haskell.packages.ghc914.callCabal2nix "xmonad-config" ./. { };
        in {
          inherit xmonad-config;
          default = xmonad-config;
        });

      devShells = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hs = pkgs.haskell.packages.ghc914;
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              hs.ghc
              cabal-install
              pkg-config
              libx11
              libxext
              libxinerama
              libxrandr
              libxscrnsaver
              libice
              libsm
            ];
            shellHook = ''
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [
                libx11 libxext libxinerama libxrandr libxscrnsaver libice libsm
              ])}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            '';
          };
        });
    };
}
