{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs { 
          inherit system;
          config.allowUnfree = true;
        };

        # System-specific packages
        systemSpecificPkgs = if system == "aarch64-darwin" then {
          extraPackages = with pkgs; [
            darwin.apple_sdk.frameworks.Security
          ];
        } else {
          extraPackages = with pkgs; [
            linuxPackages.nvidia_x11
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python310
            zsh
            git 
            fzf
            ripgrep
            uv
            gh
          ] ++ systemSpecificPkgs.extraPackages;
          
          shellHook = ''
          echo "Running on ${system}"
          echo "ZDOTDIR is set to $ZDOTDIR"
          which zsh
          echo "Current shell: $0"
          export ZDOTDIR="$PWD/shell"
          if ! [ -z "$ZSH_VERSION" ]; then
            echo "Already in Zsh"
          else
            echo "Switching to Zsh"
            exec ${pkgs.zsh}/bin/zsh
            return 0
          fi
        '';
        };
        packages.default = pkgs.stdenv.mkDerivation {
          name = "mbenv";
          src = ./.;
          buildInputs = with pkgs; [ 
            zsh
            git 
            fzf
            ripgrep
            gh
          ] ++ systemSpecificPkgs.extraPackages;

          installPhase = ''
            mkdir -p $out/bin
            echo "System: ${system}" > $out/bin/info
            chmod +x $out/bin/info
            export ZDOTDIR="$PWD"
            exec ${pkgs.zsh}/bin/zsh
          '';
        };
      });
}


