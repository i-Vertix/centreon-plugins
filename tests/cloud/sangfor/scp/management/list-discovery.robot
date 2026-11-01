*** Settings ***
Documentation       cloud::sangfor::scp::management::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::management::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
List Resource Pools ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-resource-pools
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List resource pools: [id: a1b2c3d4-0000-4000-8000-000000000002][name: pool-lab][status: offline][type: hci][tag: public][version: 6.8.0] [id: a1b2c3d4-0000-4000-8000-000000000001][name: pool-prod][status: normal][type: hci][tag: private][version: 6.9.0]

List Clusters ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-clusters
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List clusters: [id: c1d2e3f4-0000-4000-8000-000000000002][name: cluster-lab][status: master_offline][type: hci][version: 6.7.0][az_id: a1b2c3d4-0000-4000-8000-000000000002][az_name: pool-lab] [id: c1d2e3f4-0000-4000-8000-000000000001][name: cluster-prod][status: normal][type: hci][version: 6.8.0][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod]

List Hosts ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-hosts
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List hosts: [id: host-0a1b2c3d4e01][name: 192.0.2.11][ip: 192.0.2.11][status: running][type: h][cpu_type: Intel(R) Xeon(R) CPU E3-1230 v3 @ 3.30GHz][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod] [id: host-0a1b2c3d4e02][name: 192.0.2.12][ip: 192.0.2.12][status: offline][type: h][cpu_type: Intel(R) Xeon(R) CPU E3-1230 v3 @ 3.30GHz][az_id: a1b2c3d4-0000-4000-8000-000000000002][az_name: pool-lab]

List Vms ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-vms
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List VMs: [id: f1e2d3c4-0000-4000-8000-000000000002][name: db-01][status: running][power_state: on][ip: 198.51.100.22][os_name: Debian GNU/Linux 12][os_type: l2664][host_id: host-0a1b2c3d4e01][host_name: 192.0.2.11][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod][project_name: admin][description: ] [id: f1e2d3c4-0000-4000-8000-000000000003][name: test-01][status: stopped][power_state: off][ip: 198.51.100.23][os_name: Debian GNU/Linux 12][os_type: l2664][host_id: host-0a1b2c3d4e02][host_name: 192.0.2.12][az_id: a1b2c3d4-0000-4000-8000-000000000002][az_name: pool-lab][project_name: admin][description: ] [id: f1e2d3c4-0000-4000-8000-000000000001][name: web-01][status: running][power_state: on][ip: 198.51.100.21][os_name: Debian GNU/Linux 12][os_type: l2664][host_id: host-0a1b2c3d4e01][host_name: 192.0.2.11][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod][project_name: admin][description: ]
    ...    2
    ...    --include-name=web
    ...    List VMs: [id: f1e2d3c4-0000-4000-8000-000000000001][name: web-01][status: running][power_state: on][ip: 198.51.100.21][os_name: Debian GNU/Linux 12][os_type: l2664][host_id: host-0a1b2c3d4e01][host_name: 192.0.2.11][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod][project_name: admin][description: ]

List Storages ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-storages
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List storages: [id: e396b491_vs_vol_rep2][name: datastore-vs][status: ok][type: vs][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod] [id: 1SANGFOR_ASAN-00a-299e-4c5c-b2d2-14c5fc6f319b][name: iscsi-01][status: alarm][type: iscsi][az_id: a1b2c3d4-0000-4000-8000-000000000002][az_name: pool-lab] [id: 350014ee2b684e903_001b21d61e70][name: node1_local][status: offline][type: local][az_id: a1b2c3d4-0000-4000-8000-000000000001][az_name: pool-prod]

Discovery ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=discovery
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    "discovered_items":3
    ...    2
    ...    --resource-type=vm --include-status=on
    ...    "discovered_items":2
    ...    3
    ...    --resource-type=vm --include-name=web
    ...    "ip":"198.51.100.21"
    ...    4
    ...    --resource-type=host
    ...    "discovered_items":2
    ...    5
    ...    --resource-type=resourcepool
    ...    "name":"pool-prod"
    ...    6
    ...    --resource-type=cluster --exclude-name=lab
    ...    "discovered_items":1
    ...    7
    ...    --resource-type=storage
    ...    "discovered_items":3
