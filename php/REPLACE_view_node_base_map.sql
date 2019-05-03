CREATE OR REPLACE VIEW view_node_base_map
AS
SELECT
    node_root.id as r_id,
    lv1.id as lv1_id,
    lv2.id as lv2_id,
    lv3.id as lv3_id,
    lv4.id as lv4_id
FROM
    `nodes_hierarchy` node_project
    LEFT OUTER JOIN
    `nodes_hierarchy` node_root
    ON
        node_root.`parent_id` = node_project.`id`
        AND
        node_root.`node_type_id` = 2
    LEFT OUTER JOIN
    `nodes_hierarchy` lv1
    ON
        lv1.`parent_id` = node_root.`id`
        AND
        lv1.`node_type_id` = 2
    LEFT OUTER JOIN
    `nodes_hierarchy` lv2
    ON
        lv2.`parent_id` = lv1.`id`
        AND
        lv2.`node_type_id` = 2
    LEFT OUTER JOIN
    `nodes_hierarchy` lv3
    ON
        lv3.`parent_id` = lv2.`id`
        AND
        lv3.`node_type_id` = 2
    LEFT OUTER JOIN
    `nodes_hierarchy` lv4
    ON
        lv4.`parent_id` = lv3.`id`
        AND
        lv4.`node_type_id` = 2
WHERE
    ( node_project.`id` IN (
        SELECT
            id
        FROM
            testprojects
    ) )
ORDER BY
        r_id, lv1_id, lv2_id, lv3_id, lv4_id
