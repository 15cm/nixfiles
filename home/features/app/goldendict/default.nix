{ pkgs, mylib, ... }:

let package = pkgs.goldendict;
in { home.packages = [ package ]; }
