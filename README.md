# dev-environment
A livelygig development environment. Uses a GUI intelliJ by bind mounting to the host X session.

Feel free to ping me with issues or requests!

## Installation
1. Install docker
2. Clone this repository
3. (Optional) take a look at the dockerfile and remove / add features. Don't like vim? Take out the whole ### VIM ### section and add / configure your favorite editor.
4. (Optional) check out the files in the customize directory and modify them to suit your needs.
5. On the host machine, run `xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -`
6. From the root of this repository run `docker-compose up -d`.
7. Login to your machine
    - As root: `docker exec -it livelygig-dev '/bin/bash'`
    - As the development user: `docker exec --user dev -it livelygig-dev '/bin/bash'`
8. Run IntelliJ: `/opt/idea-IC-173.4127.27/bin/idea.sh`
9. follow steps for Setting Up the IDE here: https://docs.google.com/document/d/1VyU5XtWzXugTa7R3odUEa8I1kmj_nVUa7VgrnkDHnQE/edit?ts=5a53456b
