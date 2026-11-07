{ pkgs }:

# The fleet's directory plugins. Hosts symlink them into $HERMES_HOME at
# activation; the brain image bakes them in, because a container has no
# activation step. Same derivations either way.
{
  hermes-lcm = pkgs.callPackage ../hermes-plugin-lcm { };
  memory-wiki = pkgs.callPackage ../hermes-plugin-memory-wiki { };
  ponytail = pkgs.callPackage ../hermes-plugin-ponytail { };
}
