#!/bin/bash

if [ -f "/start.sh" ]; then
    mv "/start.sh" "$working_dir/"
fi

/start.sh