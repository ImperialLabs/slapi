#!/bin/bash

unicorn -c $APP_HOME/unicorn.rb -D
service nginx start
