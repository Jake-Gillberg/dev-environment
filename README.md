# dev-environment
A dockerized RChain development environment.

Feel free to ping me with issues or requests!

## Features
* Start GUI apps from within the container!
* Connect to docker to create / run containers without docker-in-dockering yourself!
* Compile the latest RChain node!

## Installation
1. Install docker
2. Clone this repository
3. If you want to be able to send commands to docker from within the container, change DOCKER_GID on line 15 of `Dockerfile` to be the docker group id on your host system. (Alternatively, add the "in-container" user to a group with the host system's docker groupid every time after spinning up the container.) I know this is hacky, please get at me if you have other ideas. I'm guessing a good solution would have something to do with docker namespaces, but I haven't had spent enough time with them to figure it out. 
4. (Optional) take a look at the dockerfile and remove / add features. Don't like vim? Take out the whole ### VIM ### section and add / configure your favorite editor.
5. (Optional) check out the files in the customize directory and modify them to suit your needs.
6. On the host machine, run `xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -` to set up xauth for connecting to the host x session from within the contianer
7. From the root of this repository run `docker-compose up -d`.
8. Login to your machine
    - As root: `docker exec -it rchain-dev /bin/bash`
    - As the development user: `docker exec -it -u dev rchain-dev /bin/bash --login`