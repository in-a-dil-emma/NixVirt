pkgs:
{
  virtio-win.iso =
    pkgs.runCommand "virtio-win.iso" { } "${pkgs.cdrtools}/bin/mkisofs -l -V VIRTIO-WIN -o $out ${pkgs.virtio-win}";
}
