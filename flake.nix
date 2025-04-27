{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-compat, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        template = pkgs.buildGoModule {
          pname = "template";
          version = "v0.0.1";
          src = ./src;
          vendorHash = "sha256-ia8osexXnsGlAh7HpXOTSsWj0Dr0vrndO42cH3WKVpo=";

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            dir="$GOPATH/bin"
            [ -e "$dir" ] && cp $dir/src $out/bin/template

            runHook postInstall
          '';
        };
        resume = pkgs.stdenv.mkDerivation {
          pname = "resume";
          version = "v0.0.1";
          src = builtins.path { path = ./.; name = "Resume"; };
          buildInputs = with pkgs; [
            gnumake
            nodePackages.prettier
            pandoc
            texliveSmall
            typst
          ];

          buildPhase = ''
            runHook preBuild

            TEMPLATE_EXEC=${template}/bin/template make

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/intermediate $out/resume
            cp index.html README.md $out
            cp -f intermediate/*.{tex,typ} $out/intermediate
            cp -f resume/*.{docx,html,md,pdf} $out/resume

            runHook postInstall
          '';
        };
        resume-shell = pkgs.mkShell {
          inputsFrom = [ resume template ];
        };
      in
      {
        packages = {
          inherit resume template;
          default = resume;
        };
        devShells = {
          inherit resume-shell;
          default = resume-shell;
        };
      }
    );
}
