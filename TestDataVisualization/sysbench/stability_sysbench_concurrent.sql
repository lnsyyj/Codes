/*
Navicat MySQL Data Transfer

Source Server         : prometheus
Source Server Version : 50556
Source Host           : 10.110.144.55:3306
Source Database       : ceph

Target Server Type    : MYSQL
Target Server Version : 50556
File Encoding         : 65001

Date: 2018-11-12 15:24:51
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for stability_sysbench_concurrent
-- ----------------------------
DROP TABLE IF EXISTS `stability_sysbench_concurrent`;
CREATE TABLE `stability_sysbench_concurrent` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `datetime` datetime DEFAULT NULL,
  `outputinterval` int(255) DEFAULT NULL,
  `thds` int(255) DEFAULT NULL,
  `tps` double(255,3) DEFAULT NULL,
  `qps` double(255,3) DEFAULT NULL,
  `qps_r` double(255,3) DEFAULT NULL,
  `qps_w` double(255,3) DEFAULT NULL,
  `qps_o` double(255,3) DEFAULT NULL,
  `lat` double(255,3) DEFAULT NULL,
  `lat_unit` varchar(255) DEFAULT NULL,
  `lat_percentage` double(255,3) DEFAULT NULL,
  `err` double(255,3) DEFAULT NULL,
  `reconn` double(255,3) DEFAULT NULL,
  `operationtabledate` datetime DEFAULT NULL,
  `client_number` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=69045 DEFAULT CHARSET=utf8;
