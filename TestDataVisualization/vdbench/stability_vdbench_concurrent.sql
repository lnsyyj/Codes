/*
Navicat MySQL Data Transfer

Source Server         : prometheus
Source Server Version : 50556
Source Host           : 10.110.144.55:3306
Source Database       : ceph

Target Server Type    : MYSQL
Target Server Version : 50556
File Encoding         : 65001

Date: 2018-11-13 10:55:16
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for stability_vdbench_concurrent
-- ----------------------------
DROP TABLE IF EXISTS `stability_vdbench_concurrent`;
CREATE TABLE `stability_vdbench_concurrent` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `datetime` datetime DEFAULT NULL,
  `outputinterval` int(255) DEFAULT NULL,
  `iorate` double(255,3) DEFAULT NULL,
  `MBsec` double(255,3) DEFAULT NULL,
  `bytesio` int(255) DEFAULT NULL,
  `readpct` double(255,3) DEFAULT NULL,
  `resptime` double(255,3) DEFAULT NULL,
  `readresp` double(255,3) DEFAULT NULL,
  `writeresp` double(255,3) DEFAULT NULL,
  `respmax` double(255,3) DEFAULT NULL,
  `respstddev` double(255,3) DEFAULT NULL,
  `queuedepth` double(255,3) DEFAULT NULL,
  `cpupercentagesysu` double(255,3) DEFAULT NULL,
  `cpupercentagesys` double(255,3) DEFAULT NULL,
  `clustercapacitypercentage` double(255,3) DEFAULT NULL,
  `operationtabledate` datetime DEFAULT NULL,
  `testcase` varchar(255) DEFAULT NULL,
  `client_number` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=480153 DEFAULT CHARSET=utf8;
