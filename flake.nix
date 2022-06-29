{
  description = "Grxnola's NixOS configuration.";
  # NOTE: This file is tangled from readme.org. Do not edit by hand.
  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
      nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  
      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
  
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    };
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.cognac = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, lib, modulesPath, ... }: {
          fileSystems."/" = {
            device = "zroot/root";
            fsType = "zfs";
          };
          
          fileSystems."/home" = {
            device = "zroot/root/home";
            fsType = "zfs";
          };
          
          fileSystems."/nix" = {
            device = "zroot/root/nix";
            fsType = "zfs";
          };
          
          fileSystems."/boot" = {
            device = "/dev/disk/by-uuid/9864-170D";
            fsType = "vfat";
          };
          
          swapDevices = [{
            device = "/dev/disk/by-uuid/6dbfd189-bc54-4159-98d8-6bb0cb0e7bdf";
          }];
          
          hardware.cpu.amd.updateMicrocode =
            lib.mkDefault config.hardware.enableRedistributableFirmware;
          
          boot.initrd.availableKernelModules =
            [ "ahci" "xhci_pci" "usbhid" "sd_mod" ];
          boot.initrd.kernelModules = [ ];
          boot.kernelModules = [ "kvm-amd" ];
          boot.extraModulePackages = [ ];
          
          boot = {
            supportedFilesystems = [ "zfs" ];
            loader.grub.zfsSupport = true;
            loader.grub.efiSupport = true;
            loader.grub.device = "nodev";
            loader.efi.canTouchEfiVariables = true;
          };
          networking = {
              hostName = "cognac";
              hostId = "19828237"; # Should be a random number.
              nameservers = [ "1.1.1.1" ];
              useDHCP = false; # For some reason this is deprecated?
              interfaces.enp39s0.useDHCP = true;
              wireless.enable = false;
            };
          imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
          
          nixpkgs.overlays = [ (import self.inputs.emacs-overlay) ];
          
          services.xserver = {
            enable = true;
            videoDrivers = [ "amdgpu" ];
            desktopManager.xfce.enable = true;
            displayManager.defaultSession = "xfce";
            layout = "gb";
          };
          
          services.openssh = {
            enable = true;
            passwordAuthentication = false;
            permitRootLogin = "prohibit-password";
          };
          
          services.ratbagd.enable = true;
          
          sound.enable = true;
          hardware.pulseaudio.enable = true;
          programs.noisetorch.enable = true;
          
          hardware.opengl.driSupport = true;
          hardware.opengl.driSupport32Bit = true;
          
          time.timeZone = "Europe/London";
          i18n.defaultLocale = "en_GB.UTF-8";
          console = {
            font = "Lat2-Terminus16";
            keyMap = "uk";
          };
          
          services = {
          };
          
          users.users.dch = {
            shell = pkgs.fish;
            isNormalUser = true;
            home = "/home/dch";
            extraGroups = [ "wheel" "podman" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjqcbQfCraYffdGObPpVVNHTqOvie4ns5TfqoADP4mx"
            ];
          };
          
          environment.systemPackages = with pkgs; [
            curl inetutils vis wget zfs freetype
          ];
          
          # Some programs need SUID wrappers, can be configured further or are
          # started in user sessions.
          programs.fish.enable = true;
          programs.gnupg.agent = {
            enable = true;
            enableSSHSupport = true;
          };
          
          # nix & flakes
          nix = {
            package = pkgs.nixFlakes;
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          
            settings = {
              substituters = [ "https://nix-community.cachix.org" ];
              trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };
          };
          
          # System state
          system = {
            configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            stateVersion = "22.05";
            autoUpgrade = {
              enable = true;
              allowReboot = false;
            };
          };
        })
      ];
    };
  };
}
