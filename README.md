# dev-environment
An Ethereum development environment built in Docker that supports remote login and paired programming. The development environment I use on a daily basis.

## Features
* [truffle](http://truffleframework.com/docs/) for solidity development
* [testrpc](https://github.com/ethereumjs/testrpc) for local dapp testing
* vim with solidity syntax highlighting
* ssh server for secure remote development
* [wemux](https://github.com/zolrath/wemux) (multi-user tmux) for secure paired programming. Supports both read-only access to your session and allows multiple parties to work in the same terminal.
* Written to be taken apart, easily remove features you don't want.
* Home directory is preserved

## Installation
1. Install docker
2. Clone this repository
3. (Optional) take a look at the dockerfile and remove / add features. Don't like vim? Take out the whole ### VIM ### section and add / configure your favorite editor.
3. (Optional) check out the files in the customize directory and modify them to suit your needs.
4. From the root of this repository run `docker-compose up`. Port 64583 (specified and easily changed in docker-compose.yml) will now be listening for incoming ssh connection requests. If you want to login to this machine outside of localhost, be sure this port is open on your firewall, and port forwarding is set up correctly on your router.
5. Login to your machine
    - As root: `docker exec -it dev '/bin/bash'`
    - As the development user: `docker exec --user dev -it dev '/bin/bash'`
    - Using SSH `ssh dev@localhost -i <private key file>` (must have added a public key to `customize/authorized_keys-dev`, or have logged in as root and modified `/etc/ssh/authorized_keys/dev`)
6. Start a paired programming session
    1. While logged in as dev `wemux start`
    2. Add a ssh-key with `command="wemux mirror"` or `command="wemux pair"` to `/etc/ssh/authorized_keys/dev` (see examples in file) and have the user `ssh guest@localhost -i <private key file>`

If you only want the image, it is also [hosted on dockerhub](https://hub.docker.com/r/jakegillberg/dev-environment/). `docker pull jakegillberg/dev-environment`
