{
  config,
  lib,
  pkgs,
  ...
}: let
  base16-schemes = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "base16-schemes";
    rev = "cf6bc89";
    sha256 = "U9pfie3qABp5sTr3M9ga/jX8C807FeiXlmEZnC4ZM58=";
  };
in {
  # Style the operating system using Stylix
  stylix.base16Scheme = "${base16-schemes}/gruvbox-dark-medium.yaml";
  stylix.image = builtins.fetchurl {
    url = "https://gruvbox-wallpapers.onrender.com/wallpapers/anime/wall.jpg";
    sha256 = "sha256-Dt5A3cA5M+g82RiZn1cbD7CVzAz/b8c1nTEpkp273/s=";
  };
  stylix.polarity = "dark";
  stylix.fonts = {
    serif = config.stylix.fonts.sansSerif;
    sansSerif = {
      package = pkgs.fira;
      name = "Fira Sans";
    };
    monospace = {
      package = pkgs.jetbrains-mono;
      name = "Jetbrains Mono Nerd Font";
    };
    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };

  # This is false by default for some reason
  stylix.targets.gnome.enable =
    lib.mkIf config.services.xserver.desktopManager.gnome.enable true;

  # These are not set by Stylix
  home-manager.users."nico".dconf.settings = lib.mkIf config.stylix.targets.gnome.enable {
    "org/gnome/desktop/wm/preferences" = {
      titlebar-font = "Fira Sans Bold 11";
    };
    "org/gnome/desktop/interface" = {
      document-font-name = "Fira Sans 11";
      monospace-font-name = "JetBrainsMono Nerd Font 10";
    };
  };
}
