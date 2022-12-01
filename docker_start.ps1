############################################################
# Parameters                                               #
############################################################

param(
    [Alias('n', 'name')] $PROJECT_NAME,

    [Alias('o', 'odoo')] [string[]] $ODOO_VER="15.0",

    [Alias('p', 'psql')] [string[]] $PSQL_VER="13",

    [Alias('a', 'addons')] $ADDONS_URL,

    [Alias('b', 'branch')] $BRANCH_NAME,

    [Alias('e', 'enterprise')] [switch] $INSTALL_ENTERPRISE_MODULES,
    
    [Alias('d', 'delete')] [switch] $DELETE_PROJECT,
    
    [Alias('t', 'test')] [switch] $RUN_TEST,

    [Alias('m', 'module')] $TEST_MODULE,

    [Alias('database')] $TEST_DB,

    [Alias('tags')] $TEST_TAGS,

    [Alias('h', 'help')] [switch] $display_help

)

############################################################
# Default Values                                           #
############################################################

# Flags

# Variables
# $ODOO_VER="15.0"
# $PSQL_VER="13"
$RUN_LOCATION = Get-Location
$PROJECTS_DIR=$PSScriptRoot -replace "SmartOdoo", "DockerProjects"
# Odoo
$ODOO_GITHUB_NAME="odoo"
$ODOO_ENTERPRISE_REPOSITORY="enterprise"
############################################################
# Functions                                                #
############################################################

function customize_env {
    # CUSTOMIZE .ENV VARIABLES
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PROJECT_NAME=TEST_PROJECT", "PROJECT_NAME=$PROJECT_NAME" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "ODOO_VER=15.0", "ODOO_VER=$ODOO_VER" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PSQL_VER=13", "PSQL_VER=$PSQL_VER" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "ODOO_CONT_NAME=ODOO_TEMP_CONT", "ODOO_CONT_NAME=$PROJECT_NAME-web" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PSQL_CONT_NAME=PSQL_TEMP_CONT", "PSQL_CONT_NAME=$PROJECT_NAME-db" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "SMTP_CONT_NAME=SMTP_TEMP_CONT", "SMTP_CONT_NAME=$PROJECT_NAME-smtp" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PROJECT_LOCATION=TEST_LOCATION", "PROJECT_LOCATION=$PROJECT_FULLPATH" } | Set-Content .env

    Get-Content .env
}

function standarize_env {
    # RETURN TO STANDARD .ENV VARIABLES
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PROJECT_NAME=$PROJECT_NAME", "PROJECT_NAME=TEST_PROJECT" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "ODOO_VER=$ODOO_VER", "ODOO_VER=15.0" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PSQL_VER=$PSQL_VER", "PSQL_VER=13" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "ODOO_CONT_NAME=$PROJECT_NAME-web", "ODOO_CONT_NAME=ODOO_TEMP_CONT" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "PSQL_CONT_NAME=$PROJECT_NAME-db", "PSQL_CONT_NAME=PSQL_TEMP_CONT" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace "SMTP_CONT_NAME=$PROJECT_NAME-smtp", "SMTP_CONT_NAME=SMTP_TEMP_CONT" } | Set-Content .env
    (Get-Content .\.env) | ForEach-Object { $_ -replace [Regex]::Escape("PROJECT_LOCATION=$PROJECT_FULLPATH"), "PROJECT_LOCATION=TEST_LOCATION" } | Set-Content .env
}

function clone_addons {
    if  ( $null -ne $ADDONS_CLONE_URL )
    {
        if ( $null -ne $BRANCH_NAME )
        {
            git -C $PROJECT_FULLPATH clone $ADDONS_CLONE_URL  --branch $BRANCH_NAME addons 
        }
        else
        {
            git -C $PROJECT_FULLPATH clone $ADDONS_CLONE_URL addons 
        }
    }
}
function clone_enterprise {
    enterprise_link_compose
    if ($null -ne $ENTERPRISE_CLONE_URL )
    {
        git -C $PROJECT_FULLPATH clone $ENTERPRISE_CLONE_URL  --branch $ODOO_VER enterprise 
    }
}

function delete_project {
    Write-Output "DELETING PROJECT AND VOLUMES"
    $location = Get-Location
    Set-Location $PROJECT_FULLPATH; docker-compose down -v
    Set-Location $location
    Write-Output "DELETING PROJECT DIRECTORY"
    Remove-Item $PROJECT_FULLPATH -Recurse -Force
}

function project_start {
    # Find project in running containers and start or restart
    $RUNNING_CONTAINERS = docker ps
    if ( $RUNNING_CONTAINERS -like "*$PROJECT_NAME*" )
    {
        Write-Output "RESTARTING $PROJECT_NAME"
        $location = Get-Location
        Set-Location $PROJECT_FULLPATH; docker-compose restart
        Set-Location $location
    }
    else
    {
        Write-Output "UPDATE GIT REPO"
        git -C "$PROJECT_FULLPATH/addons" stash
        git -C "$PROJECT_FULLPATH/addons" pull
        git -C "$PROJECT_FULLPATH/addons" stash pop
        Write-Output "STARTING $PROJECT_NAME"
        $location = Get-Location
        Set-Location $PROJECT_FULLPATH; docker-compose start
        Set-Location $location
    }
}

function run_unit_tests {
    $location = Get-Location
    if ( $null -eq $TEST_DB -or $TEST_DB -eq "" )
    {
        Write-Output "You need to specify database to run tests on. Use --db."
        display_help
    }
    if ( $null -ne $TEST_MODULE )
    {
        Write-Output "START ODOO UNIT TESTS ON ($TEST_DB) DB FOR ($TEST_MODULE) MODULE"
        Set-Location $PROJECT_FULLPATH; docker-compose run --rm web --test-enable --log-level=test --stop-after-init -d $TEST_DB -i $TEST_MODULE
        Set-Location $location
    }
    elseif ( $null -ne $TEST_TAGS )
    {
        Write-Output "START ODOO UNIT TESTS ON ($TEST_DB) DB FOR ($TEST_TAGS) TAGS"
        Set-Location $PROJECT_FULLPATH; docker-compose run --rm web --test-enable --log-level=test --stop-after-init -d $TEST_DB --test-tags=$TEST_TAGS
        Set-Location $location
    }
    else
    {
        Write-Output "You need to specify module or tags. Use -m or --tags"
        display_help
    }
}

function project_exist {
    if ( $DELETE_PROJECT )
    {
        delete_project
        Set-Location $RUN_LOCATION
        exit 1
    }
    elseif ( $RUN_TEST )
    {
        run_unit_tests
    }
    else
    {
        project_start
    }
}

function create_project {
    Write-Output "CREATE PROJECT"
    Copy-Item .\config\* -Destination $PROJECT_FULLPATH\config\ -Recurse
    Copy-Item .\docker-compose.yml -Destination $PROJECT_FULLPATH\ -Recurse
    Copy-Item .\entrypoint.sh -Destination $PROJECT_FULLPATH\ -Recurse
    # Change CRLF to LF
    (Get-Content "$PROJECT_FULLPATH\entrypoint.sh" -Raw) -replace "`r`n", "`n" | Set-Content "$PROJECT_FULLPATH\entrypoint.sh" -Force
    Copy-Item .\launch.json -Destination $PROJECT_FULLPATH\.vscode\ -Recurse
    clone_addons
    if ( $INSTALL_ENTERPRISE_MODULES )
    {
        clone_enterprise
    }
    customize_env
    Copy-Item .\.env -Destination $PROJECT_FULLPATH\ -Recurse
    docker-compose -p $PROJECT_NAME -f $PROJECT_FULLPATH\docker-compose.yml up --detach
    standarize_env
}

function create_project_directiories {
    New-Item $PROJECT_FULLPATH -ItemType "directory"
    New-Item $PROJECT_FULLPATH\addons -ItemType "directory"
    New-Item $PROJECT_FULLPATH\enterprise -ItemType "directory"
    New-Item $PROJECT_FULLPATH\config -ItemType "directory"
    New-Item $PROJECT_FULLPATH\.vscode -ItemType "directory"
}

function check_project {
    Set-Location $PSScriptRoot
    $PROJECT_FULLPATH="$PROJECTS_DIR\$PROJECT_NAME"
    if ( Test-Path $PROJECT_FULLPATH )
    {
        project_exist
    }
    elseif ( $DELETE_PROJECT )
    {
        Write-Output "PROJECT DESN'T EXIST"
        Set-Location $RUN_LOCATION
        exit 1
    }
    else
    {
        create_project_directiories
        create_project
    }
}

function check_odoo_version {
    if ( $ODOO_VER.Substring(2) -ne ".0" )
    {
        $script:ODOO_VER="$ODOO_VER.0"
    }
}

function check_psql_version {
    if ( $PSQL_VER.Substring($PSQL_VER.Length-1) -eq ".0" )
    {
        $script:PSQL_VER=$PSQL_VER.Substring(0,2)
    }
}
###################################
# CREATE AND RETRIEVE SECRET KEYS #
###################################
function get_addons_secret {
    if ( Test-Path "./secret/git_addons.xml" )
    {
        $GITHUB_ADDONS_CREDENTIALS=Import-CliXml -Path "./secret/git_addons.xml"
        $script:GITHUB_ADDONS_ACCOUNT=$GITHUB_ADDONS_CREDENTIALS.Username
        $script:GITHUB_ADDONS_TOKEN=$GITHUB_ADDONS_CREDENTIALS.GetNetworkCredential().Password
    }
    else
    {
        if ( -not (Test-Path "./secret") )
        {
            New-Item -ItemType 'directory' -Path './secret'
            $FILE=Get-Item './secret' -Force
            $FILE.attributes='Hidden'
        }
        $GITHUB_ADDONS_CREDENTIALS=Get-Credential -Message "Provide login and token for YOUR github account."
        $script:GITHUB_ADDONS_ACCOUNT=$GITHUB_ADDONS_CREDENTIALS.Username
        $script:GITHUB_ADDONS_TOKEN=$GITHUB_ADDONS_CREDENTIALS.GetNetworkCredential().Password
        $GITHUB_ADDONS_CREDENTIALS | Export-CliXml  -Path "./secret/git_addons.xml"
    }
}

function get_enterprise_secret {
    if ( Test-Path "./secret/git_ent.xml" )
    {
        $GITHUB_ENTERPRISE_CREDENTIALS=Import-CliXml -Path "./secret/git_ent.xml"
        $script:GITHUB_ENTERPRISE_ACCOUNT=$GITHUB_ENTERPRISE_CREDENTIALS.Username
        $script:GITHUB_ENTERPRISE_TOKEN=$GITHUB_ENTERPRISE_CREDENTIALS.GetNetworkCredential().Password
    }
    else
    {
        if ( -not (Test-Path "./secret") )
        {
            New-Item -ItemType 'directory' -Path './secret'
            $FILE=Get-Item './secret' -Force
            $FILE.attributes='Hidden'
        }
        $GITHUB_ENTERPRISE_CREDENTIALS=Get-Credential -Message "Provide login and token for COMPANY github account."
        $script:GITHUB_ENTERPRISE_ACCOUNT=$GITHUB_ENTERPRISE_CREDENTIALS.Username
        $script:GITHUB_ENTERPRISE_TOKEN=$GITHUB_ENTERPRISE_CREDENTIALS.GetNetworkCredential().Password
        $GITHUB_ENTERPRISE_CREDENTIALS | Export-CliXml  -Path "./secret/git_ent.xml"
    }
}

function addons_link_compose {

    # https://github.com/rnwood/smtp4dev.git
    if ( $ADDONS_URL -notlike "*github.com*" )
    {
        Write-Output "Currently only github URLs accepted"
        display_help
    }
    # Currently support only HTTPS connection
    if ( $ADDONS_URL -like "*https://*" )
    {
        $ADDONS_URL=$ADDONS_URL.Substring(8)
    }
    else
    {
        Write-Output "Currently only HTTPS URLs are accepted"
        display_help
    }
    get_addons_secret
    $script:ADDONS_CLONE_URL="https://$GITHUB_ADDONS_TOKEN@$ADDONS_URL"
}

function enterprise_link_compose {
    get_enterprise_secret
    $script:ENTERPRISE_CLONE_URL="https://$GITHUB_ENTERPRISE_TOKEN@github.com/$ODOO_GITHUB_NAME/$ODOO_ENTERPRISE_REPOSITORY.git"
}
############################################################
# Help                                                     #
############################################################
function display_help {
    $script_name = "docker_start.ps1"
    # taken from https://stackoverflow.com/users/4307337/vincent-stans
    Write-Output "Usage: $script_name -n {project_name} [parameters...] "
    Write-Output "Examples:"
    Write-Output "$script_name -n Test_Project -e -o 14.0 -p 12"
    Write-Output "$script_name -n Test_Project"
    Write-Output "$script_name -n Test_Project -t --db=test_db -m my_module "
    Write-Output "$script_name -n Test_Project -t --db=test_db --tags=my_tag,my_tag2 "
    Write-Output ""
    Write-Output "(M) --> Mandatory parameter "
    Write-Output "(N) --> Need parameter "
    Write-Output ""
    Write-Output "-n, -name                 (M) (N)  Set project directory and containers names"
    Write-Output "-o, -odoo                     (N)  Set version of Odoo"
    Write-Output "-p, -psql                     (N)  Set version of postgreSQL "
    Write-Output "-a, -addons                   (N)  Set addons repository HTTPS url"
    Write-Output "-b, -branch                   (N)  Set addons repository branch"
    Write-Output "-e, -enterprise                    Set for install enterprise modules"
    Write-Output "-d, -delete                        Delete project if exist"
    Write-Output "-t, -test                          Run tests."
    Write-Output "-m, -module                   (N)  Module to test"
    Write-Output "    -tags                     (N)  Tags to test"
    Write-Output "    -database                 (N)  Database to test on"

    # echo some stuff here for the -a or --add-options
    Set-Location $RUN_LOCATION
    exit 2
}

############################################################
# Process the input options. Add options as needed.        #
############################################################
if($PSBoundParameters.Count -eq 0) {
    display_help
}
if ($null -ne $ODOO_VER)
{
    check_odoo_version
}
if ($null -ne $PSQL_VER)
{
    check_psql_version
}
if ($null -ne $ADDONS_URL)
{
    addons_link_compose
}

if ( $null -eq $PROJECT_NAME )
{
    Write-Output "ERROR Need to specify project name."
    display_help
    Set-Location $RUN_LOCATION
    exit 2
}

############################################################
############################################################
# Main Program                                             #
############################################################
############################################################

check_project
