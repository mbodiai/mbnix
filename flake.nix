{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # mbcli.url = "github:mboediai/mb";
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
            python311
            python311Packages.pip
            zsh
            bash
            git 
            fzf
            ripgrep
            uv
            gh
            glibcLocales
          ] ++ systemSpecificPkgs.extraPackages;
          
          shellHook = ''
          export ZDOTDIR="$PWD/.mbnix"
          if [ -f .mbnix/setup.sh ]; then
              source .mbnix
              source .mbnix/setup.sh
            fi
            if [ "$SHELL" = "${pkgs.zsh}/bin/zsh" ]; then
              exec $SHELL
            else
              export SHELL=$(which zsh)
              ${pkgs.zsh}/bin/zsh
              source .mbnix/.zshrc
            fi
        '';
        };
        packages.default = pkgs.stdenv.mkDerivation {
          name = "mb";
          src = ./.;
          buildInputs = with pkgs; [ 
            python311
            python311Packages.pip
            zsh
            bash
            git 
            fzf
            ripgrep
            gh
            uv
            glibcLocales
          ] ++ systemSpecificPkgs.extraPackages;

          installPhase = ''
            mkdir -p $out/bin
            echo "System: ${system}" > $out/bin/info
            chmod +x $out/bin/info
            export ZDOTDIR="$PWD/.mbnix"
            exec ${pkgs.zsh}/bin/zsh
            source .mbnix/.zshrc
          '';
        };
      });
}


