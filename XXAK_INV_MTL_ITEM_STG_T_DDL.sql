DROP TABLE XXAK_INV_MTL_ITEM_STG_T; 

CREATE TABLE XXAK_INV_MTL_ITEM_STG_T
(
  RECORD_ID                    NUMBER,
  inventory_item_id            number,
  ITEM_NUMBER                  VARCHAR2(100 ),
  ORGANIZATION_CODE            VARCHAR2(50),
  organization_id              number,
  organization_name            varchar2(150),
  DESCRIPTION                  VARCHAR2(1000 ),
  LONG_DESCRIPTION             VARCHAR2(2000 ),
  PRIMARY_UOM                  VARCHAR2(100 ),
  ITEM_UPDATE                  VARCHAR2(100 ),
  ERROR_MSG                    VARCHAR2(3000 ),
  PROCESS_FLAG                 VARCHAR2(50),
  LAST_UPDATED_BY              NUMBER,
  LAST_UPDATE_DATE             DATE,
  CREATION_DATE                DATE,
  CREATED_BY                   NUMBER,
  LAST_UPDATE_LOGIN            NUMBER,
  REQUEST_ID                   NUMBER ,
  transaction_type             VARCHAr2(100),
  int_transaction_id           number 
)  ;

/
SHOW ERRORS;
EXIT;