{
  config,
  pkgs,
  lib,
  ...
}: {
  # Individual settings
  imports = [
    ../../configurations/chaotic.nix
    ../../configurations/common.nix
    ../../configurations/desktops.nix
    ../../configurations/desktops/development.nix
    ../../configurations/desktops/games.nix
    ../../configurations/desktops/impermanence.nix
    ../../configurations/desktops/school.nix
    ../../configurations/desktops/slim-lair.nix
    ./hardware-configuration.nix
  ];

  # Use Lanzaboote for secure boot
  boot = {
    supportedFilesystems = ["zfs"];
    zfs = {
      enableUnstable = true;
      requestEncryptionCredentials = false;
    };
    # Needed to get the touchpad to work
    blacklistedKernelModules = ["elan_i2c"];
    # The new AMD Pstate driver & needed modules
    extraModulePackages = with config.boot.kernelPackages; [acpi_call zenpower];
    kernelModules = ["acpi_call" "amdgpu" "amd-pstate=passive"];
    kernelPackages = pkgs.linuxPackages_xanmod;
    kernelParams = ["initcall_blacklist=acpi_cpufreq_init"];
    lanzaboote = {
      configurationLimit = 20;
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    loader.efi.canTouchEfiVariables = true;
  };

  # Creates a second boot entry with LTS kernel and stable ZFS
  specialisation.safe.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    boot.zfs.enableUnstable = lib.mkForce false;
    system.nixos.tags = ["lts" "zfs-stable"];
  };

  # Network configuration & id for ZFS
  networking.hostName = "slim-lair";
  networking.hostId = "9c8011ee";

  # SSD
  services.fstrim.enable = true;

  # AMD device
  services.xserver.videoDrivers = ["amdgpu"];
  services.hardware.bolt.enable = false;

  # Enable OpenCL using rocm
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  # Workaround to enable HIP
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
  ];

  # RADV video decode
  environment.variables.RADV_VIDEO_DECODE = "1";

  # Virtualisation / Containerization
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
      options.zfs = {
        fsname = "zroot/containers";
        mountopt = "nodev";
      };
    };
  };

  # Enable the touchpad & secure boot
  environment.systemPackages = with pkgs; [libinput sbctl zenmonitor];

  # Neeeded for lzbt
  boot.bootspec.enable = true;

  # Fix the monitor setup
  home-manager.users.nico.home.file.".config/monitors.xml".source = ./monitors.xml;

  # A few secrets
  sops.secrets."machine-id/slim-lair" = {
    path = "/etc/machine-id";
    mode = "0600";
  };
  sops.secrets."gsconnect/slim-lair/private" = {
    path = "/home/nico/.config/gsconnect/private.pem";
    mode = "0600";
    owner = config.users.users.nico.name;
  };
  sops.secrets."gsconnect/slim-lair/certificate" = {
    path = "/home/nico/.config/gsconnect/certificate.pem";
    mode = "0600";
    owner = config.users.users.nico.name;
  };
  sops.secrets."ssh_keys/id_rsa" = {
    mode = "0600";
    owner = config.users.users.nico.name;
    path = "/home/nico/.ssh/id_rsa";
  };

  # NixOS stuff
  system.stateVersion = "22.11";
}
