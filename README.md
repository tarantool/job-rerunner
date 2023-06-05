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
   
   * Set "Payload URL" to the service endpoint.
   * Select "application/json" in the "Content type" dropdown.
   * Pick "Let me select individual events", then check "Workflow jobs" in the bottom of the page.
   
   
2. Add the bot user to the repository with "Write" permissions.
   For repos in the [tarantool organization](https://github.com/tarantool),
   it's the [@TarantoolBot](https://github.com/TarantoolBot).
   
The service will now restart all failed workflows in this repository up to three times.

## Deployment

The app is deployed in [Dokku](https://dokku.com) using the 
[dummy buildpack](https://github.com/maximkulkin/heroku-buildpack-dummy).

Dokku must have [dokku-apt](https://github.com/dokku-community/dokku-apt)
plugin enabled to install `apt` dependencies in `apt-*` files.

Provide the SSH key for access to Dokku in the `SSH_PRIVATE_KEY` secret.

`Procfile` contains the command for running the main process of the application.

## Environment variables

| Variable     | Default | Meaning                                            |
|--------------|---------|----------------------------------------------------|
| RUN_ATTEMPTS | 4       | Number of attempts to run a specific workflow job. |

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

## Payload example

<details>
<summary>
<a href="https://github.com/tarantool/tarantool/runs/8039369388?check_suite_focus=true">Job `osx_11_lto`</a>
failed:
</summary>

```json
{
   "workflow_job": {
      "head_sha": "0d5ec357fb8684bd26a74f0b8b3a5020768688eb",
      "id": 11786061154,
      "head_branch": "master",
      "node_id": "CR_kwDOH2Isjs8AAAACvoEFYg",
      "workflow_name": "Deploy branch",
      "url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/actions\/jobs\/11786061154",
      "run_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/actions\/runs\/4341897961",
      "run_id": 4341897961,
      "status": "in_progress",
      "conclusion": null,
      "runner_group_id": 1,
      "completed_at": null,
      "runner_name": "ghacts-shared-1-2-n1",
      "created_at": "2023-03-06T09:30:16Z",
      "steps": [
         {
            "number": 1,
            "conclusion": null,
            "status": "in_progress",
            "completed_at": null,
            "name": "Set up job",
            "started_at": "2023-03-06T09:30:19.000Z"
         }
      ],
      "run_attempt": 1,
      "runner_id": 232,
      "check_run_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/check-runs\/11786061154",
      "labels": [
         "self-hosted",
         "Linux",
         "flavor-1-2"
      ],
      "runner_group_name": "Default",
      "started_at": "2023-03-06T09:30:20Z",
      "name": "other-job (5, 1)",
      "html_url": "https:\/\/github.com\/tarantool\/devx-team-sandbox\/actions\/runs\/4341897961\/jobs\/7582057694"
   },
   "sender": {
      "login": "lastoCHka42",
      "events_url": "https:\/\/api.github.com\/users\/lastoCHka42\/events{\/privacy}",
      "gists_url": "https:\/\/api.github.com\/users\/lastoCHka42\/gists{\/gist_id}",
      "repos_url": "https:\/\/api.github.com\/users\/lastoCHka42\/repos",
      "node_id": "MDQ6VXNlcjg4NzQ2Nzkw",
      "gravatar_id": "",
      "received_events_url": "https:\/\/api.github.com\/users\/lastoCHka42\/received_events",
      "starred_url": "https:\/\/api.github.com\/users\/lastoCHka42\/starred{\/owner}{\/repo}",
      "avatar_url": "https:\/\/avatars.githubusercontent.com\/u\/88746790?v=4",
      "site_admin": false,
      "type": "User",
      "html_url": "https:\/\/github.com\/lastoCHka42",
      "id": 88746790,
      "followers_url": "https:\/\/api.github.com\/users\/lastoCHka42\/followers",
      "subscriptions_url": "https:\/\/api.github.com\/users\/lastoCHka42\/subscriptions",
      "following_url": "https:\/\/api.github.com\/users\/lastoCHka42\/following{\/other_user}",
      "url": "https:\/\/api.github.com\/users\/lastoCHka42",
      "organizations_url": "https:\/\/api.github.com\/users\/lastoCHka42\/orgs"
   },
   "action": "in_progress",
   "organization": {
      "members_url": "https:\/\/api.github.com\/orgs\/tarantool\/members{\/member}",
      "login": "tarantool",
      "issues_url": "https:\/\/api.github.com\/orgs\/tarantool\/issues",
      "events_url": "https:\/\/api.github.com\/orgs\/tarantool\/events",
      "repos_url": "https:\/\/api.github.com\/orgs\/tarantool\/repos",
      "node_id": "MDEyOk9yZ2FuaXphdGlvbjIzNDQ5MTk=",
      "public_members_url": "https:\/\/api.github.com\/orgs\/tarantool\/public_members{\/member}",
      "url": "https:\/\/api.github.com\/orgs\/tarantool",
      "hooks_url": "https:\/\/api.github.com\/orgs\/tarantool\/hooks",
      "avatar_url": "https:\/\/avatars.githubusercontent.com\/u\/2344919?v=4",
      "id": 2344919,
      "description": "In-memory computing platform with flexible data schema."
   },
   "repository": {
      "disabled": false,
      "subscribers_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/subscribers",
      "private": false,
      "notifications_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/notifications{?since,all,participating}",
      "tags_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/tags",
      "pushed_at": "2023-02-14T12:18:16Z",
      "description": "Tests and experiments in the DevX team",
      "license": null,
      "deployments_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/deployments",
      "keys_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/keys{\/key_id}",
      "comments_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/comments{\/number}",
      "language": null,
      "has_wiki": false,
      "releases_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/releases{\/id}",
      "has_downloads": true,
      "forks_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/forks",
      "has_pages": false,
      "watchers_count": 0,
      "downloads_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/downloads",
      "size": 5,
      "assignees_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/assignees{\/user}",
      "issues_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/issues{\/number}",
      "commits_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/commits{\/sha}",
      "clone_url": "https:\/\/github.com\/tarantool\/devx-team-sandbox.git",
      "owner": {
         "login": "tarantool",
         "events_url": "https:\/\/api.github.com\/users\/tarantool\/events{\/privacy}",
         "gists_url": "https:\/\/api.github.com\/users\/tarantool\/gists{\/gist_id}",
         "repos_url": "https:\/\/api.github.com\/users\/tarantool\/repos",
         "node_id": "MDEyOk9yZ2FuaXphdGlvbjIzNDQ5MTk=",
         "gravatar_id": "",
         "received_events_url": "https:\/\/api.github.com\/users\/tarantool\/received_events",
         "starred_url": "https:\/\/api.github.com\/users\/tarantool\/starred{\/owner}{\/repo}",
         "avatar_url": "https:\/\/avatars.githubusercontent.com\/u\/2344919?v=4",
         "site_admin": false,
         "type": "Organization",
         "html_url": "https:\/\/github.com\/tarantool",
         "id": 2344919,
         "followers_url": "https:\/\/api.github.com\/users\/tarantool\/followers",
         "subscriptions_url": "https:\/\/api.github.com\/users\/tarantool\/subscriptions",
         "following_url": "https:\/\/api.github.com\/users\/tarantool\/following{\/other_user}",
         "url": "https:\/\/api.github.com\/users\/tarantool",
         "organizations_url": "https:\/\/api.github.com\/users\/tarantool\/orgs"
      },
      "languages_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/languages",
      "hooks_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/hooks",
      "git_commits_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/git\/commits{\/sha}",
      "name": "devx-team-sandbox",
      "teams_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/teams",
      "updated_at": "2022-10-05T11:24:55Z",
      "issue_events_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/issues\/events{\/number}",
      "default_branch": "master",
      "events_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/events",
      "homepage": null,
      "node_id": "R_kgDOH2Isjg",
      "pulls_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/pulls{\/number}",
      "visibility": "public",
      "url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox",
      "statuses_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/statuses\/{sha}",
      "git_url": "git:\/\/github.com\/tarantool\/devx-team-sandbox.git",
      "branches_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/branches{\/branch}",
      "issue_comment_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/issues\/comments{\/number}",
      "created_at": "2022-08-19T08:39:08Z",
      "labels_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/labels{\/name}",
      "trees_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/git\/trees{\/sha}",
      "web_commit_signoff_required": false,
      "archived": false,
      "allow_forking": true,
      "topics": [
      ],
      "id": 526527630,
      "watchers": 0,
      "open_issues": 1,
      "has_issues": true,
      "forks": 0,
      "contributors_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/contributors",
      "mirror_url": null,
      "open_issues_count": 1,
      "is_template": false,
      "milestones_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/milestones{\/number}",
      "git_tags_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/git\/tags{\/sha}",
      "subscription_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/subscription",
      "forks_count": 0,
      "git_refs_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/git\/refs{\/sha}",
      "html_url": "https:\/\/github.com\/tarantool\/devx-team-sandbox",
      "svn_url": "https:\/\/github.com\/tarantool\/devx-team-sandbox",
      "contents_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/contents\/{+path}",
      "merges_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/merges",
      "stargazers_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/stargazers",
      "full_name": "tarantool\/devx-team-sandbox",
      "archive_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/{archive_format}{\/ref}",
      "fork": false,
      "collaborators_url": "https:\/\/api.github.com\/repos\/tarantool\/devx-team-sandbox\/collaborators{\/collaborator}",
      "ssh_url": "git@github.com:tarantool\/devx-team-sandbox.git",
      "stargazers_count": 0,
      "blobs_url": "https:\/\/api.github.com\/repos\/"
   }
}
```

</details>

## Status codes
Job rerunner returns some status code while working on payload from GitHub.

|     | Result     | Meaning                                                                                           |
|-----|------------|---------------------------------------------------------------------------------------------------|
| 204 | No Content | Got empty payload, overall run attempts more than allowed, or user in `NO_RETRY_LIST` No action.  |
| 200 | OK         | Final job was completed, but no action is required.                                               |
| 201 | Created    | Final job was completed, restarting the workflow.                                                 |
| 202 | Accepted   | Recorded the queued or completed jobs and waiting for results.                                    |
| 404 | Error      | Job action is 'completed', but there's no previous record about it.                               |

## Excluding usernames from retrying
Rerunner will not restart workflows initiated by GitHub users,
specified in the environment variable `NO_RETRY_LIST`:
NO_RETRY_LIST=username1,username2
