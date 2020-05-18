#!/bin/bash
# Entrypoint for Docker Container

echo "Starting....."

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# see http://stackoverflow.com/a/2705678/433558
sed_escape_lhs() {
    echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
}
sed_escape_rhs() {
    echo "$@" | sed -e 's/[\/&]/\\&/g'
}
php_escape() {
    php -r 'var_export(('$2') $argv[1]);' -- "$1"
}
set_config() {
    key="$1"
    value="$2"
    sed -i "/'$key'/s/>\(.*\)/>$value,/1"  application/config/config.php
}

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

DB_TYPE=${DB_TYPE:-'mysql'}
DB_HOST=${DB_HOST:-'mysql'}
DB_PORT=${DB_PORT:-'3306'}
DB_SOCK=${DB_SOCK:-}
DB_NAME=${DB_NAME:-'limesurvey'}
DB_TABLE_PREFIX=${DB_TABLE_PREFIX:-'lime_'}
USE_INNODB=${USE_INNODB:-}
MYSQL_SSL_CA=${MYSQL_SSL_CA:-}
DB_USERNAME=${DB_USERNAME:-'limesurvey'}
# DB_PASSWORD=${DB_PASSWORD:-}
file_env 'DB_PASSWORD' ''

ADMIN_USER=${ADMIN_USER:-'admin'}
ADMIN_NAME=${ADMIN_NAME:-'admin'}
ADMIN_EMAIL=${ADMIN_EMAIL:-'foobar@example.com'}
#ADMIN_PASSWORD=${ADMIN_PASSWORD:-'-'}
file_env 'ADMIN_PASSWORD' ''

PUBLIC_URL=${PUBLIC_URL:-}
URL_FORMAT=${URL_FORMAT:-'path'}

DEBUG=${DEBUG:-'0'}
SQL_DEBUG=${SQ_DEBUG:-'0'}


# Check if database is available
if [ -z "$DB_SOCK" ]; then
    until nc -z -v -w30 $DB_HOST $DB_PORT
    do
        echo "Info: Waiting for database connection..."
        sleep 5
    done
fi


# Check if already provisioned
if [ -f application/config/config.php ]; then
    echo 'Info: config.php already provisioned'
    echo "Continue..."
fi
#else
    echo 'Info: Generating config.php'

    if [ "$DB_TYPE" = 'mysql' ]; then
        echo 'Info: Using MySQL configuration'
        DB_CHARSET=${DB_CHARSET:-'utf8mb4'}
        cp application/config/config-sample-mysql.php application/config/config.php
    fi

    if [ "$DB_TYPE" = 'pgsql' ]; then
        echo 'Info: Using PostgreSQL configuration'
        DB_CHARSET=${DB_CHARSET:-'utf8'}
        cp application/config/config-sample-pgsql.php application/config/config.php
    fi

#    # Set Database config
#    if [ ! -z "$DB_SOCK" ]; then
#        echo 'Info: Using unix socket'
#        sed -i "s#\('connectionString' => \).*,\$#\\1'${DB_TYPE}:unix_socket=${DB_SOCK};dbname=${DB_NAME};',#g" application/config/config.php
#    else
#        echo 'Info: Using TCP connection'
#        sed -i "s#\('connectionString' => \).*,\$#\\1'${DB_TYPE}:host=${DB_HOST};port=${DB_PORT};dbname=${DB_NAME};',#g" application/config/config.php
#    fi
#
#    sed -i "s#\('username' => \).*,\$#\\1'${DB_USERNAME}',#g" application/config/config.php
#    sed -i "s#\('password' => \).*,\$#\\1'${DB_PASSWORD}',#g" application/config/config.php
#    sed -i "s#\('charset' => \).*,\$#\\1'${DB_CHARSET}',#g" application/config/config.php
#    sed -i "s#\('tablePrefix' => \).*,\$#\\1'${DB_TABLE_PREFIX}',#g" application/config/config.php
#
#    # Set URL config
#    sed -i "s#\('urlFormat' => \).*,\$#\\1'${URL_FORMAT}',#g" application/config/config.php
#
#    # Set Public URL
#    if [ -z "$PUBLIC_URL" ]; then
#        echo 'Info: Setting PublicURL'
#        sed -i "s#\('debug'=>0,\)\$#'publicurl'=>'${PUBLIC_URL}',\n\t\t\\1 #g" application/config/config.php
#    fi
#fi

set_config 'connectionString' "'mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_NAME;'"
set_config 'tablePrefix'      "'$DB_TABLE_PREFIX'"
set_config 'username'         "'$DB_USERNAME'"
set_config 'password'         "'$DB_PASSWORD'"
#set_config 'publicurl'        "$PUBLIC_URL"
set_config 'urlFormat'        "'$URL_FORMAT'"
set_config 'charset'          "'$DB_CHARSET'"
set_config 'debug'            "$DEBUG"
set_config 'debugsql'         "$SQL_DEBUG"

if [ -n "$MYSQL_SSL_CA" ]; then
	set_config 'attributes' "array(PDO::MYSQL_ATTR_SSL_CA => '\/var\/www\/html\/$MYSQL_SSL_CA', PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false)"
fi

if [ -n "$USE_INNODB" ]; then
    #If you want to use INNODB - remove MyISAM specification from LimeSurvey code
    sed -i "/ENGINE=MyISAM/s/\(ENGINE=MyISAM \)//1" application/core/db/MysqlSchema.php
    #Also set mysqlEngine in config file
    sed -i "/\/\/ Update default LimeSurvey config here/s//'mysqlEngine'=>'InnoDB',/" application/config/config.php
    DBENGINE='InnoDB'
fi

chown www-data:www-data -R tmp
mkdir -p upload/surveys
mkdir -p upload/plugins
chown www-data:www-data -R upload
chown www-data:www-data -R application/config

# DBSTATUS=$(TERM=dumb php -- "$LIMESURVEY_DB_HOST" "$LIMESURVEY_DB_USER" "$LIMESURVEY_DB_PASSWORD" "$LIMESURVEY_DB_NAME" "$LIMESURVEY_TABLE_PREFIX" "$MYSQL_SSL_CA" <<'EOPHP'

#echo "========= application/config/config.php ========="
#cat application/config/config.php
#echo "================================================="

# Check if LimeSurvey database is provisioned
echo 'Info: Check if database already provisioned. Nevermind the Stack trace.'
php application/commands/console.php updatedb


if [ $? -eq 0 ]; then
    echo 'Info: Database already provisioned'
else
    # Check if DB_PASSWORD is set
    if [ -z "$DB_PASSWORD" ]; then
        echo >&2 'Error: Missing DB_PASSWORD'
        exit 1
    fi

    # Check if DB_PASSWORD is set
    if [ -z "$ADMIN_PASSWORD" ]; then
        echo >&2 'Error: Missing ADMIN_PASSWORD'
        exit 1
    fi

    echo ''
    echo 'Running console.php install'
    php application/commands/console.php install $ADMIN_USER $ADMIN_PASSWORD $ADMIN_NAME $ADMIN_EMAIL
fi

if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASSWORD" ]; then
    echo >&2 'Updating password for admin user'
    php application/commands/console.php resetpassword "$ADMIN_USER" "$ADMIN_PASSWORD"
fi

exec "$@"