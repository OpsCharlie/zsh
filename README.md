# Zsh


Features:
* shows number of active background jobs
* shows number of open *tmux* sockets
* *hostname* color can be based on host unique identifier to simplify server identification by the user when working with multiple open SSH sessions
* shows checked-out branch name when current directory is within Git repository
* shows last command return code if it differs from 0


## Installation

The most convenient way of installation is to checkout the repository and symlink the relevant scripts.
Assuming the installation in home directory:
```bash
git clone git@github.com:OpsCharlie/zsh.git
cd zsh
./__deploy.sh
or
./__deploy.sh username@host

```


