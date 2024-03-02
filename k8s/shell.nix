{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    # setup for cpp projects.
    name = "cpp-env";
    nativeBuildInputs = with pkgs.buildPackages; [ 
        cmake
        pkg-config
        ninja
        gcc11
        clang_17
        llvm
        conan
    ];
    shellHook = ''
        zsh
        set -a
        source .env
        set +a
    '';
}
