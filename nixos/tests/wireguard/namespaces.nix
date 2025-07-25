{
  lib,
  kernelPackages ? null,
  ...
}:
let
  listenPort = 12345;
  socketNamespace = "foo";
  interfaceNamespace = "bar";
  node = {
    networking.wireguard.interfaces.wg0 = {
      listenPort = listenPort;
      ips = [ "10.10.10.1/24" ];
      privateKeyFile = "/etc/wireguard/private";
      generatePrivateKeyFile = true;
    };
  };
in
{
  name = "wireguard-with-namespaces";
  meta.maintainers = with lib.maintainers; [ asymmetric ];

  nodes = {
    # interface should be created in the socketNamespace
    # and not moved from there
    peer0 =
      { lib, pkgs, ... }:
      lib.attrsets.recursiveUpdate node {
        boot.kernelPackages = lib.mkIf (kernelPackages != null) (kernelPackages pkgs);
        networking.wireguard.interfaces.wg0 = {
          preSetup = ''
            ip netns add ${socketNamespace}
          '';
          inherit socketNamespace;
        };
      };
    # interface should be created in the init namespace
    # and moved to the interfaceNamespace
    peer1 =
      { lib, pkgs, ... }:
      lib.attrsets.recursiveUpdate node {
        boot.kernelPackages = lib.mkIf (kernelPackages != null) (kernelPackages pkgs);
        networking.wireguard.interfaces.wg0 = {
          preSetup = ''
            ip netns add ${interfaceNamespace}
          '';
          mtu = 1280;
          inherit interfaceNamespace;
        };
      };
    # interface should be created in the socketNamespace
    # and moved to the interfaceNamespace
    peer2 =
      { lib, pkgs, ... }:
      lib.attrsets.recursiveUpdate node {
        boot.kernelPackages = lib.mkIf (kernelPackages != null) (kernelPackages pkgs);
        networking.wireguard.interfaces.wg0 = {
          preSetup = ''
            ip netns add ${socketNamespace}
            ip netns add ${interfaceNamespace}
          '';
          inherit socketNamespace interfaceNamespace;
        };
      };
    # interface should be created in the socketNamespace
    # and moved to the init namespace
    peer3 =
      { lib, pkgs, ... }:
      lib.attrsets.recursiveUpdate node {
        boot.kernelPackages = lib.mkIf (kernelPackages != null) (kernelPackages pkgs);
        networking.wireguard.interfaces.wg0 = {
          preSetup = ''
            ip netns add ${socketNamespace}
          '';
          inherit socketNamespace;
          interfaceNamespace = "init";
        };
      };
  };

  testScript = ''
    start_all()

    for machine in peer0, peer1, peer2, peer3:
        machine.wait_for_unit("wireguard-wg0.service")

    peer0.succeed("ip -n ${socketNamespace} link show wg0")
    peer1.succeed("ip -n ${interfaceNamespace} link show wg0")
    peer2.succeed("ip -n ${interfaceNamespace} link show wg0")
    peer3.succeed("ip link show wg0")
  '';
}
