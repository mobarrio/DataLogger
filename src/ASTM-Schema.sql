/*
MySQL - 5.1.53 : Database - ASTM
*********************************************************************
*/


/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`ASTM` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `ASTM`;

/*Table structure for table `Action_Code` */

DROP TABLE IF EXISTS `Action_Code`;

CREATE TABLE `Action_Code` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Action_Code` */

LOCK TABLES `Action_Code` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Orden` */

DROP TABLE IF EXISTS `Comment_Orden`;

CREATE TABLE `Comment_Orden` (
  `Comment_ID` varchar(33) NOT NULL,
  `Orden_ID` varchar(33) DEFAULT NULL,
  `Reference_Table` varchar(15) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Comment_Source` varchar(1) DEFAULT NULL,
  `Text` varchar(100) DEFAULT NULL,
  `Comment_Type` varchar(1) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Comment_ID`),
  KEY `Comment-Source` (`Comment_Source`),
  KEY `Comment-Type` (`Comment_Type`),
  KEY `Comment-Orden` (`Orden_ID`),
  CONSTRAINT `Comment_Orden` FOREIGN KEY (`Orden_ID`) REFERENCES `Orden` (`Orden_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Orden` */

LOCK TABLES `Comment_Orden` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Patient` */

DROP TABLE IF EXISTS `Comment_Patient`;

CREATE TABLE `Comment_Patient` (
  `Comment_ID` varchar(33) NOT NULL,
  `Patient_ID` varchar(33) DEFAULT NULL,
  `Reference_Table` varchar(15) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Comment_Source` varchar(1) DEFAULT NULL,
  `Text` varchar(100) DEFAULT NULL,
  `Comment_Type` varchar(1) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Comment_ID`),
  KEY `Comment-Source` (`Comment_Source`),
  KEY `Comment-Type` (`Comment_Type`),
  KEY `Comment-Orden` (`Patient_ID`),
  CONSTRAINT `Comment_Patient` FOREIGN KEY (`Patient_ID`) REFERENCES `Patient` (`Patient_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Patient` */

LOCK TABLES `Comment_Patient` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Result` */

DROP TABLE IF EXISTS `Comment_Result`;

CREATE TABLE `Comment_Result` (
  `Comment_ID` varchar(33) NOT NULL,
  `Result_ID` varchar(33) DEFAULT NULL,
  `Reference_Table` varchar(15) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Comment_Source` varchar(1) DEFAULT NULL,
  `Text` varchar(100) DEFAULT NULL,
  `Comment_Type` varchar(1) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Comment_ID`),
  KEY `Comment-Source` (`Comment_Source`),
  KEY `Comment-Type` (`Comment_Type`),
  KEY `Comment-Orden` (`Result_ID`),
  CONSTRAINT `Comment_Result` FOREIGN KEY (`Result_ID`) REFERENCES `Result` (`Result_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Result` */

LOCK TABLES `Comment_Result` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Source` */

DROP TABLE IF EXISTS `Comment_Source`;

CREATE TABLE `Comment_Source` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Source` */

LOCK TABLES `Comment_Source` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Type` */

DROP TABLE IF EXISTS `Comment_Type`;

CREATE TABLE `Comment_Type` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Type` */

LOCK TABLES `Comment_Type` WRITE;

UNLOCK TABLES;

/*Table structure for table `Header` */

DROP TABLE IF EXISTS `Header`;

CREATE TABLE `Header` (
  `Header_ID` varchar(33) NOT NULL,
  `Access_Password` varchar(50) DEFAULT NULL,
  `Sender_Name` varchar(50) DEFAULT NULL,
  `Sender_Address` varchar(50) DEFAULT NULL,
  `Reserved` varchar(50) DEFAULT NULL,
  `Sender_Telephone` varchar(20) DEFAULT NULL,
  `Characteristics_Of_Sender` varchar(50) DEFAULT NULL,
  `Receiver_ID` varchar(33) DEFAULT NULL,
  `Comments` varchar(50) DEFAULT NULL,
  `Processing_ID` varchar(33) DEFAULT NULL,
  `ASTM_Version` varchar(50) DEFAULT NULL,
  `Date_and_Time` varchar(14) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  `NumPac` int(11) DEFAULT '0',
  PRIMARY KEY (`Header_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Header` */

LOCK TABLES `Header` WRITE;

UNLOCK TABLES;

/*Table structure for table `Message_Terminator` */

DROP TABLE IF EXISTS `Message_Terminator`;

CREATE TABLE `Message_Terminator` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(70) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Message_Terminator` */

LOCK TABLES `Message_Terminator` WRITE;

UNLOCK TABLES;

/*Table structure for table `Nature_of_Abnormality_Testing` */

DROP TABLE IF EXISTS `Nature_of_Abnormality_Testing`;

CREATE TABLE `Nature_of_Abnormality_Testing` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Nature_of_Abnormality_Testing` */

LOCK TABLES `Nature_of_Abnormality_Testing` WRITE;

UNLOCK TABLES;

/*Table structure for table `Orden` */

DROP TABLE IF EXISTS `Orden`;

CREATE TABLE `Orden` (
  `Orden_ID` varchar(33) NOT NULL,
  `Patient_ID` varchar(33) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Sample_ID` varchar(22) DEFAULT NULL,
  `Instrument_Specimen_ID` varchar(1) DEFAULT NULL,
  `Universal_Test_ID` varchar(15) DEFAULT NULL,
  `Priority` varchar(1) DEFAULT NULL,
  `Requested_Ordered_Date_and_Time` varchar(20) DEFAULT NULL,
  `Specimen_Collection_Date_and_Time` varchar(20) DEFAULT NULL,
  `Collection_End_Time` varchar(20) DEFAULT NULL,
  `Collection_Volume` varchar(50) DEFAULT NULL,
  `Collector_ID` varchar(50) DEFAULT NULL,
  `Action_Code` varchar(1) DEFAULT NULL,
  `Danger_Code` varchar(50) DEFAULT NULL,
  `Relevant_Clinical_Informations` varchar(50) DEFAULT NULL,
  `Date_Time_Specimen_Received` varchar(20) DEFAULT NULL,
  `Specimen_Descriptor` varchar(20) DEFAULT NULL,
  `Ordering_Physician` varchar(50) DEFAULT NULL,
  `Physician_Tel_Nb` varchar(20) DEFAULT NULL,
  `User_Field_1` varchar(50) DEFAULT NULL,
  `User_Field_2` varchar(50) DEFAULT NULL,
  `Laboratory_Field_1` varchar(50) DEFAULT NULL,
  `Laboratory_Field_2` varchar(50) DEFAULT NULL,
  `Date_and_Time_Results_reported_or_last_modified` varchar(20) DEFAULT NULL,
  `Instrument_Charge_to_Computer_System` varchar(50) DEFAULT NULL,
  `Instrument_Section_ID` varchar(50) DEFAULT NULL,
  `Report_Types` varchar(1) DEFAULT NULL,
  `Reserved` varchar(50) DEFAULT NULL,
  `Location_or_Ward_of_Specimen_Collection` varchar(10) DEFAULT NULL,
  `Nosocomial_Infection_Flag` varchar(50) DEFAULT NULL,
  `Specimen_Service` varchar(50) DEFAULT NULL,
  `Specimen_institution` varchar(50) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Orden_ID`),
  KEY `FK_Order` (`Patient_ID`),
  KEY `Order-Action_code` (`Action_Code`),
  KEY `Order-Report_Types` (`Report_Types`),
  CONSTRAINT `FK_Order` FOREIGN KEY (`Patient_ID`) REFERENCES `Patient` (`Patient_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Orden` */

LOCK TABLES `Orden` WRITE;

UNLOCK TABLES;

/*Table structure for table `Patient` */

DROP TABLE IF EXISTS `Patient`;

CREATE TABLE `Patient` (
  `Patient_ID` varchar(33) NOT NULL,
  `Header_ID` varchar(33) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Practice_Assigned_Patient_ID` varchar(20) DEFAULT NULL,
  `Laboratory_Assigned_Patient_ID` varchar(50) DEFAULT NULL,
  `Patient_ID_No_3` varchar(50) DEFAULT NULL,
  `Patient_Name_Name_First_name` varchar(52) DEFAULT NULL,
  `Mothers_Maiden_Name` varchar(50) DEFAULT NULL,
  `Birthdate` varchar(8) DEFAULT NULL,
  `Patient_Sex` varchar(1) DEFAULT NULL,
  `Patient_Race_thnic_Origin` varchar(20) DEFAULT NULL,
  `Patient_Address` varchar(50) DEFAULT NULL,
  `Reserved` varchar(50) DEFAULT NULL,
  `Patient_Telephone_Nb` varchar(20) DEFAULT NULL,
  `Attending_Physician_ID` varchar(20) DEFAULT NULL,
  `Special_Field_1` varchar(20) DEFAULT NULL,
  `Special_Field_2` varchar(20) DEFAULT NULL,
  `Patient_Height` varchar(5) DEFAULT NULL,
  `Patient_Weight` varchar(5) DEFAULT NULL,
  `Patients_Known_or_Suspected_Diagnosis` varchar(20) DEFAULT NULL,
  `Patient_Active_Medication` varchar(20) DEFAULT NULL,
  `Patients_Diet` varchar(20) DEFAULT NULL,
  `Practice_Field_1` varchar(50) DEFAULT NULL,
  `Practice_Field_2` varchar(50) DEFAULT NULL,
  `Admission_and_Discharge_Dates` varchar(50) DEFAULT NULL,
  `Admission_Status` varchar(50) DEFAULT NULL,
  `Location` varchar(20) DEFAULT NULL,
  `Nature_of_Alternative_Diagnostic_Code_and_Classifiers_1` varchar(50) DEFAULT NULL,
  `Nature_of_Alternative_Diagnostic_Code_and_Classifiers_2` varchar(50) DEFAULT NULL,
  `Patient_Religion` varchar(50) DEFAULT NULL,
  `Martial_status` varchar(50) DEFAULT NULL,
  `Isolation_Status` varchar(50) DEFAULT NULL,
  `Language` varchar(50) DEFAULT NULL,
  `Hospital_Service` varchar(50) DEFAULT NULL,
  `Hopital_Institution` varchar(50) DEFAULT NULL,
  `Dosage_Category` varchar(50) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Patient_ID`),
  KEY `Patient-Sex` (`Patient_Sex`),
  KEY `Header-Patient` (`Header_ID`),
  CONSTRAINT `Header-Patient` FOREIGN KEY (`Header_ID`) REFERENCES `Header` (`Header_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Patient` */

LOCK TABLES `Patient` WRITE;

UNLOCK TABLES;

/*Table structure for table `Patient_Sex` */

DROP TABLE IF EXISTS `Patient_Sex`;

CREATE TABLE `Patient_Sex` (
  `id` varchar(1) NOT NULL,
  `Decripcion` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Patient_Sex` */

LOCK TABLES `Patient_Sex` WRITE;

UNLOCK TABLES;

/*Table structure for table `Priority` */

DROP TABLE IF EXISTS `Priority`;

CREATE TABLE `Priority` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Priority` */

LOCK TABLES `Priority` WRITE;

UNLOCK TABLES;

/*Table structure for table `Report_Types` */

DROP TABLE IF EXISTS `Report_Types`;

CREATE TABLE `Report_Types` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Report_Types` */

LOCK TABLES `Report_Types` WRITE;

UNLOCK TABLES;

/*Table structure for table `Result` */

DROP TABLE IF EXISTS `Result`;

CREATE TABLE `Result` (
  `Result_ID` varchar(33) NOT NULL,
  `Orden_ID` varchar(33) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Universal_Test_ID` varchar(15) DEFAULT NULL,
  `Data_or_Measurement_value` varchar(20) DEFAULT NULL,
  `Unit` varchar(50) DEFAULT NULL,
  `Reference_Range` varchar(50) DEFAULT NULL,
  `Result_Abnormal_Flag` varchar(2) DEFAULT NULL,
  `Nature_of_Abnormality_Testing` varchar(1) DEFAULT NULL,
  `Result_Status` varchar(1) DEFAULT NULL,
  `Date_of_Change_in_Normative_Values_or_Units` varchar(20) DEFAULT NULL,
  `Operator_Identification` varchar(50) DEFAULT NULL,
  `Date_Time_Test_Starting` varchar(20) DEFAULT NULL,
  `Date_Time_Test_Completed` varchar(20) DEFAULT NULL,
  `Instrument_Identification` varchar(20) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Result_ID`),
  KEY `Result-Nature_of_Abnormal_Testing` (`Nature_of_Abnormality_Testing`),
  KEY `Result-Abnormal_Flags` (`Result_Abnormal_Flag`),
  KEY `Result-Status` (`Result_Status`),
  KEY `Result-Orden` (`Orden_ID`),
  CONSTRAINT `Result-Orden` FOREIGN KEY (`Orden_ID`) REFERENCES `Orden` (`Orden_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Result` */

LOCK TABLES `Result` WRITE;

UNLOCK TABLES;

/*Table structure for table `Result_Abnormal_ Flags` */

DROP TABLE IF EXISTS `Result_Abnormal_ Flags`;

CREATE TABLE `Result_Abnormal_ Flags` (
  `id` varchar(2) NOT NULL,
  `Descripcion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Result_Abnormal_ Flags` */

LOCK TABLES `Result_Abnormal_ Flags` WRITE;

UNLOCK TABLES;

/*Table structure for table `Result_Status` */

DROP TABLE IF EXISTS `Result_Status`;

CREATE TABLE `Result_Status` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Result_Status` */

LOCK TABLES `Result_Status` WRITE;

UNLOCK TABLES;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
