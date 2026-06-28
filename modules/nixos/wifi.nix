{ config, ... }:

{
  networking.wireless = {
    enable = true;
    secretsFile = config.sops.templates.wifi.path;
    networks = {
      "SFR_E368".pskRaw = "ext:psk_sfr_e368";
      "SFR_E368_5SGHZ".pskRaw = "ext:psk_sfr_e368_5ghz";
      "Vintage Korean".pskRaw = "ext:psk_vintage_korean";
    };
  };

  sops = {
    secrets = {
      wifi-sfr-e368 = {
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
        restartUnits = [ "wpa_supplicant.service" ];
      };
      wifi-sfr-e368-5ghz = {
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
        restartUnits = [ "wpa_supplicant.service" ];
      };
      wifi-vintage-korean = {
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
        restartUnits = [ "wpa_supplicant.service" ];
      };
    };
    templates = {
      wifi = {
        content = ''
          psk_sfr_e368=${config.sops.placeholder.wifi-sfr-e368}
          psk_sfr_e368_5ghz=${config.sops.placeholder.wifi-sfr-e368-5ghz}
          psk_vintage_korean=${config.sops.placeholder.wifi-vintage-korean}
        '';
        restartUnits = [ "wpa_supplicant.service" ];
      };
    };
  };
}
