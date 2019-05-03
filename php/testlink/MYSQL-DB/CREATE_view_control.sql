CREATE TABLE IF NOT EXISTS `view_control` (
  `table_name` varchar(40) NOT NULL,
  `table_count` int(11) NOT NULL,
  `view_name` varchar(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`table_name`,`view_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;