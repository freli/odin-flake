{
    description = "Odin lang patched to use system installed libraries on NixOS";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        #nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };

    outputs = { self, nixpkgs, ... }: 
        let
            # Version and hash needs to be changed, when updating to newer Odin lang version
            version = "dev-2025-04";
            hash = "sha256-dVC7MgaNdgKy3X9OE5ZcNCPnuDwqXszX9iAoUglfz2k=";

            supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
            forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
            nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
        in
        {
            overlay = final: prev: {

                odin-syslib = with final; stdenv.mkDerivation rec {
                    pname = "odin-syslib";
                    inherit version;

                    src = pkgs.fetchFromGitHub {
                        owner = "odin-lang";
                        repo = "Odin";
                        rev = "${version}";
                        hash = "${hash}";
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

                    patches = [./odin-system-raylib.patch];

                    postPatch = ''
                        patchShebangs build_odin.sh
                        sed -i 's/\\"dev-\$(date +"%Y-%m")\\"/\\"${version}-syslib\\"/' build_odin.sh
                    '';

                    #nativeBuildInputs = [ autoreconfHook ];

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

            };

            # Provide some binary packages for selected system types.
            packages = forAllSystems (system:
            {
                inherit (nixpkgsFor.${system}) odin-syslib;
            });

            # The default package for 'nix build'. This makes sense if the
            # flake provides only one package or there is a clear "main"
            # package.
            defaultPackage = forAllSystems (system: self.packages.${system}.odin-syslib);

        };
    # Indent matching `output`, we are not missing a }
}

# vim: noai:ts=4:sw=4
