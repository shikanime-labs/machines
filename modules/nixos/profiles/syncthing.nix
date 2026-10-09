{
  lib,
  ...
}:

let
  hubId = "FORKJBY-NKQUGQC-GAD6ISF-XRHOOYY-D5GYH26-WNHBS7E-K4JMTM6-354P4QO";
  hubName = "nishir";
  hubAddress = "tcp://syncthing.i.shikanime.studio:22000";
  peerIds = [
    "D2WRW6P-5ZJFMIC-DAF2LCD-4FJRE7J-3EDFFJ5-JD7GDFX-YUHB45P-VVT2QQ6"
    "HTR5WGC-KVK67K6-U3R3IKB-2KZZYMI-WKRR7P3-JMO6HPV-A3VNOEV-A6EN2QX"
    "JH274AZ-B7BVN4N-IGDWADJ-6754ZJ6-F5WGZYU-DELNCIH-X6LLPNO-PONQUAV"
    "2DDD6DU-VD5DL4B-R5A42WB-YYF6B2G-FYZOIH7-6SYXXCY-3SSAPBV-KZRFKQP"
  ];
  hubDevice = {
    addresses = [ hubAddress ];
    autoAcceptFolders = true;
    id = hubId;
  };
  peerDevices = builtins.listToAttrs (map (id: lib.nameValuePair id { inherit id; }) peerIds);
in
{
  services.syncthing = {
    configDir = "/var/lib/hermes/.config/syncthing";
    dataDir = "/var/lib/hermes";
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    user = "hermes";
    settings = {
      devices = peerDevices // {
        ${hubName} = hubDevice;
      };
      options.urAccepted = -1;
    };
  };
}
