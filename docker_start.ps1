############################################################
# Default Values                                           #
############################################################

# Flags

# Variables
$ODOO_VER="15.0"
$PSQL_VER="13"
$PROJECTS_DIR="$HOME/Dokumenty/DockerProjects/"
# Odoo
$ODOO_GITHUB_NAME="odoo"
$ODOO_ENTERPRISE_REPOSITORY="enterprise"
############################################################
# Functions                                                #
############################################################

function customize_env {
    # CUSTOMIZE .ENV VARIABLES
    (Get-Content .\env) | ForEach-Object { $_ -replace "PROJECT_NAME=TEST_PROJECT", "PROJECT_NAME=$PROJECT_NAME" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "ODOO_VER=15.0", "ODOO_VER=$ODOO_VER" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "PSQL_VER=13", "PSQL_VER=$PSQL_VER" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "ODOO_CONT_NAME=ODOO_TEMP_CONT", "ODOO_CONT_NAME=$PROJECT_NAME-web" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "PSQL_CONT_NAME=PSQL_TEMP_CONT", "PSQL_CONT_NAME=$PROJECT_NAME-db" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "SMTP_CONT_NAME=SMTP_TEMP_CONT", "SMTP_CONT_NAME=$PROJECT_NAME-smtp" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "PROJECT_LOCATION=TEST_LOCATION", "PROJECT_LOCATION=$PROJECT_FULLPATH" } | Set-Content test.txt

    Get-Content .env
}

function standarize_env {
    # RETURN TO STANDARD .ENV VARIABLES
    (Get-Content .\env) | ForEach-Object { $_ -replace "PROJECT_NAME=$PROJECT_NAME", "PROJECT_NAME=TEST_PROJECT" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "ODOO_VER=$ODOO_VER", "ODOO_VER=15.0" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "PSQL_VER=$PSQL_VER", "PSQL_VER=13" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "ODOO_CONT_NAME=$PROJECT_NAME-web", "ODOO_CONT_NAME=ODOO_TEMP_CONT" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "PSQL_CONT_NAME=$PROJECT_NAME-db", "PSQL_CONT_NAME=PSQL_TEMP_CONT" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "SMTP_CONT_NAME=$PROJECT_NAME-smtp", "SMTP_CONT_NAME=SMTP_TEMP_CONT" } | Set-Content test.txt
    (Get-Content .\env) | ForEach-Object { $_ -replace "PROJECT_LOCATION=$PROJECT_FULLPATH", "PROJECT_LOCATION=TEST_LOCATION" } | Set-Content test.txt
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
    Remove-Item $PROJECT_FULLPATH -Recurse
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
    if ( $null -ne $DELETE )
    {
        delete_project
        exit 1
    }
    elseif ( $null -ne $TEST )
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
    Copy-Item .\launch.json -Destination $PROJECT_FULLPATH\.vscode\ -Recurse
    clone_addons
    if ( $null -ne $INSTALL_ENTERPRISE_MODULES )
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
    $PROJECT_FULLPATH="$PROJECTS_DIR$PROJECT_NAME"
    if ( Test-Path $PROJECT_FULLPATH )
    {
        project_exist
    }
    elseif ( $null -ne $DELETE )
    {
        Write-Output "PROJECT DESN'T EXIST"
        exit 1
    }
    else
    {
        create_project_directiories
        create_project
    }
}

function check_odoo_version {
    $ODOO_VER=$args[1]
    if ( $ODOO_VER.Substring($ODOO_VER.Length-1) -ne ".0" )
    {
        $ODOO_VER="$ODOO_VER.0"
    }
}

function check_psql_version {
    $PSQL_VER=$args[1]
    if ( $PSQL_VER.Substring($PSQL_VER.Length-1) -eq ".0" )
    {
        $PSQL_VER=$PSQL_VER.Substring(0,2)
    }
}
###################################
# CREATE AND RETRIEVE SECRET KEYS #
###################################
function get_addons_secret {
    $GITHUB_ADDONS_TOKEN=get_secret github_addons_token
    $GITHUB_ADDONS_ACCOUNT=get_secret github_addons_account
}

function get_enterprise_secret {
    $GITHUB_ENTERPRISE_TOKEN=get_secret github_enterprise_token
    $GITHUB_ENTERPRISE_ACCOUNT=get_secret github_enterprise_account
}

function addons_link_compose {

    # https://github.com/rnwood/smtp4dev.git
    $ADDONS_URL=$args[1]
    if ( $ADDONS_URL -notlike "*github.com*" )
    {
        Write-Output "Currently only github URLs accepted"
        display_help
    }
    # Currently support only HTTPS connection
    if ( $ADDONS_URL -like "*https://*" )
    {
        $ADDONS_URL=$ADDONS_URL.Substring(8, $ADDONS_URL.Length-1)
    }
    else
    {
        Write-Output "Currently only HTTPS URLs are accepted"
        display_help
    }
    get_addons_secret
    $ADDONS_CLONE_URL="https://$GITHUB_ADDONS_TOKEN@$ADDONS_URL"
}

function enterprise_link_compose {
    get_enterprise_secret
    $ENTERPRISE_CLONE_URL="https://$GITHUB_ENTERPRISE_TOKEN@github.com/$ODOO_GITHUB_NAME/$ODOO_ENTERPRISE_REPOSITORY.git"
}
############################################################
# Help                                                     #
############################################################
function display_help {
    $script_name = "docker_start.ps1"
    # taken from https://stackoverflow.com/users/4307337/vincent-stans
    Write-Output "Usage: $script_name -n {project_name} [parameters...] "
    Write-Output "   Examples:"
    Write-Output "   $script_name -n Test_Project -e -o 14.0 -p 12"
    Write-Output "   $script_name -n Test_Project"
    Write-Output "   $script_name -n Test_Project -t --db=test_db -m my_module "
    Write-Output "   $script_name -n Test_Project -t --db=test_db --tags=my_tag,my_tag2 "
    Write-Output
    Write-Output "   (M) --> Mandatory parameter "
    Write-Output "   (N) --> Need parameter "
    Write-Output
    Write-Output "   -n, -name                 (M) (N)  Set project directory and containers names"
    Write-Output "   -o, -odoo                     (N)  Set version of Odoo"
    Write-Output "   -p, -psql                     (N)  Set version of postgreSQL "
    Write-Output "   -a, -addons                   (N)  Set addons repository HTTPS url"
    Write-Output "   -b, -branch                   (N)  Set addons repository branch"
    Write-Output "   -e, -enterprise                    Set for install enterprise modules"
    Write-Output "   -d, -delete                        Delete project if exist"
    Write-Output "   -t, -test                          Run tests."
    Write-Output "   -m, -module                   (N)  Module to test"
    Write-Output "       -tags                     (N)  Tags to test"
    Write-Output "       -db                       (N)  Database to test on"

    # echo some stuff here for the -a or --add-options
    exit 2
}

############################################################
# Process the input options. Add options as needed.        #
############################################################

#$PARSED_ARGS=$(getopt -a -o n:o:p:a:b:m:edth -l name:,odoo:,psql:,addons:,branch:,module:,db:,tags:,enterprise,delete,test,help -- "$@")
param(
    [Parameter(Mandatory)] [Alias('n', 'name')] $PROJECT_NAME,

    [Alias('o', 'odoo')] $check_odoo_version,

    [Alias('p', 'psql')] $check_psql_version,

    [Alias('a', 'addons')] $addons_link_compose,

    [Alias('b', 'branch')] $BRANCH_NAME,

    [Alias('e', 'enterprise')] $INSTALL_ENTERPRISE_MODULES,
    
    [Alias('d', 'delete')] [switch] $DELETE,
    
    [Alias('t', 'test')] [switch] $TEST,

    [Alias('m', 'module')] $TEST_MODULE,

    [Alias('db')] $TEST_DB,

    [Alias('tags')] $TEST_TAGS,

    [Alias('h', 'help')] [switch] $display_help

)
VALID_ARGS=$?
if [ "$VALID_ARGS" != "0" ]; then
    display_help
fi

eval set -- "$PARSED_ARGS"
while :; do
    case "$1" in
    -n | --name)
        PROJECT_NAME="$2"
        shift 2
        ;;
    -o | --odoo)
        check_odoo_version "$2"
        shift 2
        ;;
    -p | --psql)
        check_psql_version "$2"
        shift 2
        ;;
    -a | --addons)
        addons_link_compose "$2"
        shift 2
        ;;
    -b | --branch)
        BRANCH_NAME="$2"
        shift 2
        ;;
    -e | --enterprise)
        INSTALL_ENTERPRISE_MODULES='T'
        shift
        ;;
    -d | --delete)
        DELETE='T'
        shift
        ;;
    -t | --test)
        TEST='T'
        shift
        ;;
    -m | --module)
        TEST_MODULE="$2"
        shift 2
        ;;
    --db)
        TEST_DB="$2"
        shift 2
        ;;
    --tags)
        TEST_TAGS="$2"
        shift 2
        ;;
    -h | --help)
        display_help
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Unexpected option: $1"
        display_help
        ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR Need to specify project name."
    display_help
    exit 2
fi

############################################################
############################################################
# Main Program                                             #
############################################################
############################################################

check_project
