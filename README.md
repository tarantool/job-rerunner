# Tarantool Workflow Re-runner

This service is written in Lua and runs on [Tarantool](https://tarantool.io).

It receives webhooks from all completed workflows in a certain GitHub repository.
If a webhook came with `check_run.conclusion == failure` in the 
[payload](https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads#check_run), 
the service calls GitHub API to re-run failed jobs in the workflow.

## Adding repositories

To enable restarting workflows in a repository:

1. Add a new webhook in the repository.
   You should have "Admin" permissions in the repository to do so.
   Pick "Let me select individual events", then check "Workflow jobs".
   Set webhook URL to the service endpoint.
   
2. Add the bot user to the repository with "Write" permissions.
   For repos in the [tarantool organization](https://github.com/tarantool),
   it's the [@TarantoolBot](https://github.com/TarantoolBot).
   
The service will now restart all failed workflows up to three times.

## Deployment

The app is deployed in [Dokku](https://dokku.com) using the 
[dummy buildpack](https://github.com/maximkulkin/heroku-buildpack-dummy).

Dokku must have [dokku-apt](https://github.com/dokku-community/dokku-apt)
plugin enabled to install `apt` dependencies in `apt-*` files.

Provide the SSH key for access to Dokku in the `SSH_PRIVATE_KEY` secret.

`Procfile` contains the command for running the main process of the application.

## Updating GitHub token

To update the token or change the user which will restart workflows:

1. [Issue a new token](https://github.com/settings/tokens/new) with scopes `repo` and `workflow`.
2. Add the token to the service config in Dokku:

    ```console
    $ ssh user@dokku-machine
    $ sudo su
    # dokku config job-re-runner
    BUILDPACK_URL:            https://github.com/maximkulkin/heroku-buildpack-dummy.git
    DOKKU_APP_RESTORE:        1
    DOKKU_APP_TYPE:           herokuish
    DOKKU_LETSENCRYPT_EMAIL:  admin@org
    DOKKU_PROXY_PORT:         80
    DOKKU_PROXY_PORT_MAP:     http:80:5000 https:443:5000
    DOKKU_PROXY_SSL_PORT:     443
    GITHUB_TOKEN:             <old_token_value>
    GIT_REV:                  e4da2ec3daf9366236da98b5ba06ecbe4d645365

    # dokku config:set job-re-runner GITHUB_TOKEN=<value>
    -----> Setting config vars
       GITHUB_TOKEN:  <value>
    -----> Restarting app job-re-runner
    ...
    ```
    
    Dokku will now deploy a new service instance with the new configuration.
    There shouldn't be any downtime in the deployment.
    
## Logging

To read service logs, SSH to the Dokku machine:

```console
$ ssh user@dokku-machine
$ sudo su
# dokku logs job-re-runner --tail
```
