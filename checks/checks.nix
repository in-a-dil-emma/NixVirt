pkgs: lib: mklib:
let
  teststuff = pkgs // {
    writeTextFile = pkgs.writeTextFile;
    runCommand = name: args: script: "BUILD " + name;
    qemu = "QEMU_PATH";
    OVMFFull.fd = "OVMFFull_FD_PATH";
  };
  testlib = mklib teststuff;
  test = xlib: dirpath:
    let
      found = xlib.writeXML (import "${dirpath}/input.nix" testlib);
      expected = "${dirpath}/expected.xml";
    in
    pkgs.runCommand "check" { }
      ''
        diff -u ${expected} ${found}
        echo "pass" > $out
      '';
in
{
  network-empty = test testlib.network network/empty;
  network-bridge = test testlib.network network/bridge;

  domain-empty = test testlib.domain domain/empty;
  domain-linux = test testlib.domain domain/template-linux;
  domain-lxc = test testlib.domain domain/template-lxc;
  domain-windows-1 = test testlib.domain domain/template-windows-1;
  domain-windows-2 = test testlib.domain domain/template-windows-2;
  domain-windows-3 = test testlib.domain domain/template-windows-3;
  domain-win11 = test testlib.domain domain/win11;
  domain-issues = test testlib.domain domain/issues;

  pool-empty = test testlib.pool pool/empty;

  volume-typical = test testlib.volume volume/typical;

  # nix flake check tells me this is not a derivation
  # this error annoys me so much because nothing changed in terms of passing an instance of pkgs
  #virtio-iso = testlib.guest-install.virtio-win.iso;

  ovmf-secboot =
    pkgs.runCommand "ovmf-secboot" { }
      ''
        test -f ${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd
        test -f ${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd
        echo "pass" > $out
      '';
}
