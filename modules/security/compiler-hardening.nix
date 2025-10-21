{ config, lib, pkgs, ... }:

{
  ##########################################################################
  # 📦 Compiler Hardening - Fortified Compilation Flags
  ##########################################################################

  # TODO: Re-enable compiler hardening overlay once compatible with newer Nix versions
  # The withCFlags approach causes "env attribute conflict" errors in Nix 2.18+
  # Alternative: Use hardeningEnable/hardeningDisable per-package or nixpkgs.config.hardening

  # nixpkgs.overlays = [(self: super: {
  #   stdenv = super.stdenvAdapters.withCFlags [
  #     "-D_FORTIFY_SOURCE=3"
  #     "-fstack-protector-strong"
  #     "-fPIE"
  #     "-Wformat"
  #     "-Wformat-security"
  #     "-Werror=format-security"
  #     "-fstack-clash-protection"
  #     "-fcf-protection=full"
  #   ] (super.stdenvAdapters.withCFlags [
  #     "-pie"
  #     "-Wl,-z,relro"
  #     "-Wl,-z,now"
  #     "-Wl,-z,noexecstack"
  #   ] super.stdenv);
  # })];

  # Enable hardening flags in stdenv
  environment.variables = {
    HARDENING_ENABLE = "fortify stackprotector pic strictoverflow format relro bindnow";
  };
}
