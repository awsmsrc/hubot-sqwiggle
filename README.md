hubot-sqwiggle
==============

hubot adapter for sqwiggle - yay

## Installation

### Install "hubot-sqwiggle".

```bash
    cd /path to your hubot
    npm install --save hubot-sqwiggle
```

### Setup your hubot.

```bash:start-script.sh
    export HUBOT_SQWIGGLE_BOTNAME="Hubot"         # Set bot name you like
    export HUBOT_SQWIGGLE_TOKEN="ABCDEFGH"        # Set your API token. make it from https://www.sqwiggle.com/clients (need "Stream Permissions")
    export HUBOT_SQWIGGLE_ROOM=1234               # (option) Set Default stream id
```

### Run hubot with sqwiggle adapter.

```bash:start-script.sh
    bin/hubot -a sqwiggle
```
