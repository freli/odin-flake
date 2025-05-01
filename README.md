# odin-syslib-flake

## Disclaimer!

This is a flake for my own convenience.  
It might work for you. Or not.

I'm likely to make breaking changes.  
Both intentionally and unintentionally.

**You use this flake on your own risk!**

If you *do* use it, I highly recommend you lock to a specific commit.  
And check the commit history before you update.

## Status

I've only used Raylib myself, so that is the only one patched at the moment.

Patched and tested:
- Raylib

Patched but not tested:
- N/A

Not patched:
- Everything else

## Why?

NixOS is special. It does not come with a Linux FHS and it does not support dynamic linking.

Which means the included vendor libraries in Odin does not work very well.

For Raylib, I needed a workaround for it to find X11 libraries, or I could not open a window.  
And then it failed to initialize audio, so I could not play sounds. I could not find a workaround for that.

Downloading Odin to a local folder, I realized I could just change the vendor library to load Raylib from system instead of from the Odin package.  
So I created a flake to apply that patch and install it in the system.

## Usage

Requires your NixOS to have flakes enabled.

Add this to your inputs:
￼￼￼
``` nix
inputs.odin-syslib-flake.url = "github:freli/odin-syslib-flake?rev=COMMIT_SHA";
```
￼￼
And then you can add it to your system with

``` nix
environment.systemPackages = with pkgs; [
  inputs.odin-syslib-flake.packages."${system}".odin-syslib
```

And don't forget to also install the libraries you want to use!  
Check which version of Odin is used in the flake, go to [Tags · odin-lang/Odin](https://github.com/odin-lang/Odin/tags),
go into the matching version and dive into the vendors folder and see what versions they expect.  
Hopefully that matches what you will get from NixOS by default, otherwise you are on your own to figure out how to get the correct one.
