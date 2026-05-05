#!/usr/bin/dash
printf '%s\n' "Verifying Mise is installed for complete dev env removal"
sudo pacman -S --noconfirm mise
sudo pacman -Rns --noconfirm php composer php-sqlite xdebug 2>/dev/null || true
printf '%s\n' "Removing Mise \& all dev envs"
sleep 3
printf '%s\n' "Running composer for final time before removal"
composer global remove laravel/installer 2>/dev/null || true
printf '%s\n' "Removing Ruby...\n"
mise uninstall ruby --all
mise rm -g ruby
rm -f ~/.gemrc
printf '%s\n' "Removing Node.js...\n"
mise uninstall node --all
mise rm -g node
printf '%s\n' "Removing Bun...\n"
mise uninstall bun --all
mise rm -g bun
printf '%s\n' "Removing Deno...\n"
mise uninstall deno --all
mise rm -g deno
printf '%s\n' "Removing Go...\n"
mise uninstall go --all
mise rm -g go
printf '%s\n' "Removing PHP...\n"
printf '%s\n' "Removing Laravel...\n"
printf '%s\n' "Removing Symfony CLI...\n"
sudo pacman -Rns --noconfirm symfony-cli 2>/dev/null || true
printf '%s\n' "Removing Python...\n"
mise uninstall python --all
mise rm -g python
rm -rf ~/.local/bin/uv ~/.local/bin/uvx ~/.cargo/bin/uv 2>/dev/null || true
printf '%s\n' "Removing Elixir/Erlang...\n"
mise uninstall elixir --all
mise uninstall erlang --all
mise rm -g elixir
mise rm -g erlang
printf '%s\n' "Removing Zig...\n"
mise uninstall zig --all
mise uninstall zls --all
mise rm -g zig
mise rm -g zls
printf '%s\n' "Removing Rust...\n"
rustup self uninstall -y 2>/dev/null || true
printf '%s\n' "Removing Java...\n"
mise uninstall java --all
mise rm -g java
printf '%s\n' "Removing .NET...\n"
mise uninstall dotnet --all
mise rm -g dotnet
printf '%s\n' "Removing OCaml...\n"
opam switch remove default -y 2>/dev/null || true
rm -rf ~/.opam 2>/dev/null || true
sudo rm -f /usr/local/bin/opam 2>/dev/null || true
printf '%s\n' "Removing Clojure...\n"
mise uninstall clojure --all
mise rm -g clojure
printf '%s\n' "Removing Scala...\n"
mise uninstall scala --all
mise uninstall scala-cli --all
mise rm -g scala
mise rm -g scala-cli
printf '%s\n' "Removing mise...\n"
sudo pacman -Rns --noconfirm mise
