{
  description =
    "srvyrexploR: Data Supplement for Exploring Complex Survey Data Analysis Using R";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

  };
  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        R-dev = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            pkgdown # To build the docs
            servr # To host the docs locally
          ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShell = with pkgs;
          mkShellNoCC {
            name = "R";
            buildInputs = [ R-dev pandoc ];

            # If for some reason you need to install
            # packages manually
            shellHook = ''
              mkdir -p "$(pwd)/_libs"
              export R_LIBS_USER="$(pwd)/_libs"
            '';
          };

        # Site Builder Helper Script
        packages.build-site = pkgs.writeScriptBin "build_site.R" ''
          #!/usr/bin/env Rscript
          pkgdown::build_site(preview = FALSE)
        '';

        # Site Hosting Helper Script
        packages.show-site = pkgs.writeScriptBin "show_site.R" ''
          #!/usr/bin/env Rscript
          servr::httw("docs/")
        '';

        # Build the site by running:
        # nix run .#build-site
        apps.build-site = {
          type = "app";
          program = "${self.packages.${system}.build-site}/bin/build_site.R";
        };

        # Preview site by running:
        # nix run .#show-site
        apps.show-site = {
          type = "app";
          program = "${self.packages.${system}.show-site}/bin/show_site.R";
        };
      });
}
