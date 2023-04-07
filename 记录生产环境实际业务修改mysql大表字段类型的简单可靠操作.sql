# 需求：完成大表上的字段类型变更， ALTER TABLE tbl_reservation_notify_queue modify `id` BIGINT NOT NULL AUTO_INCREMENT
# 由于目前mysql8.0还不支持原表无锁操作该字段类型（还是COPY模式），数据量越大，锁表时间越长，业务永不停歇，会导致数据库会话越多。
# 因为避免免不了全量迁移数据，手动迁移较慢，所以借助DTS工具来替代全量复制+触发器的方案；

# 1.查看被修改表的建表语句，注意AUTO_INCREMENT的值
SHOW CREATE TABLE `ky_other`.`tbl_reservation_notify_queue`;

# 2.创建一个新表（已完成表字段修改） 此处不要使用create table like语句，因为这样创建的表AUTO_INCREMENT从0开始，如果这个id被别的表使用，可能会引发其它问题
CREATE TABLE `ky_other`.`tbl_reservation_notify_queue_new` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `brand_id` int(11) NOT NULL DEFAULT '0',
  `venue_id` int(11) NOT NULL DEFAULT '0',
  `reservation_id` int(11) NOT NULL DEFAULT '0',
  `start_time` bigint(20) NOT NULL DEFAULT '0',
  `accepter_id` int(11) NOT NULL DEFAULT '0',
  `accepter_name` varchar(90) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `accepter_phone` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `course_type` int(11) NOT NULL DEFAULT '1',
  `course_id` int(11) NOT NULL DEFAULT '0',
  `course_name` varchar(90) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `coach_id` int(11) NOT NULL DEFAULT '0',
  `coach_name` varchar(90) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `time` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `brand_reservation_UNIQUE` (`brand_id`,`reservation_id`),
  KEY `start_time_INDEX` (`start_time`)
) ENGINE=InnoDB AUTO_INCREMENT=原始表当前值+预留操作期间的增量（大概10万） DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

# 3.使用DTS迁移工具进行全量数据迁移和增量迁移，指定新表名称tbl_reservation_notify_queue_new，跳过检查  已测试速度很快
# mysql 8.0.13 之前rename之前不能使用LOCK TABLES(具体参照官方文档 https://dev.mysql.com/doc/refman/8.0/en/rename-table.html)
RENAME TABLE `ky_other`.tbl_reservation_notify_queue TO `ky_other`.tbl_reservation_notify_queue_old,
             `ky_other`.tbl_reservation_notify_queue_new TO `ky_other`.tbl_reservation_notify_queue;

# 4.核对记录（条数差不多一致，增量对的上）
SELECT COUNT(*) FROM `ky_other`.`tbl_reservation_notify_queue_old`;
SELECT COUNT(*) FROM `ky_other`.`tbl_reservation_notify_queue`;
SELECT id, FROM_UNIXTIME(start_time), FROM_UNIXTIME(time) FROM `ky_other`.`tbl_reservation_notify_queue` ORDER BY `id` DESC LIMIT 100;

# 5.释放迁移任务（去DTS控制台操作）
