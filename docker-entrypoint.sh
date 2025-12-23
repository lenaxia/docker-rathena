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
    RESULT=`mysqlshow --user=${MYSQL_USERNAME} --password=${MYSQL_PASSWORD} --host=${MYSQL_HOST} --port=${MYSQL_PORT} ${MYSQL_DATABASE} | grep -v Wildcard | grep -o ${MYSQL_DATABASE}`
    if [ "$RESULT" = "${MYSQL_DATABASE}" ]; then
        return 0;
    else
        return 1;
    fi
}

check_tables_exist () {
    # Check if essential tables exist in the database
    TABLE_COUNT=`mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -D ${MYSQL_DATABASE} -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${MYSQL_DATABASE}' AND table_name IN ('login', 'char', 'storage', 'party', 'guild');"`
    if [ "${TABLE_COUNT}" -ge 5 ]; then
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
    if [ -z "${MYSQL_DATABASE}" ]; then printf "Missing MYSQL_DATABASE environment variable. Unable to continue.\n"; exit 1; fi
    if [ -z "${MYSQL_USERNAME}" ]; then printf "Missing MYSQL_USERNAME environment variable. Unable to continue.\n"; exit 1; fi
    if [ -z "${MYSQL_PASSWORD}" ]; then printf "Missing MYSQL_PASSWORD environment variable. Unable to continue.\n"; exit 1; fi

    printf "Setting up MySQL on Login Server...\n"
    # Set YAML mode (no SQL for game data)
    sed -i "s/^use_sql_db:.*/use_sql_db: no/" /opt/rAthena/conf/inter_athena.conf

    # Set server_type based on RENEWAL runtime flag (case-insensitive)
    # 0 = Pre-Renewal/Classic, 1 = Renewal
    RENEWAL_LOWER=$(echo "${RENEWAL}" | tr '[:upper:]' '[:lower:]')
    if [ "${RENEWAL_LOWER}" = "true" ] || [ "${RENEWAL_LOWER}" = "1" ] || [ "${RENEWAL_LOWER}" = "yes" ]; then
        printf "Setting server_type to Renewal (1)\n"
        sed -i "s/^server_type:.*/server_type: 1/" /opt/rAthena/conf/inter_athena.conf
    else
        printf "Setting server_type to Classic/Pre-Renewal (0)\n"
        sed -i "s/^server_type:.*/server_type: 0/" /opt/rAthena/conf/inter_athena.conf
    fi

    sed -i "s/^login_server_ip:.*/login_server_ip: ${MYSQL_HOST}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^login_server_port:.*/login_server_port: ${MYSQL_PORT}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^login_server_id:.*/login_server_id: ${MYSQL_USERNAME}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^login_server_pw:.*/login_server_pw: ${MYSQL_PASSWORD}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^login_server_db:.*/login_server_db: ${MYSQL_DATABASE}/" /opt/rAthena/conf/inter_athena.conf

    printf "Setting up MySQL on Map Server...\n"
    sed -i "s/^map_server_ip:.*/map_server_ip: ${MYSQL_HOST}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^map_server_port:.*/map_server_port: ${MYSQL_PORT}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^map_server_id:.*/map_server_id: ${MYSQL_USERNAME}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^map_server_pw:.*/map_server_pw: ${MYSQL_PASSWORD}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^map_server_db:.*/map_server_db: ${MYSQL_DATABASE}/" /opt/rAthena/conf/inter_athena.conf

    printf "Setting up MySQL on Char Server...\n"
    sed -i "s/^char_server_ip:.*/char_server_ip: ${MYSQL_HOST}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^char_server_port:.*/char_server_port: ${MYSQL_PORT}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^char_server_id:.*/char_server_id: ${MYSQL_USERNAME}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^char_server_pw:.*/char_server_pw: ${MYSQL_PASSWORD}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^char_server_db:.*/char_server_db: ${MYSQL_DATABASE}/" /opt/rAthena/conf/inter_athena.conf

    printf "Setting up MySQL on Web Server...\n"
    sed -i "s/^web_server_ip:.*/web_server_ip: ${MYSQL_HOST}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^web_server_port:.*/web_server_port: ${MYSQL_PORT}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^web_server_id:.*/web_server_id: ${MYSQL_USERNAME}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^web_server_pw:.*/web_server_pw: ${MYSQL_PASSWORD}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^web_server_db:.*/web_server_db: ${MYSQL_DATABASE}/" /opt/rAthena/conf/inter_athena.conf

    printf "Setting up MySQL on IP ban...\n"
    sed -i "s/^ipban_db_ip:.*/ipban_db_ip: ${MYSQL_HOST}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^ipban_db_port:.*/ipban_db_port: ${MYSQL_PORT}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^ipban_db_id:.*/ipban_db_id: ${MYSQL_USERNAME}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^ipban_db_pw:.*/ipban_db_pw: ${MYSQL_PASSWORD}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^ipban_db_db:.*/ipban_db_db: ${MYSQL_DATABASE}/" /opt/rAthena/conf/inter_athena.conf

    printf "Setting up MySQL on log...\n"
    sed -i "s/^log_db_ip:.*/log_db_ip: ${MYSQL_HOST}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^log_db_port:.*/log_db_port: ${MYSQL_PORT}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^log_db_id:.*/log_db_id: ${MYSQL_USERNAME}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^log_db_pw:.*/log_db_pw: ${MYSQL_PASSWORD}/" /opt/rAthena/conf/inter_athena.conf
    sed -i "s/^log_db_db:.*/log_db_db: ${MYSQL_DATABASE}/" /opt/rAthena/conf/inter_athena.conf

    if ! [ -z ${MYSQL_DROP_DB} ]; then
        if [ ${MYSQL_DROP_DB} -ne 0 ]; then
            printf "DROP FOUND, REMOVING EXISTING DATABASE...\n"
            mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -e "DROP DATABASE ${MYSQL_DATABASE};"
        fi
    fi
    printf "Checking if database already exists...\n"
    if ! check_database_exist; then
        printf "Creating database...\n"
        mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -e "CREATE DATABASE ${MYSQL_DATABASE};"
    fi

    printf "Checking if tables exist...\n"
    if ! check_tables_exist; then
        printf "Importing essential SQL files (YAML mode - game data loaded from YAML)...\n"
        # Import all SQL files from /opt/sql directory (only essential files for YAML mode)
        for sql_file in /opt/sql/*.sql; do
            if [ -f "$sql_file" ]; then
                printf "Importing %s\n" "$(basename "$sql_file")"
                mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} ${MYSQL_DATABASE} < "$sql_file"
            fi
        done

        printf "Updating interserver credentials...\n"
        mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} ${MYSQL_DATABASE} -e "UPDATE login SET userid = \"${SET_INTERSRV_USERID}\", user_pass = \"${SET_INTERSRV_PASSWD}\" WHERE account_id = 1;"
    else
        printf "Tables already exist, skipping SQL import.\n"
    fi

    if ! [ -z "${MYSQL_ACCOUNTSANDCHARS}" ]; then
        printf "Populating accounts and characters"

        # Prepare GM account variables from environment (with defaults)
        GM1_USER="${GM1_USER:-Admin}"
        GM1_PASS="${GM1_PASS:-Melon.77}"
        GM1_CHAR="${GM1_CHAR:-${GM1_USER}}"
        GM1_EMAIL="${GM1_EMAIL:-${GM1_USER}@ragnarok.com}"
        GM2_USER="${GM2_USER:-Almarc}"
        GM2_PASS="${GM2_PASS:-Melon.77}"
        GM2_CHAR="${GM2_CHAR:-${GM2_USER}}"
        GM2_EMAIL="${GM2_EMAIL:-${GM2_USER}@ragnarok.com}"
        GM_SEX="${GM_SEX:-M}"

        # Build the SQL variable setup commands
        SQL_VARS="SET @GM1_USER = '${GM1_USER}'; \
                  SET @GM1_PASS = '${GM1_PASS}'; \
                  SET @GM1_CHAR = '${GM1_CHAR}'; \
                  SET @GM1_EMAIL = '${GM1_EMAIL}'; \
                  SET @GM2_USER = '${GM2_USER}'; \
                  SET @GM2_PASS = '${GM2_PASS}'; \
                  SET @GM2_CHAR = '${GM2_CHAR}'; \
                  SET @GM2_EMAIL = '${GM2_EMAIL}'; \
                  SET @GM_SEX = '${GM_SEX}';"

        printf "\n  Using GM accounts: ${GM1_USER} (${GM1_CHAR}), ${GM2_USER} (${GM2_CHAR})\n"

        # First attempt: Try executing the script normally
        if { echo "${SQL_VARS}"; cat /root/accountsandchars.sql; } | mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -D${MYSQL_DATABASE} 2>/tmp/mysql_error.log; then
            printf " - Success!\n"
        else
            # Check if the error is related to function creation with binary logging
            if grep -q "log_bin_trust_function_creators\|DETERMINISTIC\|NO SQL\|READS SQL DATA" /tmp/mysql_error.log 2>/dev/null; then
                printf " - Function creation blocked by binary logging, trying alternative approach...\n"

                # Second attempt: Try to enable function creators for this session and retry
                if mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -D${MYSQL_DATABASE} -e "SET SESSION sql_log_bin = 0;" 2>/dev/null && \
                   { echo "${SQL_VARS}"; cat /root/accountsandchars.sql; } | mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -D${MYSQL_DATABASE} 2>/dev/null; then
                    printf " - Success with alternative approach!\n"
                else
                    printf " - Alternative approach failed, trying root user if available...\n"

                    # Third attempt: Try with root user if we have credentials
                    if ! [ -z "${MYSQL_ROOT_PASSWORD}" ] && \
                       mysql -uroot -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -D${MYSQL_DATABASE} -e "SET GLOBAL log_bin_trust_function_creators = 1;" 2>/dev/null && \
                       { echo "${SQL_VARS}"; cat /root/accountsandchars.sql; } | mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -D${MYSQL_DATABASE} 2>/dev/null; then
                        printf " - Success with root privileges!\n"
                    else
                        printf " - All attempts failed. Account creation skipped.\n"
                        printf "   You may need to manually set 'log_bin_trust_function_creators=1' on your MySQL server\n"
                        printf "   or run the account creation script manually after startup.\n"
                    fi
                fi
            else
                printf " - Failed with unknown error:\n"
                cat /tmp/mysql_error.log 2>/dev/null || printf "   Could not read error details\n"
            fi
        fi

        # Cleanup temporary error log
        rm -f /tmp/mysql_error.log 2>/dev/null
    fi
}

setup_config () {
    if [ -z "${SET_PINCODE_ENABLED}" ]; then SET_PINCODE_ENABLED="no"; fi 
    if [ -z "${CLIENT_SUBNET}" ]; then CLIENT_SUBNET="192.168.0.0/16"; fi
    if [ -z "${USE_SQL_DB}" ]; then USE_SQL_DB="no"; fi
    if [ -z "${SET_SERVER_NAME}" ]; then SET_SERVER_NAME="rAthena"; fi
    if [ -z "${SET_LOG_FILTER}" ]; then SET_LOG_FILTER="1"; fi
    if [ -z "${SET_LOG_CHAT}" ]; then SET_LOG_CHAT="63"; fi

    sed -i "s/^char_del_option:.*/char_del_option: 1/" /opt/rAthena/conf/char_athena.conf
    sed -i "s/^char_del_delay:.*/char_del_delay: 30/" /opt/rAthena/conf/char_athena.conf
    sed -i "s/^char_del_restriction:.*/char_del_restriction: 3/" /opt/rAthena/conf/char_athena.conf
    sed -i "s/^clear_parties:.*/clear_parties: yes/" /opt/rAthena/conf/char_athena.conf


    if ! [ -z "${SET_INTERSRV_USERID}" ]; then
        sed -i "s/^userid:.*/userid: ${SET_INTERSRV_USERID}/" /opt/rAthena/conf/map_athena.conf
        sed -i "s/^userid:.*/userid: ${SET_INTERSRV_USERID}/" /opt/rAthena/conf/char_athena.conf
    fi
    if ! [ -z "${SET_INTERSRV_PASSWD}" ]; then
        sed -i "s/^passwd:.*/passwd: ${SET_INTERSRV_PASSWD}/" /opt/rAthena/conf/map_athena.conf
        sed -i "s/^passwd:.*/passwd: ${SET_INTERSRV_PASSWD}/" /opt/rAthena/conf/char_athena.conf
    fi
    if ! [ -z "${SET_SERVER_NAME}" ]; then sed -i "s/^server_name:.*/server_name: ${SET_SERVER_NAME}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${USE_SQL_DB}" ]; then sed -i "s/^use_sql_db:.*/use_sql_db: ${USE_SQL_DB}/" /opt/rAthena/conf/inter_athena.conf; fi
    if ! [ -z "${CLIENT_SUBNET}" ]; then echo "allow: ${CLIENT_SUBNET}" >> /opt/rAthena/conf/import/packet_conf.txt; fi

    if ! [ -z "${SET_MAP_PUBLIC_IP}" ]; then sed -i "s/^\(\/\/\)\?map_ip:.*/map_ip: ${SET_MAP_PUBLIC_IP}/" /opt/rAthena/conf/map_athena.conf; fi
    if ! [ -z "${SET_CHAR_TO_LOGIN_IP}" ]; then sed -i "s/^\(\/\/\)\?login_ip:.*/login_ip: ${SET_CHAR_TO_LOGIN_IP}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_CHAR_PUBLIC_IP}" ]; then sed -i "s/^\(\/\/\)\?char_ip:.*/char_ip: ${SET_CHAR_PUBLIC_IP}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_MAP_TO_CHAR_IP}" ]; then sed -i "s/^\(\/\/\)\?char_ip:.*/char_ip: ${SET_MAP_TO_CHAR_IP}/" /opt/rAthena/conf/map_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP1}" ]; then sed -i "s/^subnet:.*/subnet: ${ADD_SUBNET_MAP1}/" /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP2}" ]; then sed -i "s/^subnet:.*/subnet: ${ADD_SUBNET_MAP2}/" /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP3}" ]; then sed -i "s/^subnet:.*/subnet: ${ADD_SUBNET_MAP3}/" /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP4}" ]; then sed -i "s/^subnet:.*/subnet: ${ADD_SUBNET_MAP4}/" /opt/rAthena/conf/subnet_athena.conf; fi
    if ! [ -z "${ADD_SUBNET_MAP5}" ]; then sed -i "s/^subnet:.*/subnet: ${ADD_SUBNET_MAP5}/" /opt/rAthena/conf/subnet_athena.conf; fi

    if ! [ -z "${SET_MAX_CONNECT_USER}" ]; then sed -i "s/^max_connect_user:.*/max_connect_user: ${SET_MAX_CONNECT_USER}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_START_ZENNY}" ]; then sed -i "s/^start_zenny:.*/start_zenny: ${SET_START_ZENNY}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_START_POINT}" ]; then sed -i "s/^start_point:.*/start_point: ${SET_START_POINT}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_START_POINT_PRE}" ]; then sed -i "s/^start_point_pre:.*/start_point_pre: ${SET_START_POINT_PRE}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_START_POINT_DORAM}" ]; then sed -i "s/^start_point_doram:.*/start_point_doram: ${SET_START_POINT_DORAM}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_START_ITEMS}" ]; then sed -i "s/^start_items:.*/start_items: ${SET_START_ITEMS}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_START_ITEMS_DORAM}" ]; then sed -i "s/^start_items_doram:.*/start_items_doram: ${SET_START_ITEMS_DORAM}/" /opt/rAthena/conf/char_athena.conf; fi
    if ! [ -z "${SET_PINCODE_ENABLED}" ]; then sed -i "s/^pincode_enabled:.*/pincode_enabled: ${SET_PINCODE_ENABLED}/" /opt/rAthena/conf/char_athena.conf; fi

    if ! [ -z "${SET_NEW_ACCOUNT}" ]; then sed -i "s/^new_account:.*/new_account: ${SET_NEW_ACCOUNT}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_ALLOWED_REGS}" ]; then sed -i "s/^allowed_regs:.*/allowed_regs: ${SET_ALLOWED_REGS}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_TIME_ALLOWED}" ]; then sed -i "s/^time_allowed:.*/time_allowed: ${SET_TIME_ALLOWED}/" /opt/rAthena/conf/login_athena.conf; fi

    if ! [ -z "${SET_LOG_FILTER}" ]; then sed -i "s/^log_filter:.*/log_filter: ${SET_LOG_FILTER}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_LOG_CHAT}" ]; then sed -i "s/^log_chat:.*/log_chat: ${SET_LOG_CHAT}/" /opt/rAthena/conf/login_athena.conf; fi

    # IP Ban configuration
    if ! [ -z "${SET_IPBAN_ENABLE}" ]; then sed -i "s/^ipban_enable:.*/ipban_enable: ${SET_IPBAN_ENABLE}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN}" ]; then sed -i "s/^ipban_dynamic_pass_failure_ban:.*/ipban_dynamic_pass_failure_ban: ${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN_INTERVAL}" ]; then sed -i "s/^ipban_dynamic_pass_failure_ban_interval:.*/ipban_dynamic_pass_failure_ban_interval: ${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN_INTERVAL}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN_LIMIT}" ]; then sed -i "s/^ipban_dynamic_pass_failure_ban_limit:.*/ipban_dynamic_pass_failure_ban_limit: ${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN_LIMIT}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN_DURATION}" ]; then sed -i "s/^ipban_dynamic_pass_failure_ban_duration:.*/ipban_dynamic_pass_failure_ban_duration: ${SET_IPBAN_DYNAMIC_PASS_FAILURE_BAN_DURATION}/" /opt/rAthena/conf/login_athena.conf; fi
    if ! [ -z "${SET_IPBAN_CLEANUP_INTERVAL}" ]; then sed -i "s/^ipban_cleanup_interval:.*/ipban_cleanup_interval: ${SET_IPBAN_CLEANUP_INTERVAL}/" /opt/rAthena/conf/login_athena.conf; fi
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

sed -i '39,54s/^/\/\//' /opt/rAthena/npc/re/warps/cities/izlude.txt
sed -i '94,113s/^/\/\//' /opt/rAthena/npc/re/warps/fields/prontera_fild.txt

exec "$@"
