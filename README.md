# Tarantool Workflow Re-Runner

THe app is written on Lua and runs on Tarantool

It receives WebHook from GitHub and if it came with "failure" in "conclusion", 
it sends api call to re-run failed jobs in the workflow.

## Deployment

The app is deployed in Dokku using [dummy buildpack](https://github.com/maximkulkin/heroku-buildpack-dummy)

Dokku must have enabled [dokku-apt](https://github.com/dokku-community/dokku-apt)
plugin for installing apt dependencies in `apt-*` files

`Procfile` contains a command for running main process of the application
