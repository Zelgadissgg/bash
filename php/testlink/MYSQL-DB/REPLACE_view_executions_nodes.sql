CREATE OR REPLACE VIEW view_executions_nodes
AS
SELECT
    plan.id                         as plan_id,
    plan_tcv.tcversion_id           as cv_id,
    exec_info.id                    as exec_id,
    exec_info.status                as result,
    bugs.bug_id                     as bug_id,
    external_name.tc_external_id    as ext_id,
    node_case.id                    as case_id,
    node_case.name                  as case_name,
    exec_info.tcversion_number      as case_version,
    node_suite.id                   as suite_id,
    node_parent.id                  as parent_id,
    node_suite.name                 as suite_name,
    node_parent.name                as parent_name,
    external_name.execution_type    as execution
FROM
    `testplans`             plan
    LEFT OUTER JOIN
    `testplan_tcversions`   plan_tcv
        ON (
            plan.`id` = plan_tcv.`testplan_id`
            AND
            plan.`active` = 1
        )
    LEFT OUTER JOIN
    `executions`            exec_info
        ON (
            exec_info.`tcversion_id` = plan_tcv.`tcversion_id`
        AND
            exec_info.`testplan_id` = plan_tcv.`testplan_id`
        AND
            exec_info.`id` NOT IN (
            SELECT
                exec_id_1.id
            FROM
                `executions`    exec_id_1,
                `executions`    exec_id_2
            WHERE
                exec_id_1.`testplan_id` = exec_id_2.`testplan_id`
            AND
                exec_id_1.`tcversion_id` = exec_id_2.`tcversion_id`
            AND
                exec_id_1.`id` < exec_id_2.id )
        )
    LEFT OUTER JOIN
    `execution_bugs`        bugs
        ON
            bugs.`execution_id` = exec_info.`id`
    LEFT OUTER JOIN
    `nodes_hierarchy`       node_tc
        ON
        plan_tcv.`tcversion_id` = node_tc.`id`
    LEFT OUTER JOIN
    `nodes_hierarchy`       node_case
        ON
        node_tc.`parent_id` = node_case.`id`
    LEFT OUTER JOIN
    `nodes_hierarchy`       node_suite
        ON
        node_case.`parent_id` = node_suite.`id`
    LEFT OUTER JOIN
    `nodes_hierarchy`       node_parent
        ON
        node_suite.`parent_id` = node_parent.`id`
    LEFT OUTER JOIN
    `tcversions`            external_name
        ON
        external_name.`id` = node_tc.`id`
ORDER BY plan_id DESC, suite_id DESC, ext_id DESC;
