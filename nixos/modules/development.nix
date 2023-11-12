{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.dr460nixed.development;

  # Retrieve updpksums script from Arch - fix me: shebang
  updpkgsums = pkgs.writeScriptBin "updpkgsums" (builtins.readFile updpkgsumsSrc);
  updpkgsumsSrc = builtins.fetchurl {
    url = "https://gitlab.archlinux.org/pacman/pacman-contrib/-/raw/master/src/updpkgsums.sh.in";
    sha256 = "0c7fmvhdwkfmh715kwj4dkls3xzrzxxhqw2930r69yfzr1ijsppl";
  };
in {
  options.dr460nixed.development = {
    enable =
      mkOption
      {
        default = false;
        type = types.bool;
        description = mdDoc ''
          Enables commonly used development tools.
        '';
      };
  };

  config = mkIf cfg.enable {
    # Import secrets needed for development
    sops.secrets."api_keys/sops" = {
      mode = "0600";
      owner = config.users.users.nico.name;
      path = "/home/nico/.config/sops/age/keys.txt";
    };
    sops.secrets."api_keys/heroku" = {
      mode = "0600";
      owner = config.users.users.nico.name;
      path = "/home/nico/.netrc";
    };
    sops.secrets."api_keys/cloudflared" = {
      mode = "0600";
      owner = config.users.users.nico.name;
      path = "/home/nico/.cloudflared/cert.pem";
    };

    # Conflicts with virtualisation.containers if enabled
    boot.enableContainers = false;

    # Allow building sdcard images for Raspi
    nixpkgs.config.allowUnsupportedSystem = true;

    # Supply makepkg.conf for pacman
    environment = {
      etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";
      systemPackages = [updpkgsums];
    };

    # Wireshark
    programs.wireshark.enable = true;

    # Libvirt & Podman with docker alias
    virtualisation = {
      docker = {
        autoPrune = {
          enable = true;
          flags = ["--all"];
        };
        enable = true;
        enableOnBoot = false;
        package = pkgs.docker_24;
        storageDriver = "overlay2";
      };
      libvirtd = {
        enable = true;
        parallelShutdown = 2;
        qemu = {
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
          swtpm.enable = true;
        };
      };
      lxd.enable = false;
    };

    # Allow cross-compiling to aarch64
    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    # Configure nspawn containers
    systemd.nspawn."garuda" = {
      execConfig = {
        Boot = true;
      };
      enable = true;
      filesConfig = {
        Bind = ["/home/nico"];
      };
      networkConfig = {
        VirtualEthernet = false;
      };
    };

    # In case I need to fix my phone
    programs.adb.enable = true;
  };
}
