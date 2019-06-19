let
  _nixpkgs = import <nixpkgs> {};

  nixpkgsSrc = _nixpkgs.fetchFromGitHub {
    owner  = "NixOS";
    repo   = "nixpkgs-channels";
    rev    = "83ba5afcc9682b52b39a9a958f730b966cc369c5";
    sha256 = "0swh1i3rm8a7fij6drz11s5nyzr145yh4n17k0572pp8knpxw762";
  };

  nixpkgs = import nixpkgsSrc {};

  eventlog2htmlSrc = builtins.filterSource (path: type: baseNameOf path != "hakyll-eventlog") ./.. ;

  hp = nixpkgs.haskell.packages.ghc865.extend (sel: sup:
        { eventlog2html = sel.callCabal2nix "eventlog2html" eventlog2htmlSrc {}; });

  ghc = hp.ghcWithPackages (ps: with ps;
        [ ps.hakyll ps.eventlog2html
        ]);

  generator =
    nixpkgs.stdenv.mkDerivation {

      name = "blog-0.1";

      src = ./site.hs;
      LANG = "en_US.UTF-8";
      LOCALE_ARCHIVE = "${nixpkgs.glibcLocales}/lib/locale/locale-archive";

      preUnpack = ''mkdir generator'';

      unpackCmd = ''
        cp $curSrc ./generator/site.hs
        sourceRoot=generator
      '';

      buildInputs = [ ghc ];

      buildPhase = ''
        ghc -dynamic site.hs -o site
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp site $out/bin/generate-site
        '';


};
site =
  nixpkgs.stdenv.mkDerivation {

    name = "blog-0.1";

    src = nixpkgs.lib.cleanSource ./.;
    LANG = "en_US.UTF-8";
    LOCALE_ARCHIVE = "${nixpkgs.glibcLocales}/lib/locale/locale-archive";

    buildInputs = [ generator ];

    preConfigure = ''
      export LANG="en_US.UTF-8";
      '';

    buildPhase = ''
      generate-site build
    '';

    installPhase = ''
      cp -r _site $out
    '';
  };
in
  { inherit site; }
  #hakyll = nixpkgs.haskell.packages.ghc822.hakyll; }


