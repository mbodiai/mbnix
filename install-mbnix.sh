#!/bin/sh

# You just ran curl -L https://mbodi.ai/install.sh | sh
if [ -f "$HOME/mbnix" ]; then
    echo "mbnix already installed"
else
    git clone https://github.com/mbodiai/mbnix.git "$HOME/mbnix"
fi

# shellcheck disable=SC1091
. "$HOME/mbnix/.mbnix/setup-mbnix.sh"

