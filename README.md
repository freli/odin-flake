# odin-flake

Flake to build and install Odin in NixOS.  

It includes:

- Some patches for batteries that did not fit
- Package for ols, so it can use the same Odin version

## Disclaimer!

This is a flake for my own convenience.  
Breaking changes might happen.

If you want to try it out, I recommend you pin it to a specific revision.  
And always check the changes before you update!

## Why?

NixOS is special. It does not come with a Linux FHS and it does not support
dynamic linking.

Which means the included vendor libraries in Odin does not work very well.

## Status

I've only used a few libraries:

- raylib
  - Needed patching to use `system`
  - NixOS 25.05 comes with raylib 5.5
    - Matches the bindings
- sdl3
  - Already use `system`
  - NixOS 25.05 comes with sdl3 3.2.10
    - Matches the bindings
- sdl2
  - Already use `system`
  - NixOS 25.05 comes with sdl2 using sdl2-compat, which uses sdl3 behind the scenes
    - Does not match the bindings, which uses 2.0.16
    - But it worked for my very limited test
    - For closer match, use an older nixpkgs
      - 2.0.16 never made it into nixpkgs
      - 2.0.22 is probably good enough

A lot of the other packages already use `system` and might work just fine, as long
as you have the libraries installed.

Some will need patching.  
I'll do them if/when I need them and write code to use them, so I can test.  
Or if someone supplies code to test with.

## Usage

Requires your NixOS to have flakes enabled.

Add this to your inputs:
￼￼￼
``` nix
inputs.odin-flake.url = "github:freli/odin-flake?rev=COMMIT_SHA";
```
￼￼
And then you can add it to your shell with

``` nix
inputs.odin-flake.packages."${system}".odin
inputs.odin-flake.packages."${system}".ols
```

And don't forget to also install the libraries you want to use!

## odin-flake-test

There is a companion repository: `odin-flake-test`  
I use it to test things.

It contains a flake for setting up a developer environment, with examples
using explicit nixpkgs versions to get library versions matching the bindings.

## Implementation notes

### buildPhase

There is no `buildPhase` for the Odin package.

As explained in [Nixpkgs Reference Manual - Standard Environment - Phases](https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases),
the default build phase will run `make <buildFlags>`, if the package contains
a `Makefile`.  
Odin does and it will run `build_odin.sh`.

### Replacing versions

Both Odin and ols try to set the version from `.git` but we don't have that.

For Odin, that means it will fall back to current year-month when building.  
In ols, it just fails and leave version empty.

In both cases, it's better to use the version we set in the flake.

For Odin, `-custom-nixos` is also added to the version, to indicate that it's
not a stock build.

## License

MIT No Attribution.
