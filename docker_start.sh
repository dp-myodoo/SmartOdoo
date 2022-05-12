#!/bin/bash
. encpass.sh
# V1.0 


############################################################
# Default Values                                           #
############################################################

# Flags

# Variables
ODOO_VER="15.0"
PSQL_VER="13"
PROJECTS_DIR="${HOME}/Dokumenty/DockerProjects/"
# Odoo
ODOO_GITHUB_NAME="odoo"
ODOO_ENTERPRISE_REPOSITORY="enterprise"
############################################################
# Functions                                                #
############################################################

customize_env() {
    # CUSTOMIZE .ENV VARIABLES
    sed -i "s|^PROJECT_NAME=TEST_PROJECT *|PROJECT_NAME=$PROJECT_NAME|g" .env
    sed -i "s|^ODOO_VER=15.0 *|ODOO_VER=$ODOO_VER|g" .env
    sed -i "s|^PSQL_VER=13 *|PSQL_VER=$PSQL_VER|g" .env
    sed -i "s|^ODOO_CONT_NAME=ODOO_TEMP_CONT *|ODOO_CONT_NAME=$PROJECT_NAME-web|g" .env
    sed -i "s|^PSQL_CONT_NAME=PSQL_TEMP_CONT *|PSQL_CONT_NAME=$PROJECT_NAME-db|g" .env
    sed -i "s|^SMTP_CONT_NAME=SMTP_TEMP_CONT *|SMTP_CONT_NAME=$PROJECT_NAME-smtp|g" .env
    sed -i "s|^PROJECT_LOCATION=TEST_LOCATION *|PROJECT_LOCATION=$PROJECT_FULLPATH|g" .env

    echo
    cat .env

}

standarize_env() {
    # RETURN TO STANDARD .ENV VARIABLES
    sed -i "s|^PROJECT_NAME=$PROJECT_NAME|PROJECT_NAME=TEST_PROJECT|g" .env
    sed -i "s|^ODOO_VER=$ODOO_VER*|ODOO_VER=15.0|g" .env
    sed -i "s|^PSQL_VER=$PSQL_VER*|PSQL_VER=13|g" .env
    sed -i "s|^ODOO_CONT_NAME=$PROJECT_NAME-web *|ODOO_CONT_NAME=ODOO_TEMP_CONT |g" .env
    sed -i "s|^PSQL_CONT_NAME=$PROJECT_NAME-db *|PSQL_CONT_NAME=PSQL_TEMP_CONT |g" .env
    sed -i "s|^SMTP_CONT_NAME=$PROJECT_NAME-smtp *|SMTP_CONT_NAME=SMTP_TEMP_CONT |g" .env
    sed -i "s|^PROJECT_LOCATION=$PROJECT_FULLPATH *|PROJECT_LOCATION=TEST_LOCATION |g" .env


}

clone_addons() {
    if  [ ! -z "${ADDONS_CLONE_URL}" ]; then
        if [ ! -z "${BRANCH_NAME}" ]; then
            git -C "${PROJECT_FULLPATH}" clone "${ADDONS_CLONE_URL}"  --branch "${BRANCH_NAME}" addons 
        else
            git -C "${PROJECT_FULLPATH}" clone "${ADDONS_CLONE_URL}" addons 
        fi
    fi
}
clone_enterprise() {
    enterprise_link_compose
    if  [ ! -z "${ENTERPRISE_CLONE_URL}" ]; then
            git -C "${PROJECT_FULLPATH}" clone "${ENTERPRISE_CLONE_URL}"  --branch "${ODOO_VER}" enterprise 
    fi
}

delete_project() {
    echo "DELETING PROJECT AND VOLUMES"
    (cd $PROJECT_FULLPATH; docker-compose down -v)
    echo "DELETING PROJECT DIRECTORY"
    sudo rm -r ${PROJECT_FULLPATH}

}

project_start() {
    # Find project in running containers and start or restart
    RUNNING_CONTAINERS="$(docker ps)"
    # echo "$RUNNING_CONTAINERS" | wc -l
    if [[ $RUNNING_CONTAINERS == *"$PROJECT_NAME"* ]]; then
        echo "RESTARTING $PROJECT_NAME"
        (cd $PROJECT_FULLPATH; docker-compose restart)
    else
        echo "UPDATE GIT REPO"
        git -C "${PROJECT_FULLPATH}/addons" stash
        git -C "${PROJECT_FULLPATH}/addons" pull
        git -C "${PROJECT_FULLPATH}/addons" stash pop
        echo "STARTING $PROJECT_NAME"
        (cd $PROJECT_FULLPATH; docker-compose start)
    fi
}

run_unit_tests(){
    if [ -z TEST_DB ] || [ "$TEST_DB" == "" ]; then
        echo "You need to specify database to run tests on. Use --db."
        display_help
    fi
    if [ -v TEST_MODULE ]; then
        echo "START ODOO UNIT TESTS ON ($TEST_DB) DB FOR ($TEST_MODULE) MODULE"
        (cd $PROJECT_FULLPATH; docker-compose run --rm web --test-enable --log-level=test --stop-after-init -d ${TEST_DB} -i ${TEST_MODULE})
    elif [ -v TEST_TAGS ]; then
        echo "START ODOO UNIT TESTS ON ($TEST_DB) DB FOR ($TEST_TAGS) TAGS"
        (cd $PROJECT_FULLPATH; docker-compose run --rm web --test-enable --log-level=test --stop-after-init -d ${TEST_DB} --test-tags=${TEST_TAGS})
    else
        echo "You need to specify module or tags. Use -m or --tags"
        display_help
    fi
}

project_exist() {
    if [ ! -z "${DELETE}" ]; then
        delete_project
        exit 1
    elif [ ! -z "${TEST}" ]; then
        run_unit_tests
    else
        project_start
    fi
}

create_project() {
    echo "CREATE PROJECT"
    cp -r ./config/* "${PROJECT_FULLPATH}/config/"
    cp -r ./docker-compose.yml "${PROJECT_FULLPATH}/"
    cp -r ./entrypoint.sh "${PROJECT_FULLPATH}/"
    cp -r ./launch.json "${PROJECT_FULLPATH}/.vscode/"
    clone_addons
    if [ ! -z "${INSTALL_ENTERPRISE_MODULES}" ]; then
        clone_enterprise
    fi
    customize_env
    cp -r ./.env "${PROJECT_FULLPATH}/"
    # docker-compose -p "${PROJECT_NAME}" --project-directory "${PROJECT_FULLPATH}" up --detach
    docker-compose -p "${PROJECT_NAME}" -f "${PROJECT_FULLPATH}/docker-compose.yml" up --detach
    standarize_env
}

create_project_directiories() {
    mkdir -p "$PROJECT_FULLPATH"
    mkdir -p "$PROJECT_FULLPATH/addons"
    mkdir -p "$PROJECT_FULLPATH/enterprise"
    mkdir -p "$PROJECT_FULLPATH/config"
    mkdir -p "${PROJECT_FULLPATH}/.vscode"
}

check_project() {
    PROJECT_FULLPATH="$PROJECTS_DIR""$PROJECT_NAME"
    if [ -d "${PROJECT_FULLPATH}" ]; then
        project_exist
    elif [ ! -z "${DELETE}" ]; then
        echo "PROJECT DESN'T EXIST"
        exit 1
    else
        create_project_directiories
        create_project
    fi
}

check_odoo_version() {
    ODOO_VER=$1
    if [ ${ODOO_VER: -2} != ".0" ]; then
        ODOO_VER+=".0"
    fi
}

check_psql_version() {
    PSQL_VER=$1
    if [ ${PSQL_VER: -2} == ".0" ]; then
        PSQL_VER=${PSQL_VER::-2}
    fi
}
###################################
# CREATE AND RETRIEVE SECRET KEYS #
###################################
get_addons_secret() {
    GITHUB_ADDONS_TOKEN=$(get_secret github_addons_token)
    GITHUB_ADDONS_ACCOUNT=$(get_secret github_addons_account)
}

get_enterprise_secret() {
    GITHUB_ENTERPRISE_TOKEN=$(get_secret github_enterprise_token)
    GITHUB_ENTERPRISE_ACCOUNT=$(get_secret github_enterprise_account)
}

addons_link_compose() {

    # https://github.com/rnwood/smtp4dev.git
    ADDONS_URL=$1
    if [[ "${ADDONS_URL}" != *"github.com"* ]]; then
        echo "Currently only github URLs accepted"
        display_help
    fi
    # Currently support only HTTPS connection
    if [[ "$ADDONS_URL" == *"https://"* ]]; then
        ADDONS_URL="${ADDONS_URL:8}"
    else
        echo "Currently only HTTPS URLs are accepted"
        display_help
    fi
    get_addons_secret
    ADDONS_CLONE_URL="https://${GITHUB_ADDONS_TOKEN}@${ADDONS_URL}"
}

enterprise_link_compose() {
    get_enterprise_secret
    ENTERPRISE_CLONE_URL="https://${GITHUB_ENTERPRISE_TOKEN}@github.com/${ODOO_GITHUB_NAME}/${ODOO_ENTERPRISE_REPOSITORY}.git"
}
############################################################
# Help                                                     #
############################################################
display_help() {
    # taken from https://stackoverflow.com/users/4307337/vincent-stans
    echo "Usage: $0 -n {project_name} [parameters...] " >&2
    echo
    echo "   Examples:"
    echo "   $0 -n Test_Project -e -o 14.0 -p 12" >&2
    echo "   $0 -n Test_Project" >&2
    echo "   $0 -n Test_Project -t --db=test_db -m my_module " >&2
    echo "   $0 -n Test_Project -t --db=test_db --tags=my_tag,my_tag2 " >&2
    echo
    echo "   (M) --> Mandatory parameter "
    echo "   (N) --> Need parameter "
    echo
    echo "   -n, --name                 (M) (N)  Set project directory and containers names"
    echo "   -o, --odoo                     (N)  Set version of Odoo"
    echo "   -p, --psql                     (N)  Set version of postgreSQL "
    echo "   -a, --addons                   (N)  Set addons repository HTTPS url"
    echo "   -b, --branch                   (N)  Set addons repository branch"
    echo "   -e, --enterprise                    Set for install enterprise modules"
    echo "   -d, --delete                        Delete project if exist"
    echo "   -t, --test                          Run tests."
    echo "   -m, --module                   (N)  Module to test"
    echo "       --tags                     (N)  Tags to test"
    echo "       --db                       (N)  Database to test on"

    echo
    # echo some stuff here for the -a or --add-options
    exit 2
}

############################################################
# Process the input options. Add options as needed.        #
############################################################

PARSED_ARGS=$(getopt -a -o n:o:p:a:b:m:edth -l name:,odoo:,psql:,addons:,branch:,module:,db:,tags:,enterprise,delete,test,help -- "$@")
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
