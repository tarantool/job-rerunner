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
  "action": "completed",
  "workflow_job": {
    "id": 8039369388,
    "run_id": 2934728824,
    "run_url": "https://api.github.com/repos/tarantool/tarantool/actions/runs/2934728824",
    "run_attempt": 1,
    "node_id": "CR_kwDOAA3qbM8AAAAB3y8KrA",
    "head_sha": "48a3ecdac4c95d69f69ea17c5ccadb549d0d65b5",
    "url": "https://api.github.com/repos/tarantool/tarantool/actions/jobs/8039369388",
    "html_url": "https://github.com/tarantool/tarantool/runs/8039369388?check_suite_focus=true",
    "status": "completed",
    "conclusion": "failure",
    "started_at": "2022-08-26T15:16:28Z",
    "completed_at": "2022-08-26T15:28:00Z",
    "name": "osx_11_lto",
    "steps": [
      {
        "name": "Set up job",
        "status": "in_progress",
        "conclusion": null,
        "number": 1,
        "started_at": "2022-08-26T15:16:28.000Z",
        "completed_at": null
      }
    ],
    "check_run_url": "https://api.github.com/repos/tarantool/tarantool/check-runs/8039369388",
    "labels": [
      "macos-11"
    ],
    "runner_id": 244,
    "runner_name": "tntmac06",
    "runner_group_id": 1,
    "runner_group_name": "Default"
  },
  "repository": {
    "id": 911980,
    "node_id": "MDEwOlJlcG9zaXRvcnk5MTE5ODA=",
    "name": "tarantool",
    "full_name": "tarantool/tarantool",
    "private": false,
    "owner": {
      "login": "tarantool",
      "id": 2344919,
      "node_id": "MDEyOk9yZ2FuaXphdGlvbjIzNDQ5MTk=",
      "avatar_url": "https://avatars.githubusercontent.com/u/2344919?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/tarantool",
      "html_url": "https://github.com/tarantool",
      "followers_url": "https://api.github.com/users/tarantool/followers",
      "following_url": "https://api.github.com/users/tarantool/following{/other_user}",
      "gists_url": "https://api.github.com/users/tarantool/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/tarantool/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/tarantool/subscriptions",
      "organizations_url": "https://api.github.com/users/tarantool/orgs",
      "repos_url": "https://api.github.com/users/tarantool/repos",
      "events_url": "https://api.github.com/users/tarantool/events{/privacy}",
      "received_events_url": "https://api.github.com/users/tarantool/received_events",
      "type": "Organization",
      "site_admin": false
    },
    "html_url": "https://github.com/tarantool/tarantool",
    "description": "Get your data in RAM. Get compute close to data. Enjoy the performance.",
    "fork": false,
    "url": "https://api.github.com/repos/tarantool/tarantool",
    "forks_url": "https://api.github.com/repos/tarantool/tarantool/forks",
    "keys_url": "https://api.github.com/repos/tarantool/tarantool/keys{/key_id}",
    "collaborators_url": "https://api.github.com/repos/tarantool/tarantool/collaborators{/collaborator}",
    "teams_url": "https://api.github.com/repos/tarantool/tarantool/teams",
    "hooks_url": "https://api.github.com/repos/tarantool/tarantool/hooks",
    "issue_events_url": "https://api.github.com/repos/tarantool/tarantool/issues/events{/number}",
    "events_url": "https://api.github.com/repos/tarantool/tarantool/events",
    "assignees_url": "https://api.github.com/repos/tarantool/tarantool/assignees{/user}",
    "branches_url": "https://api.github.com/repos/tarantool/tarantool/branches{/branch}",
    "tags_url": "https://api.github.com/repos/tarantool/tarantool/tags",
    "blobs_url": "https://api.github.com/repos/tarantool/tarantool/git/blobs{/sha}",
    "git_tags_url": "https://api.github.com/repos/tarantool/tarantool/git/tags{/sha}",
    "git_refs_url": "https://api.github.com/repos/tarantool/tarantool/git/refs{/sha}",
    "trees_url": "https://api.github.com/repos/tarantool/tarantool/git/trees{/sha}",
    "statuses_url": "https://api.github.com/repos/tarantool/tarantool/statuses/{sha}",
    "languages_url": "https://api.github.com/repos/tarantool/tarantool/languages",
    "stargazers_url": "https://api.github.com/repos/tarantool/tarantool/stargazers",
    "contributors_url": "https://api.github.com/repos/tarantool/tarantool/contributors",
    "subscribers_url": "https://api.github.com/repos/tarantool/tarantool/subscribers",
    "subscription_url": "https://api.github.com/repos/tarantool/tarantool/subscription",
    "commits_url": "https://api.github.com/repos/tarantool/tarantool/commits{/sha}",
    "git_commits_url": "https://api.github.com/repos/tarantool/tarantool/git/commits{/sha}",
    "comments_url": "https://api.github.com/repos/tarantool/tarantool/comments{/number}",
    "issue_comment_url": "https://api.github.com/repos/tarantool/tarantool/issues/comments{/number}",
    "contents_url": "https://api.github.com/repos/tarantool/tarantool/contents/{+path}",
    "compare_url": "https://api.github.com/repos/tarantool/tarantool/compare/{base}...{head}",
    "merges_url": "https://api.github.com/repos/tarantool/tarantool/merges",
    "archive_url": "https://api.github.com/repos/tarantool/tarantool/{archive_format}{/ref}",
    "downloads_url": "https://api.github.com/repos/tarantool/tarantool/downloads",
    "issues_url": "https://api.github.com/repos/tarantool/tarantool/issues{/number}",
    "pulls_url": "https://api.github.com/repos/tarantool/tarantool/pulls{/number}",
    "milestones_url": "https://api.github.com/repos/tarantool/tarantool/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/tarantool/tarantool/notifications{?since,all,participating}",
    "labels_url": "https://api.github.com/repos/tarantool/tarantool/labels{/name}",
    "releases_url": "https://api.github.com/repos/tarantool/tarantool/releases{/id}",
    "deployments_url": "https://api.github.com/repos/tarantool/tarantool/deployments",
    "created_at": "2010-09-15T07:59:26Z",
    "updated_at": "2022-08-25T09:47:42Z",
    "pushed_at": "2022-08-26T15:19:35Z",
    "git_url": "git://github.com/tarantool/tarantool.git",
    "ssh_url": "git@github.com:tarantool/tarantool.git",
    "clone_url": "https://github.com/tarantool/tarantool.git",
    "svn_url": "https://github.com/tarantool/tarantool",
    "homepage": "https://www.tarantool.io",
    "size": 89568,
    "stargazers_count": 2963,
    "watchers_count": 2963,
    "language": "Lua",
    "has_issues": true,
    "has_projects": true,
    "has_downloads": true,
    "has_wiki": true,
    "has_pages": true,
    "forks_count": 342,
    "mirror_url": null,
    "archived": false,
    "disabled": false,
    "open_issues_count": 1311,
    "license": {
      "key": "other",
      "name": "Other",
      "spdx_id": "NOASSERTION",
      "url": null,
      "node_id": "MDc6TGljZW5zZTA="
    },
    "allow_forking": true,
    "is_template": false,
    "web_commit_signoff_required": false,
    "topics": [
      "appserver",
      "database",
      "disk",
      "in-memory",
      "lua",
      "msgpack",
      "tarantool",
      "transactions"
    ],
    "visibility": "public",
    "forks": 342,
    "open_issues": 1311,
    "watchers": 2963,
    "default_branch": "master"
  },
  "organization": {
    "login": "tarantool",
    "id": 2344919,
    "node_id": "MDEyOk9yZ2FuaXphdGlvbjIzNDQ5MTk=",
    "url": "https://api.github.com/orgs/tarantool",
    "repos_url": "https://api.github.com/orgs/tarantool/repos",
    "events_url": "https://api.github.com/orgs/tarantool/events",
    "hooks_url": "https://api.github.com/orgs/tarantool/hooks",
    "issues_url": "https://api.github.com/orgs/tarantool/issues",
    "members_url": "https://api.github.com/orgs/tarantool/members{/member}",
    "public_members_url": "https://api.github.com/orgs/tarantool/public_members{/member}",
    "avatar_url": "https://avatars.githubusercontent.com/u/2344919?v=4",
    "description": "In-memory computing platform with flexible data schema."
  },
  "sender": {
    "login": "ylobankov",
    "id": 3645987,
    "node_id": "MDQ6VXNlcjM2NDU5ODc=",
    "avatar_url": "https://avatars.githubusercontent.com/u/3645987?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/ylobankov",
    "html_url": "https://github.com/ylobankov",
    "followers_url": "https://api.github.com/users/ylobankov/followers",
    "following_url": "https://api.github.com/users/ylobankov/following{/other_user}",
    "gists_url": "https://api.github.com/users/ylobankov/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/ylobankov/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/ylobankov/subscriptions",
    "organizations_url": "https://api.github.com/users/ylobankov/orgs",
    "repos_url": "https://api.github.com/users/ylobankov/repos",
    "events_url": "https://api.github.com/users/ylobankov/events{/privacy}",
    "received_events_url": "https://api.github.com/users/ylobankov/received_events",
    "type": "User",
    "site_admin": false
  }
}
```

</details>
