{
  description = "Odin lang patched to use system installed libraries on NixOS";

  # inputs = {
  #   nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  # };

  outputs = { self, nixpkgs, ... }: 
    let
        supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
        nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {
      overlay = final: prev: {

        odin = with final; llvmPackages.stdenv.mkDerivation rec {
          pname = "odin";
          version = "dev-2025-09";

          src = pkgs.fetchFromGitHub {
            owner = "odin-lang";
            repo = "Odin";
            rev = "${version}";
            hash = "sha256-PxegNMEzxytZtmhmzDgb1Umzx/9aUIlc9SDojRlZfsE=";
          };

          LLVM_CONFIG = "${llvmPackages.llvm.dev}/bin/llvm-config";

          dontConfigure = true;

          buildFlags = ["release"];

          nativeBuildInputs = [
            llvmPackages.bintools
            llvmPackages.llvm
            llvmPackages.clang
            llvmPackages.lld
            makeBinaryWrapper
            which
          ];

          patches = [
            ./raylib.patch
          ];

          postPatch = ''
            patchShebangs build_odin.sh
            sed -i 's/\\"dev-\$GIT_DATE\\"/\\"${version}-custom-nixos\\"/' build_odin.sh
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp odin $out/bin/odin

            mkdir -p $out/share
            cp -r {base,core,shared,vendor} $out/share

            make -C "$out/share/vendor/cgltf/src/"
            make -C "$out/share/vendor/stb/src/"
            make -C "$out/share/vendor/miniaudio/src/"

            wrapProgram $out/bin/odin \
              --set-default ODIN_ROOT $out/share \
              --prefix PATH : ${
              lib.makeBinPath (
                with llvmPackages; [
                  bintools
                  llvm
                  clang
                  lld
                ]
              )
            }

            runHook postInstall
          '';
        };

        # For compatibility with old flake
        odin-syslib = final.odin;

        ols = with final; stdenv.mkDerivation rec {
          pname = "ols";
          version = "0-unstable-2025-09-17-761f556";

          src = pkgs.fetchFromGitHub {
            owner = "DanielGavin";
            repo = "ols";
            rev = "761f556b80abe30d7b2b6c1c692d584eeff91795";
            hash = "sha256-eS5iq48f7Yw52cdr3ZvHExQZsckAS3mm5goYwey7DTw=";
          };

          postPatch = ''
            patchShebangs build.sh odinfmt.sh
            sed -i 's/^VERSION.*/VERSION="${version}"/' build.sh
          '';

          nativeBuildInputs = [ makeBinaryWrapper ];
          buildInputs = [ odin ];

          buildPhase = ''
            runHook preBuild

            ./build.sh && ./odinfmt.sh

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp ols odinfmt $out/bin/

            wrapProgram $out/bin/ols \
              --set-default ODIN_ROOT ${odin}/share

            runHook postInstall
          '';
        };
      };

      # Expose packages for selected systems
      packages = forAllSystems (system:
      {
          inherit (nixpkgsFor.${system}) odin ols odin-syslib;
      });

      # Default package for 'nix build'
      defaultPackage = forAllSystems (system: self.packages.${system}.odin);
    };
  # Indent matching `output`, we are not missing a }
}

# vim: noai:ts=2:sw=2
