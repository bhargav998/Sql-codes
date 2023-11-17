--/***********************************************************************************************
-- *                                                                                             * 
-- *    Title                         : XXAK_ITEM_CONV_CTL.ctl                		             *
-- *    Program type                  : CTL FILE                                                 *
-- *    Description                   : Load data into XXAK_INV_MTL_ITEM_STG_T staging    	     *
-- *                                    table from data file                                     *
-- ***********************************************************************************************/
OPTIONS (SKIP = 1)
LOAD DATA
TRUNCATE
INTO TABLE XXAK_INV_MTL_ITEM_STG_T 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
   
ITEM_NUMBER  							"trim(:ITEM_NUMBER)",
ORGANIZATION_NAME 								"trim(:ORGANIZATION_NAME)",
DESCRIPTION 								"trim(:DESCRIPTION)",
PRIMARY_UOM ,
ITEM_UPDATE									"trim(:ITEM_UPDATE)",
RECORD_ID 									SEQUENCE(MAX,1),
PROCESS_FLAG 								CONSTANT "N",
CREATED_BY                              	"fnd_global.user_id",
LAST_UPDATED_BY                         	"fnd_global.user_id",
LAST_UPDATE_LOGIN                       	"fnd_global.login_id",
CREATION_DATE								SYSDATE,
LAST_UPDATE_DATE							SYSDATE
)