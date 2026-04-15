{ writeTextFile }:

writeTextFile {
  name = "notify-lib";
  destination = "/lib/notify-lib.sh";
  text = builtins.readFile ./notify-lib.sh;
}
