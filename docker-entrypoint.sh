#!/bin/sh
echo "rAthena Development Team presents"
echo "           ___   __  __"
echo "     _____/   | / /_/ /_  ___  ____  ____ _"
echo "    / ___/ /| |/ __/ __ \/ _ \/ __ \/ __  /"
echo "   / /  / ___ / /_/ / / /  __/ / / / /_/ /"
echo "  /_/  /_/  |_\__/_/ /_/\___/_/ /_/\__,_/"
echo ""
echo "http://rathena.org/board/"
echo ""
DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "Initalizing Docker container..."

check_database_exist () {
    RESULT=`mysqlshow --user=${MYSQL_USER} --password=${MYSQL_PWD} --host=${MYSQL_HOST} ${MYSQL_DB} | grep -v Wildcard | grep -o ${MYSQL_DB}`
    if [ "$RESULT" = "${MYSQL_DB}" ]; then
        return 0;
    else
        return 1;
    fi
}

setup_init () {
    if ! [ -z "${SET_MOTD}" ]; then printf "%s\n" "${SET_MOTD}" > /opt/rAthena/conf/motd.txt; fi
    setup_mysql_config
    setup_config
    enable_custom_npc
}

setup_mysql_config () {
    printf "###### MySQL setup ######\n"
    if [ -z "${MYSQL_HOST}" ]; then printf "Missing MYSQL_HOST environment variable. Unable to continue.\n"; exit 1; fi
    if [ -z "${MYSQL_DB}" ]; then printf "Missing MYSQL_DB environment variable. Unable to continue.\n"; exit 1; fi
    if [ -z "${MYSQL_USER}" ]; then printf "Missing MYSQL_USER environment variable. Unable to continue.\n"; exit 1; fi
    if [ -z "${MYSQL_PWD}" ]; then printf "Missing MYSQL_PWD environment variable. Unable to continue.\n"; exit 1; fi

    printf "Setting up MySQL on Login Server...\n"
    printf "use_sql_db: yes\n\n" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "login_server_ip: %s\n" "${MYSQL_HOST}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "login_server_db: %s\n" "${MYSQL_DB}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "login_server_id: %s\n" "${MYSQL_USER}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "login_server_pw: %s\n\n" "${MYSQL_PWD}" >> /opt/rAthena/conf/import/inter_conf.txt

    printf "Setting up MySQL on Map Server...\n"
    printf "map_server_ip: %s\n" "${MYSQL_HOST}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "map_server_db: %s\n" "${MYSQL_DB}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "map_server_id: %s\n" "${MYSQL_USER}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "map_server_pw: %s\n\n" "${MYSQL_PWD}" >> /opt/rAthena/conf/import/inter_conf.txt

    printf "Setting up MySQL on Char Server...\n"
    printf "char_server_ip: %s\n" "${MYSQL_HOST}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "char_server_db: %s\n" "${MYSQL_DB}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "char_server_id: %s\n" "${MYSQL_USER}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "char_server_pw: %s\n\n" "${MYSQL_PWD}" >> /opt/rAthena/conf/import/inter_conf.txt

    printf "Setting up MySQL on IP ban...\n"
    printf "ipban_db_ip: %s\n" "${MYSQL_HOST}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "ipban_db_db: %s\n" "${MYSQL_DB}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "ipban_db_id: %s\n" "${MYSQL_USER}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "ipban_db_pw: %s\n\n" "${MYSQL_PWD}" >> /opt/rAthena/conf/import/inter_conf.txt

    printf "Setting up MySQL on log...\n"
    printf "log_db_ip: %s\n" "${MYSQL_HOST}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "log_db_db: %s\n" "${MYSQL_DB}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "log_db_id: %s\n" "${MYSQL_USER}" >> /opt/rAthena/conf/import/inter_conf.txt
    printf "log_db_pw: %s\n\n" "${MYSQL_PWD}" >> /opt/rAthena/conf/import/inter_conf.txt

    printf "DROP FOUND, REMOVING EXISTING DATABASE...\n"
    if ! [ -z ${MYSQL_DROP_DB} ]; then
        if [ ${MYSQL_DROP_DB} -ne 0 ]; then
            mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -e "DROP DATABASE ${MYSQL_DB};"
        fi
    fi
    printf "Checking if database already exists...\n"
    if ! check_database_exist; then
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -e "CREATE DATABASE ${MYSQL_DB};"
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/main.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/logs.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/item_db.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/item_db2.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/item_db_re.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/item_db2_re.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/item_cash_db.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/item_cash_db2.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_db.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_db2.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_db_re.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_db2_re.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_skill_db.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_skill_db2.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_skill_db_re.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/mob_skill_db2_re.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /opt/rAthena/sql-files/roulette_default_data.sql
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} -e "UPDATE login SET userid = \"${SET_INTERSRV_USERID}\", user_pass = \"${SET_INTERSRV_PASSWD}\" WHERE account_id = 1;"
        if ! [ -z "${MYSQL_ACCOUNTSANDCHARS}" ]; then
            mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h ${MYSQL_HOST} -D${MYSQL_DB} < /root/accountsandchars.sql
        fi
    fi
}

setup_config () {
    if ! [ -z "${SET_INTERSRV_USERID}" ]; then
        printf "userid: %s\n" "${SET_INTERSRV_USERID}" >> /opt/rAthena/conf/import/map_conf.txt
        printf "userid: %s\n" "${SET_INTERSRV_USERID}" >> /opt/rAthena/conf/import/char_conf.txt
    fi
    if ! [ -z "${SET_INTERSRV_PASSWD}" ]; then
        printf "passwd: %s\n" "${SET_INTERSRV_PASSWD}" >> /opt/rAthena/conf/import/map_conf.txt
        printf "passwd: %s\n" "${SET_INTERSRV_PASSWD}" >> /opt/rAthena/conf/import/char_conf.txt
    fi

    if ! [ -z "${SET_CHAR_TO_LOGIN_IP}" ]; then printf "login_ip: %s\n" "${SET_CHAR_TO_LOGIN_IP}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_CHAR_PUBLIC_IP}" ]; then printf "char_ip: %s\n" "${SET_CHAR_PUBLIC_IP}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_MAP_TO_CHAR_IP}" ]; then printf "char_ip: %s\n" "${SET_MAP_TO_CHAR_IP}" >> /opt/rAthena/conf/import/map_conf.txt; fi
    if ! [ -z "${SET_MAP_PUBLIC_IP}" ]; then printf "map_ip: %s\n" "${SET_MAP_PUBLIC_IP}" >> /opt/rAthena/conf/import/map_conf.txt; fi
    if ! [ -z "${ADD_SUBNET_MAP1}" ]; then printf "subnet: %s\n" "${ADD_SUBNET_MAP1}" >> /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP2}" ]; then printf "subnet: %s\n" "${ADD_SUBNET_MAP2}" >> /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP3}" ]; then printf "subnet: %s\n" "${ADD_SUBNET_MAP3}" >> /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP4}" ]; then printf "subnet: %s\n" "${ADD_SUBNET_MAP4}" >> /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP5}" ]; then printf "subnet: %s\n" "${ADD_SUBNET_MAP5}" >> /opt/rAthena/conf/subnet_athena.conf; fi

    if ! [ -z "${SET_SERVER_NAME}" ]; then printf "server_name: %s\n" "${SET_SERVER_NAME}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_MAX_CONNECT_USER}" ]; then printf "max_connect_user: %s\n" "${SET_MAX_CONNECT_USER}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_START_ZENNY}" ]; then printf "start_zenny: %s\n" "${SET_START_ZENNY}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_START_POINT}" ]; then printf "start_point: %s\n" "${SET_START_POINT}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_START_POINT_PRE}" ]; then printf "start_point_pre: %s\n" "${SET_START_POINT_PRE}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_START_POINT_DORAM}" ]; then printf "start_point_doram: %s\n" "${SET_START_POINT_DORAM}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_START_ITEMS}" ]; then printf "start_items: %s\n" "${SET_START_ITEMS}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_START_ITEMS_DORAM}" ]; then printf "start_items_doram: %s\n" "${SET_START_ITEMS_DORAM}" >> /opt/rAthena/conf/import/char_conf.txt; fi
    if ! [ -z "${SET_PINCODE_ENABLED}" ]; then printf "pincode_enabled: %s\n" "${SET_PINCODE_ENABLED}" >> /opt/rAthena/conf/import/char_conf.txt; fi

    if ! [ -z "${SET_ALLOWED_REGS}" ]; then printf "allowed_regs: %s\n" "${SET_ALLOWED_REGS}" >> /opt/rAthena/conf/import/login_conf.txt; fi
    if ! [ -z "${SET_TIME_ALLOWED}" ]; then printf "time_allowed: %s\n" "${SET_TIME_ALLOWED}" >> /opt/rAthena/conf/import/login_conf.txt; fi

    if ! [ -z "${SET_ARROW_DECREMENT}" ]; then printf "arrow_decrement: %s\n" "${SET_ARROW_DECREMENT}" >> /opt/rAthena/conf/import/battle_conf.txt; fi
}

enable_custom_npc () {
    printf "npc: npc/custom/gab_npc.txt\n" >> /opt/rAthena/npc/scripts_custom.conf
}

#PUBLICIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

cd /opt/rAthena
if ! [ -z ${DOWNLOAD_OVERRIDE_CONF_URL} ]; then 
    wget -q ${DOWNLOAD_OVERRIDE_CONF_URL} -O /tmp/rathena_import_conf.zip
    if [ $? -eq 0 ]; then
        unzip /tmp/rathena_import_conf.zip -d /opt/rAthena/conf/import/
        if ! [ $? -eq 0 ]; then
            setup_init
        fi
    else
        setup_init
    fi
else
    setup_init
fi

exec "$@"
