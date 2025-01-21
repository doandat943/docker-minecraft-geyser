#!/bin/bash

# Set working dir
working_dir="/minecraft"

if [ -f "/start.sh" ]; then
    mv "/start.sh" "$working_dir/"
fi

$working_dir/start.sh