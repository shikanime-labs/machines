{
  home-manager.users.hermes = {
    home.stateVersion = "26.05";

    programs.git.enable = true;

    # The identities module renders git config from sops templates; the
    # home-manager sops instance decrypts with the node's age key.
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    identities = {
      enable = true;
      automata = {
        enable = true;
        git.enable = true;
      };
    };

    # CLI mail beside the Hermes email gateway, which already owns the Gmail
    # credentials. The password is read from the sops secret file at use time
    # (hermes-owned, 0400) so no secret lands in the rendered config.
    accounts.email.accounts.operator6o = {
      primary = true;
      address = "operator6o.automata@gmail.com";
      realName = "Operator 6O";
      userName = "operator6o.automata@gmail.com";
      passwordCommand = [
        "cat"
        "/run/secrets/hermes-agent-email-password"
      ];
      folders = {
        inbox = "INBOX";
        sent = "[Gmail]/Sent Mail";
        drafts = "[Gmail]/Drafts";
        trash = "[Gmail]/Trash";
      };
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
        authentication = "plain";
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
        authentication = "plain";
      };
      himalaya = {
        enable = true;
        settings.message.send.save-copy = true;
      };
    };

    programs.himalaya.enable = true;
  };

  users.users.hermes.extraGroups = [
    "adm"
    "systemd-journal"
  ];
}
