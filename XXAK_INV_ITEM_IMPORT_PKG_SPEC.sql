CREATE OR REPLACE PACKAGE APPS.XXAK_INV_ITEM_IMPORT_PKG
   AUTHID CURRENT_USER
AS
 
    PROCEDURE main (ERRBUF              OUT VARCHAR2,
                    RETCODE             OUT VARCHAR2,
                    piv_inv_org       IN     VARCHAR2 ,
					piv_debug_mode    IN     VARCHAR2);   

END XXAK_INV_ITEM_IMPORT_PKG;
/