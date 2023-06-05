local httpd = require('http.server')
local client = require('http.client').new()
local json = require('json')
local fiber = require('fiber')
local log = require('log')
local run_attempts = os.getenv("RUN_ATTEMPTS") or 4
local repo_branches = os.getenv("REPO_BRANCHES") or 'master'
local no_retry_list = os.getenv("NO_RETRY_LIST")

box.cfg({
    memtx_dir='db',
    wal_dir='db'
})
box.once('migration', function()
   jobs = box.schema.space.create('jobs')
   jobs:format({{name = 'id', type = 'unsigned'},
                {name = 'count', type = 'unsigned'},
                {name = 'fixed', type = 'boolean'}})
   jobs:create_index('primary', {unique = true,
                                 parts = {'id'}})
   box.schema.user.grant('guest','read,write,create','universe')
end)


--- Send a GitHub API request to restart a workflow that has
-- one or more failed jobs.
-- @see https://docs.github.com/en/actions/managing-workflow-runs/re-running-workflows-and-jobs
local function re_run_failed_workflow(full_repo, run_id)
    fiber.sleep(5)
    local url = 'https://api.github.com/repos/'..full_repo..'/actions/runs/'..run_id..'/rerun-failed-jobs'
    local token = os.getenv('GITHUB_TOKEN')
    local op = {
        headers = {
            ['User-Agent'] = 'Tarantool-Re-Runner',
            Accept = 'application/vnd.github+json',
            Authorization = 'token '..token
        },
        verify_host = false,
        verify_peer = false,
    }
    local res = client:request('POST', url, '', op)
    log.info('Api call for re-running '..run_id..' run finished with status '..res.status)
    log.info('Api response body is '..res.body)
end

--- Check if the table has the given value
local function check_value(table, value)
    for k, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--- Handle an incoming webhook from GitHub.
-- @see https://docs.github.com/en/developers/webhooks-and-events/webhooks/about-webhooks
function webhook_handler(req)
    local payload = req:json()
    local payload_sender = payload.sender.login
    local no_retry = no_retry_list:split(",")
    if check_value(no_retry, payload_sender) then
        log.error('Workflow by '..payload_sender..' is not allowed to rerun!')
        return { status = 204 }
    end
    if payload.workflow_job == nil then
        log.error('Empty payload')
        return { status = 204 }
    end
    if payload.workflow_job.run_attempt >= run_attempts then
        log.info('Attempt >= '..run_attempts..', no action needed')
        return { status = 204 }
    end
    local workflow_run_id = payload.workflow_job.run_id
    local full_repo = payload.repository.full_name

    describe(payload)

    if payload.action == 'queued' then
        local workflow_record = box.space.jobs:get({ workflow_run_id })
        if workflow_record then
            box.space.jobs:update(workflow_run_id, { { '+', 'count', 1}})
        else
            box.space.jobs:insert({ workflow_run_id, 1, true})
        end
        workflow_record = box.space.jobs:get({ workflow_run_id })
        log.info('Job queued in workflow '..workflow_run_id..': '..tostring(workflow_record))
        return { status = 202 }
    elseif payload.action == 'in_progress' then
        return { status = 202 }
    elseif payload.action == 'completed' then
        local workflow_record = box.space.jobs:get({ workflow_run_id })
        if workflow_record then
            box.space.jobs:update(workflow_run_id, { { '-', 'count', 1}})
            if payload.workflow_job.conclusion == 'failure' then
                box.space.jobs:update(workflow_run_id, { { '=', 'fixed', false}})
            end

            workflow_record = box.space.jobs:get({ workflow_run_id })
            log.info('Job completed in workflow '..workflow_run_id..': '..tostring(workflow_record))
            if workflow_record.count == 0 then
                box.space.jobs:delete({ workflow_run_id })
                if workflow_record.fixed then
                    return { status = 200 }
                else
                    if check_value(repo_branches:split(','), payload.workflow_job.head_branch) then
                        re_run_failed_workflow(full_repo, workflow_run_id)
                        log.info('Rerunning workflow with run_id '..workflow_run_id..
                            ' the current count of jobs in matrix is '..workflow_record.count..
                            ' and fixed equal to '..tostring(workflow_record.fixed))
                        return { status = 201 }
                    end
                end
            else
                return { status = 202 }
            end
        else
            return { status = 404 }
        end
    end
end

--- Describing incoming payload to give information in log about it.
--
function describe(payload)
    local run_id = payload.workflow_job.run_id
    if payload.workflow_job.conclusion ~= nil then
        log.info('Workflow '..run_id..', job '..payload.workflow_job.name..'#'..payload.workflow_job.run_attempt..
            ' is '..payload.workflow_job.status..' as '..payload.workflow_job.conclusion)
    else
        log.info('Workflow '..run_id..', job '..payload.workflow_job.name..'#'..payload.workflow_job.run_attempt..
            ' is '..payload.workflow_job.status)
    end
end

function list_handler(req)
    return {
        status = 200,
        headers = { ['content-type'] = 'text/html; charset=utf8' },
        body = [[
            <html>
                <body>Hello, I'm a job Re-Runner!</body>
            </html>
        ]]
    }
end

httpd = httpd.new('0.0.0.0', 5000)
httpd:route({ path = '/', method = 'POST' }, webhook_handler)
httpd:route({ path = '/', method = 'GET' }, list_handler)
httpd:start()
