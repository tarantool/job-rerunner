local httpd = require('http.server')
local client = require('http.client').new()
local json = require('json')
local fiber = require('fiber')
local log = require('log')


box.cfg({
    memtx_dir='db',
    wal_dir='db'
})
box.once('migration', function()
    if type(box.space.jobs) == 'table' then
        box.space.jobs:drop()
    end

   jobs = box.schema.space.create('jobs')
   jobs:format({{name = 'run_id', type = 'unsigned'},
                {name = 'run_attempt', type = 'unsigned'},
                {name = 'run_status', type = 'string'},
                {name = 'run_conclusion', type = 'string'},
                {name = 'job_id', type = 'unsigned'},
                {name = 'job_status', type = 'string'},
                {name = 'job_conclusion', type = 'string'},
                {name = 'count', type = 'unsigned'},
                {name = 'fixed', type = 'boolean'}})
   jobs:create_index('primary', {unique = true,
                                 parts = {'job_id'}})
   box.schema.user.grant('guest','read,write,create','universe')
end)

local function is_job_failed(data)
    if type(data) == 'table' then
        local workflow_job = data.workflow_job
        if type(workflow_job) == 'table' then
            return workflow_job.conclusion == 'failure'
        end
    end
    return false
end

local function needs_restart(run_id, run_attempt, run_status, run_conclusion, job_id, job_status, job_conclusion)
    local job = box.space.jobs:get({job_id})
    if job then
        if job.count < 3 then
            box.space.jobs:update(job_id, {{'+', 'count', 1}})
            return true
        end
    else
        box.space.jobs:insert({run_id, run_attempt, run_status, run_conclusion, job_id, job_status, job_conclusion, 1, false})
        log.info('From payload we have got job with id '..job_id..' with status '..job_status..' and conclusion is '..job_conclusion..' from run with id '..run_id..'run status is '..run_status..' and run conclusion is '..run_conclusion)
        return true
    end
    return false
end

local function re_run_failed_jobs(full_repo, run_id)
    fiber.sleep(5)
    local url = 'https://api.github.com/repos/'..full_repo..'/actions/runs/'..run_id..'/rerun-failed-jobs'
    local token = os.getenv('GITHUB_TOKEN')
    local attempt = 0
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
    log.info('Api call for re-running '..run_id..' job finished with status '..res.status)
    log.info('Api response body is '..res.body)
    attempt = attempt + 1


    while attempt < 12 do
        if res.status == 404 then
            log.info('Unable to reach repository breaking retry process')
            break
        elseif res.status == 403 then
            log.info('Unable to re-run, wait for 60 second to retry. Attempt #'..attempt)
            fiber.sleep(60)
            local res = client:request('POST', url, '', op)
            log.info('Api call for re-running '..run_id..' job finished with status '..res.status)
            log.info('Api response body is '..res.body)
            attempt = attempt + 1
        end
    end
end

function webhook_handler(req)
    local job = req:json()
    local run_id = job.workflow_job.run_id
    local full_repo = job.repository.full_name
    for job in job.workflow_job
    do
        local job_id = job.workflow_job.job_id
        local run_attempt = job.workflow_job.run_attempt
        local run_status = job.workflow_job.status
        local run_conclusion = job.workflow_job.conclusion
        local job_status = job.workflow_job.steps.status
        local job_conclusion = job.workflow_job.steps.conclusion
        local if_restart = needs_restart(run_id, run_attempt, run_status, run_conclusion, job_id, job_status, job_conclusion)
    end
    local is_failed = is_job_failed(job)
    log.info(string.format('needs_restart equal to '..tostring(if_restart)..' and is_job_failed equal to '..tostring(is_failed)))

    if if_restart and is_failed then
        fiber.create(function() re_run_failed_jobs(full_repo, run_id) end)
    end
    return { status = 200 }
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
