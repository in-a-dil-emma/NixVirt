{
  description = "LibVirt domain management";

  inputs =
    {
      systems =
        {
          type = "github";
          owner = "nix-systems";
          repo = "default-linux";
        };
      nixpkgs =
        {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          ref = "nixos-24.11";
        };
    };

  outputs = { self, nixpkgs, systems }:
    let
      inherit (nixpkgs.lib)
        genAttrs
        ;

      genSystems = f: genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

      intermediates = genSystems ({ runCommand, python311, ... }@pkgs: rec {
        nixvirtPythonModulePackage = runCommand "nixvirtPythonModulePackage" { }
          ''
            mkdir  -p $out/lib/python3.11/site-packages/
            ln -s ${tool/nixvirt.py} $out/lib/python3.11/site-packages/nixvirt.py
          '' // { pythonModule = python311; };
        pythonInterpreterPackage = libvirt: python311.withPackages (ps:
          [
            (ps.libvirt.override { inherit libvirt; })
            ps.lxml
            ps.xmldiff
            nixvirtPythonModulePackage
          ]);
        setShebang = name: path: pkgs: pkgs.runCommand name { }
          ''
            sed -e "1s|.*|\#\!${pythonInterpreterPackage pkgs.libvirt}/bin/python3|" ${path} > $out
            chmod 755 $out
          '';
        virtdeclareFile = setShebang "virtdeclare" tool/virtdeclare pkgs;
        moduleHelperFile = setShebang "nixvirt-module-helper" tool/nixvirt-module-helper pkgs;
        testlib = mklib pkgs;
      });

      mklib = import ./lib.nix;
      modules = import ./modules.nix { inherit intermediates; };
    in
    {
      # in order to not break compatibility we have to keep the x86_64-linux lib output
      lib = intermediates."x86_64-linux".testlib // (genSystems ({ system, ... }: intermediates.${system}.testlib));

      apps = genSystems ({ libvirt, system, ... }: {
        virtdeclare =
          {
            type = "app";
            program = "${intermediates.${system}.virtdeclareFile}";
          };
        nixvirt-module-helper =
          {
            type = "app";
            program = "${intermediates.${system}.moduleHelperFile}";
          };
      });

      packages = genSystems ({ runCommand, system, libvirt, ... }: {
        default = runCommand "NixVirt" { }
          ''
            mkdir -p $out/bin
            ln -s ${intermediates.${system}.virtdeclareFile} $out/bin/virtdeclare
          '';
      });

      homeModules.default = modules.homeModule;
      nixosModules.default = modules.nixosModule;

      formatter = genSystems ({ nixpkgs-fmt, ... }: nixpkgs-fmt);

      checks = genSystems ({ system, ... }@pkgs: import checks/checks.nix pkgs nixpkgs.lib mklib);
    };
}
