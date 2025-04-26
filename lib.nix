pkgs:
let
  objtype = name: getXML:
    {
      inherit getXML;
      writeXML = obj: pkgs.writeTextFile
        {
          name = "NixVirt-" + name + "-" + obj.name;
          text = getXML obj;
        };
    };
  guest-install = import ./guest-install.nix pkgs;
  stuff1 = { inherit guest-install; packages = pkgs; };
in
{
  xml = import generate-xml/xml.nix;
  domain = objtype "domain" (import generate-xml/domain.nix) // { templates = import ./templates/domain.nix stuff1; };
  network = objtype "network" (import generate-xml/network.nix) // { templates = import ./templates/network.nix stuff1; };
  pool = objtype "pool" (import generate-xml/pool.nix);
  volume = objtype "volume" (import generate-xml/volume.nix);
  inherit guest-install;
}
