# Privilege-escalation and auth gates for the graphical session: polkit
# authority + pkexec wrapper, fingerprint PAM, Bitwarden's system-auth policy.
{
  environment = {
    # Host polkit policy for Bitwarden's "Unlock with system authentication".
    # Required so the in-session polkit agent (Noctalia) can surface the
    # fingerprint/password gate for the native Bitwarden app.
    # No XML prolog: Nix indented strings keep the leading indent, and a
    # polkit/libxml2 declaration must sit at byte 0 or the policy is dropped.
    etc."polkit-1/actions/com.bitwarden.Bitwarden.policy".text = ''
      <policyconfig>
          <action id="com.bitwarden.Bitwarden.unlock">
              <description>Unlock Bitwarden</description>
              <message>Authenticate to unlock Bitwarden</message>
              <defaults>
                  <allow_any>no</allow_any>
                  <allow_inactive>no</allow_inactive>
                  <allow_active>auth_self</allow_active>
              </defaults>
          </action>
      </policyconfig>
    '';
  };

  # polkit authority daemon: required for the privilege prompts that
  # pkexec/gparted raise. Noctalia's built-in in-session agent (enabled via
  # programs.noctalia.settings.shell.polkit_agent in the home module) registers
  # against this daemon, so the external polkit-gnome agent is intentionally
  # omitted to avoid two agents racing for the session-bus registration.
  security.polkit.enable = true;

  # Re-enable the setuid pkexec wrapper so GUI tools that escalate via
  # pkexec (gparted, etc.) can gain root from a non-root desktop session.
  security.polkit.enablePkexecWrapper = true;

  # Fingerprint reader stack. Wires pam_fprintd into the auth path so the
  # polkit agent (Noctalia) can surface a fingerprint gate for Bitwarden's
  # "Unlock with system authentication". Enroll with `fprintd-enroll` as the user.
  services.fprintd.enable = true;
}
