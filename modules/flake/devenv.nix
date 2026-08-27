{ inputs, ... }:

{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      toml = pkgs.formats.toml { };
    in
    {
      devenv.shells.default = {
        imports = [
          inputs.devlib.devenvModules.git
          inputs.devlib.devenvModules.nix
          inputs.devlib.devenvModules.opentofu
          inputs.devlib.devenvModules.shell
          inputs.devlib.devenvModules.shikanime
          inputs.identities.devenvModules.default
        ];

        identities = {
          enable = true;
          nixtar.enable = true;
          telsha.enable = true;
        };

        github = {
          settings.workflows = {
            integration = {
              jobs.skaffold = {
                needs = [ "nix" ];
                secrets.CACHIX_AUTH_TOKEN = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
              };
              on.workflow_call.secrets.CACHIX_AUTH_TOKEN.required = lib.mkDefault true;
            };

            release = {
              jobs.skaffold = {
                needs = [ "nix" ];
                secrets.CACHIX_AUTH_TOKEN = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
              };
              on.workflow_call.secrets.CACHIX_AUTH_TOKEN.required = lib.mkDefault true;
            };

            skaffold.on.workflow_call.secrets.CACHIX_AUTH_TOKEN.required = lib.mkDefault true;

            wakabox = {
              name = "Wakabox";
              on.schedule = [
                { cron = "0 0 * * *"; }
              ];
              jobs.wakabox = {
                runs-on = "ubuntu-latest";
                steps = [
                  {
                    uses = "matchai/waka-box@v5.0.0";
                    env = {
                      GH_TOKEN = "\${{ secrets.WAKABOX_GITHUB_TOKEN }}";
                      GIST_ID = "\${{ vars.WAKABOX_GITHUB_GIST_ID }}";
                      WAKATIME_API_KEY = "\${{ secrets.WAKATIME_API_KEY }}";
                    };
                  }
                ];
              };
              permissions.contents = "read";
            };
          };

          workflows.skaffold = {
            enable = true;
            settings.setup-nix = {
              cachix-auth-token = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
              extra-platforms = "arm64";
            };
          };
        };

        packages =
          with pkgs;
          [
            age
            skaffold
          ]
          ++ lib.optional stdenv.hostPlatform.isLinux nixos-facter;

        sops = {
          enable = true;
          settings.creation_rules =
            let
              ashira = [
                "age1mel902ydxqv4yh798t5en336am9zwykapy8rtfvq4yprzr79t5wqzxe8ph"
              ];
              nixtar = [
                "age16tla3k0j70er5q526nrt6kqzzw7ds62dazlsknjxuhp7q4yq3ydqhxv8gy"
              ];
              fushi = [
                "age1fm9p4r5mug9rwk9puz7enpqap5xcrqeku6wp7atsajher559hads5wg03y"
              ];
              ishtar = [
                "age1m2z62rwhkldycej2ljggv9zfgp79xzzhdvkv7z8ajfhkrepxyvxsr3pgea"
              ];
              manash = [
                "age1f4yuh4j3gqafjduusfpxz3na9xtwth9s6gznq043mfex0zglp5jqkkdm64"
              ];
              minish = [
                "age1a4y27yc3tarlju7vg0lugnvs933wmk4hnw0udrn4499mts04qd0qvu7c3u"
              ];
              nalsha = [
                "age1evzl6xw2n96l2xyy7jed3zlv6d4jpmytp47rpp39pjju08tep4mqqa2au5"
              ];
              nemishi = [
                "age14c70j0haarha8e44zssrkd3rut0ygspqwnx42zfy0lv68he2pfms62h8a3"
              ];
              telsha = [
                "age1eak84xcr44yfqsg843rfu2xajxsyvjwh67a630htpnd0scy7yu5szjfh8d"
              ];

              nishir = ashira ++ fushi ++ manash ++ minish ++ nalsha ++ nemishi;

              workstations = ishtar ++ nixtar ++ telsha;

              identities =
                config.devenv.shells.default.identities.nixtar.ageKeys
                ++ config.devenv.shells.default.identities.telsha.ageKeys;
            in
            [
              {
                path_regex = "secrets/ashira.enc.yaml";
                age = ashira ++ identities;
              }
              {
                path_regex = "secrets/builder.enc.yaml";
                age = identities ++ nishir ++ workstations;
              }
              {
                path_regex = "secrets/fushi.enc.yaml";
                age = fushi ++ identities;
              }
              {
                path_regex = "secrets/machine.enc.yaml";
                age = identities ++ nishir ++ workstations;
              }
              {
                path_regex = "secrets/manash.enc.yaml";
                age = identities ++ manash;
              }
              {
                path_regex = "secrets/minish.enc.yaml";
                age = identities ++ minish;
              }
              {
                path_regex = "secrets/nalsha.enc.yaml";
                age = identities ++ nalsha;
              }
              {
                path_regex = "secrets/nemishi.enc.yaml";
                age = identities ++ nemishi;
              }
              {
                path_regex = "secrets/nixtar.enc.yaml";
                age = nixtar ++ identities;
              }
              {
                path_regex = "secrets/nishir.enc.yaml";
                age = identities ++ nishir;
              }
              {
                path_regex = "secrets/shikanime.enc.yaml";
                age = identities;
              }
              {
                path_regex = "secrets/telsha.enc.yaml";
                age = identities ++ telsha;
              }
            ];
        };

        treefmt.config.programs.typos.configFile =
          let
            configFile = toml.generate "typos.toml" {
              default.extend-words.facter = "facter";
            };
          in
          toString configFile;
      };
    };
}
