let
  moreOverlays = [ (import ./oldnix/overlay.nix) ];

  # Read in the Niv sources
  sources = import ./nix/sources.nix { };
  # If ./nix/sources.nix file is not found run:
  #   niv init
  #   niv add input-output-hk/haskell.nix -n haskellNix

  # Fetch the haskell.nix commit we have pinned with Niv
  haskellNix = import sources.haskellNix { };
  # If haskellNix is not found run:
  #   niv add input-output-hk/haskell.nix -n haskellNix

  allOverlays = moreOverlays ++ haskellNix.nixpkgsArgs.overlays;

  # Import nixpkgs and pass the haskell.nix provided nixpkgsArgs
  pkgs = import
    # haskell.nix provides access to the nixpkgs pins which are used by our CI,
    # hence you will be more likely to get cache hits when using these.
    # But you can also just use your own, e.g. '<nixpkgs>'.
    haskellNix.sources.nixpkgs-2009
    # These arguments passed to nixpkgs, include some patches and also
    # the haskell.nix functionality itself as an overlay.
    (haskellNix.nixpkgsArgs // { overlays = allOverlays; });

  hsPkgs = pkgs.haskell-nix.project {
    # 'cleanGit' cleans a source directory based on the files known by git
    src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "PaymentServer";
      src = ./.;
    };
    modules = [{
      packages.PaymentServer.components.library.libs = [
        pkgs.pkg-config
        pkgs.libchallenge_bypass_ristretto_ffi
      ];
    }];
  };
in
  hsPkgs
  # pkgs.lib.recursiveUpdate hsPkgs {
  #   PaymentServer.setup.propagatedNativeBuildInputs = [
  #     pkgs.pkg-config
  #     pkgs.libchallenge_bypass_ristretto_ffi
  #   ];
  #   PaymentServer.components.library.propagatedNativeBuildInputs = [
  #     pkgs.pkg-config
  #     pkgs.libchallenge_bypass_ristretto_ffi
  #   ];
  # }
