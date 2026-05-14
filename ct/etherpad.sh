#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ether/etherpad

APP="Etherpad"
var_tags="${var_tags:-docs;office}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors



function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/etherpad" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "etherpad" "etherpad/etherpad"; then
    msg_info "Stopping Service"
    systemctl stop etherpad
    msg_info "Stopped Service"

    msg_info "Creating backup"
    [ -f /opt/etherpad/settings.json ] && mv /opt/etherpad/settings.json /opt/
    for dir in blob block customize data datastore www/common/onlyoffice/dist onlyoffice-conf; do
      [ -d "/opt/etherpad/${dir}" ] && mv "/opt/etherpad/${dir}" "/tmp/etherpad_${dir//\//_}"
    done
    msg_ok "Created backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "etherpad" "etherpad/etherpad" "tarball"

    msg_info "Restoring backup"
    mv /opt/settings.json /opt/etherpad/
#    for dir in blob block customize data datastore www/common/onlyoffice/dist onlyoffice-conf; do
#      [ -d "/tmp/etherpad_${dir//\//_}" ] && mv "/tmp/etherpad_${dir//\//_}" "/opt/etherpad/${dir}"
#    done
    msg_ok "Restored backup"

    msg_info "Updating etherpad"
    cd /opt/etherpad
    $STD pnpm ci
    $STD pnpm run install:components
    $STD pnpm run build
    msg_ok "Updated Etherpad"

    msg_info "Starting Service"
    systemctl start etherpad
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
