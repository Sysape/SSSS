-- MySQL dump 10.11
--
-- Host: localhost    Database: solsys
-- ------------------------------------------------------
-- Server version	5.0.41-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment` (
  `id` mediumint(9) NOT NULL auto_increment,
  `custid` mediumint(9) default NULL,
  `date` date default NULL,
  `comment` varchar(5000) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2467 DEFAULT CHARSET=latin1;

--
-- Table structure for table `customer`
--

DROP TABLE IF EXISTS `customer`;
CREATE TABLE `customer` (
  `id` mediumint(9) NOT NULL auto_increment,
  `name` varchar(50) default NULL,
  `address` varchar(250) default NULL,
  `phone` varchar(50) default NULL,
  `email` varchar(50) default NULL,
  `reff` varchar(5) default NULL,
  `grantype` varchar(5) default NULL,
  `lead` varchar(5) default NULL,
  `first` date default NULL,
  `stage` varchar(23) default NULL,
  `actdate` date default NULL,
  `assign` varchar(10) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=856 DEFAULT CHARSET=latin1;

--
-- Table structure for table `inverters`
--

DROP TABLE IF EXISTS `inverters`;
CREATE TABLE `inverters` (
  `id` mediumint(9) NOT NULL auto_increment,
  `make` varchar(50) default NULL,
  `model` varchar(50) default NULL,
  `wattsin` decimal(5,0) default NULL,
  `wattsout` decimal(5,0) default NULL,
  `price` decimal(7,2) default NULL,
  `supplier` varchar(50) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=40 DEFAULT CHARSET=latin1;

--
-- Table structure for table `mounting`
--

DROP TABLE IF EXISTS `mounting`;
CREATE TABLE `mounting` (
  `id` mediumint(9) NOT NULL auto_increment,
  `name` varchar(50) default NULL,
  `price` decimal(7,2) default NULL,
  `supplier` varchar(50) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `panels`
--

DROP TABLE IF EXISTS `panels`;
CREATE TABLE `panels` (
  `id` mediumint(9) NOT NULL auto_increment,
  `make` varchar(50) default NULL,
  `model` varchar(50) default NULL,
  `watts` decimal(5,0) default NULL,
  `length` decimal(5,0) default NULL,
  `width` decimal(5,0) default NULL,
  `height` decimal(5,0) default NULL,
  `pricepW` decimal(5,2) default NULL,
  `supplier` varchar(50) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-07-05 22:26:22
