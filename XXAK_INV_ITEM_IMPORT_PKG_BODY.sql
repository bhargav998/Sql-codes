CREATE OR REPLACE PACKAGE BODY APPS.XXAK_INV_ITEM_IMPORT_PKG
AS
 
------------------------------------------------
--Global Variables
------------------------------------------------
   gv_debug_flag        VARCHAR2 (50) := NULL;
   gv_report_column1    VARCHAR2 (430);
   gv_report_column2    VARCHAR2 (430);
   gn_conc_request_id   NUMBER 		  := apps.fnd_global.conc_request_id;
   gv_debug             VARCHAR2(10) 	  := 'N';
   gv_step              VARCHAR2(100) 	  := NULL;
   gn_user_id           NUMBER        := apps.fnd_profile.value('USER_ID');
   gn_set_process_id 	NUMBER 		  := 0;

   /****************************************************************************************************************************
    Name        : write_log_msg.
    Purpose      : Print messages from the procedures into concurent program log file
    Input Parameters : piv_msg
    Output Parameters: NA
    ****************************************************************************************************************************/
   PROCEDURE write_log (piv_msg VARCHAR2)
   IS
   BEGIN
      apps.fnd_file.put_line (apps.fnd_file.LOG, piv_msg);
   EXCEPTION
      WHEN OTHERS
      THEN
         apps.fnd_file.put_line (apps.fnd_file.LOG,
                                 'Error in write_log. Reason : ' || SQLERRM);
   END write_log;

   /****************************************************************************************************************************
    Name        : update_req_id_stg.
    Purpose      : Updates the request Id and WHO columns
    Input Parameters : NA
    Output Parameters: NA
    ****************************************************************************************************************************/
   PROCEDURE update_req_id_stg
   IS
   BEGIN
      update XXAK_INV_MTL_ITEM_STG_T
	  set last_updated_by = gn_user_id, 
    last_update_date = SYSDATE, creation_date = SYSDATE , 
    created_by = gn_user_id,
    last_update_login = gn_user_id, request_id = gn_conc_request_id , 
    transaction_type = 'UPDATE';
	  
	  COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_log('Error Occured in update_req_id_stg : '||SUBSTR(SQLERRM,1,255));
   END update_req_id_stg;

   /**********************************************************************************
     Name             : write_errors
     Purpose          : This procedure is used to write error details to the common error log
     Input Parameters :
						   piv_program_name          IN VARCHAR2
                           pin_request_id           IN NUMBER
                           pin_record_sr_no          IN NUMBER
                           pin_batch_id              IN NUMBER
                           piv_key_column_name       IN VARCHAR2
                           piv_key_column_value      IN VARCHAR2
                           piv_column_name           IN VARCHAR2
						   piv_column_value    IN VARCHAR2
					       piv_error_message         IN VARCHAR2
     Output Parameters: NA
     ************************************************************************************/
   PROCEDURE write_errors (piv_program_name       IN VARCHAR2,
                           pin_request_id         IN NUMBER,
                           pin_record_sr_no       IN NUMBER,
                           pin_batch_id           IN NUMBER,
                           piv_key_column_name    IN VARCHAR2,
                           piv_key_column_value   IN VARCHAR2,
                           piv_column_name        IN VARCHAR2,
                           piv_column_value       IN VARCHAR2,
                           piv_error_message      IN VARCHAR2)
   IS
      lv_error_message   VARCHAR2 (255);
      lv_sqlerrm         VARCHAR2 (3000);
   BEGIN
      /*
      ||Call the Error Framework API to write the error messages details
      */

      apps.XXAK_COMMON_ERR_PKG.INSERT_ERROR_LOG_PRC (
         piv_program_name       => piv_program_name,
         pin_request_id         => pin_request_id,
         pin_record_sr_no       => pin_record_sr_no,
         pin_batch_id           => pin_batch_id,
         piv_key_column_name    => piv_key_column_name,
         piv_key_column_value   => piv_key_column_value,
         piv_column_name        => piv_column_name,
         piv_column_value       => piv_column_value,
         piv_error_message      => piv_error_message);
   EXCEPTION
      WHEN OTHERS
      THEN
         lv_sqlerrm := SQLERRM;
         apps.fnd_file.put_line (
            apps.fnd_file.LOG,
            'Exception in write_errors. Reason - ' || lv_sqlerrm);
   END write_errors;

   /****************************************************************************************************************************
   Name        : truncate_interface_tables.
   Purpose      : Truncates the interface and error tables mtl_system_items_interface and mtl_interface_errors
   Input Parameters : NA
   Output Parameters: NA
   ****************************************************************************************************************************/

   PROCEDURE truncate_interface_tables
   IS
   BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE inv.mtl_system_items_interface';

      EXECUTE IMMEDIATE 'TRUNCATE TABLE inv.mtl_interface_errors';
   --EXECUTE IMMEDIATE 'TRUNCATE TABLE inv.mtl_item_revisions_interface';

   EXCEPTION
      WHEN OTHERS
      THEN
         write_errors (piv_program_name       => 'XXAK Item Conversion',
                       pin_request_id         => gn_conc_request_id,
                       pin_record_sr_no       => NULL,
                       pin_batch_id           => NULL,
                       piv_key_column_name    => 'TRUNCATE_INTERFACE_TABLES',
                       piv_key_column_value   => SQLCODE,
                       piv_column_name        => NULL,
                       piv_column_value       => NULL,
                       piv_error_message      => SQLERRM);
					   
   END truncate_interface_tables;


   /****************************************************************************************************************************
   Name        : validate_data
   Purpose      : Validates the staging table item data
   Input Parameters : NA
   Output Parameters: NA
   ****************************************************************************************************************************/
   PROCEDURE validate_data
   IS
      CURSOR c_validate_stg_data
      IS
         SELECT *
           FROM XXAK_INV_MTL_ITEM_STG_T
          WHERE PROCESS_FLAG = 'N' ;
		  
		  
		  lv_error_flag 		VARCHAR2(2) ;
		  lv_error_msg  		VARCHAR2(3000);
		  ln_dup_chk   			NUMBER ;
		  lv_special_char_chk 	VARCHAR2(5);
		  ln_rec_rout_id 		NUMBER ;
		  ln_pln_make_buy 		NUMBER ;
		  ln_ccid_expense 		NUMBER ;
		  lv_item_type	  		VARCHAR2(100);	
		  ln_org_id		  		NUMBER ;
		  ln_inv_item_id 		NUMBER ;
		  ln_master_org_count   NUMBER;
		  ln_last_po_days		NUMBER ;
		  ln_so_days			NUMBER ;
		  ln_wo_days			NUMBER ;
		  ln_open_po			NUMBER ;
		  ln_open_so			NUMBER ;
		  ln_open_wo			NUMBER ;
		  ln_on_hand_qty		NUMBER ;		  
		  
   BEGIN
      FOR c_item_rec IN c_validate_stg_data
      LOOP
	  
		lv_error_flag 		:= 'N';
		lv_error_msg  		:= NULL;
		ln_dup_chk    		:= NULL;
		lv_special_char_chk := NULL;
		ln_rec_rout_id 		:= NULL;
		ln_pln_make_buy 	:= NULL;
		ln_ccid_expense 	:= NULL;
		lv_item_type 		:= NULL;
		ln_org_id			:= 0;
		ln_inv_item_id      := 0;
		ln_master_org_count := 0;
 
 -----------------------------------------------------------------------------------------
         -- Check Inv Org Specified or Not
         -----------------------------------------------------------------------------------------

         BEGIN
            gv_step := '13';

            IF gv_debug = 'Y'
            THEN
               write_log ('gv_step : ' || gv_step);
            END IF;

            IF c_item_rec.organization_name IS NULL
            THEN
               lv_error_flag := 'Y';
               lv_error_msg :=
                  lv_error_msg || ';' || 'Inventory Org not specified';
               write_errors (
                  piv_program_name       => 'XXAK Item Conversion',
                  pin_request_id         => gn_conc_request_id,
                  pin_record_sr_no       => NULL,
                  pin_batch_id           => NULL,
                  piv_key_column_name    => 'RECORD_ID',
                  piv_key_column_value   => c_item_rec.record_id,
                  piv_column_name        => 'organization_name',
                  piv_column_value       => c_item_rec.organization_name,
                  piv_error_message      => 'Inventory Org not specified');
            END IF;
         END;

         -----------------------------------------------------------------------------------------
         -- Check PRimary UOM
         -----------------------------------------------------------------------------------------
         gv_step := '17';

         IF gv_debug = 'Y'
         THEN
            write_log ('gv_step : ' || gv_step);
         END IF;

         IF c_item_rec.primary_uom IS NULL
         THEN
            lv_error_flag := 'Y';
            lv_error_msg := lv_error_msg || ';' || 'Primary UOM not specified';
            write_errors (
               piv_program_name       => 'XXAK Item Conversion',
               pin_request_id         => gn_conc_request_id,
               pin_record_sr_no       => NULL,
               pin_batch_id           => NULL,
               piv_key_column_name    => 'RECORD_ID',
               piv_key_column_value   => c_item_rec.record_id,
               piv_column_name        => 'primary_uom',
               piv_column_value       => c_item_rec.primary_uom,
               piv_error_message      => 'Primary UOM not specified');
         END IF;
-------------------------------------------------------------------------
-- Organization ID 
-------------------------------------------------------------------------				


BEGIN

select organization_id  
into ln_org_id 
from HR_ALL_ORGANIZATION_UNITS 
where name = c_item_rec.organization_name;
EXCEPTION
WHEN NO_DATA_FOUND
THEN
                  lv_error_flag := 'Y';
                  lv_error_msg :=
                  lv_error_msg || ';' || 'Org Id not found';	
            write_errors (
               piv_program_name       => 'XXAK Item Conversion',
               pin_request_id         => gn_conc_request_id,
               pin_record_sr_no       => NULL,
               pin_batch_id           => NULL,
               piv_key_column_name    => 'RECORD_ID',
               piv_key_column_value   => c_item_rec.record_id,
               piv_column_name        => 'organization_name',
               piv_column_value       => c_item_rec.organization_name,
               piv_error_message      => 'Org Id not found');					  
WHEN OTHERS 
THEN 
                  lv_error_flag := 'Y';
                  lv_error_msg :=
                  lv_error_msg || ';' || 'Error deriving the Org Id';	
            write_errors (
               piv_program_name       => 'XXAK Item Conversion',
               pin_request_id         => gn_conc_request_id,
               pin_record_sr_no       => NULL,
               pin_batch_id           => NULL,
               piv_key_column_name    => 'RECORD_ID',
               piv_key_column_value   => c_item_rec.record_id,
               piv_column_name        => 'organization_code',
               piv_column_value       => c_item_rec.organization_name,
               piv_error_message      => 'Error deriving the Org Id');					  
END ;
			
--------------------------------------------------------------------------
-- Inventory Item ID
---------------------------------------------------------------------------		
BEGIN

IF c_item_rec.ITEM_UPDATE <>'Create' THEN 

    select inventory_item_id 
    into ln_inv_item_id 
    from mtl_system_items_b 
    where segment1 = c_item_rec.item_number
    and organization_id = ln_org_id;
    
    END IF ; 
    
    EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
                      lv_error_flag := 'Y';
                      lv_error_msg :=
                      lv_error_msg || ';' || 'Inv Item Id not found';	
                write_errors (
                   piv_program_name       => 'XXAK Item Conversion',
                   pin_request_id         => gn_conc_request_id,
                   pin_record_sr_no       => NULL,
                   pin_batch_id           => NULL,
                   piv_key_column_name    => 'RECORD_ID',
                   piv_key_column_value   => c_item_rec.record_id,
                   piv_column_name        => 'item number',
                   piv_column_value       => c_item_rec.item_number,
                   piv_error_message      => 'Inv Item Id not found');					  
    WHEN OTHERS 
    THEN 
                      lv_error_flag := 'Y';
                      lv_error_msg :=
                      lv_error_msg || ';' || 'Error deriving the Inv Item Id';	
                write_errors (
                   piv_program_name       => 'XXAK Item Conversion',
                   pin_request_id         => gn_conc_request_id,
                   pin_record_sr_no       => NULL,
                   pin_batch_id           => NULL,
                   piv_key_column_name    => 'RECORD_ID',
                   piv_key_column_value   => c_item_rec.record_id,
                   piv_column_name        => 'item number',
                   piv_column_value       => c_item_rec.item_number,
                   piv_error_message      => 'Error deriving the Inv Item Id');					  

   
    END ;
   
-----------------------------------
-- Update Staging table with Ids
------------------------------------	
         IF lv_error_flag = 'N'
         THEN
            UPDATE XXAK_INV_MTL_ITEM_STG_T
               SET PROCESS_FLAG = 'V',
          	       inventory_item_id = ln_inv_item_id,
				   organization_id = ln_org_id
             WHERE record_id = c_item_rec.record_id;

            COMMIT;
         ELSE
            UPDATE XXAK_INV_MTL_ITEM_STG_T
               SET PROCESS_FLAG = 'E', ERROR_MSG = lv_error_msg
             WHERE record_id = c_item_rec.record_id;

            COMMIT;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_log (
            'Error Occured in validate_data Procedure : ' || SUBSTR (SQLERRM,1, 255));
   END validate_data;

   /****************************************************************************************************************************
   Name        : load_data_interface_table.
   Purpose      : Load Validated data into interface table
   Input Parameters :
					  piv_process_flag   IN   VARCHAR2

   Output Parameters: NA
   ****************************************************************************************************************************/
   PROCEDURE load_data_interface_table (piv_process_flag IN VARCHAR2,piv_process_flag2 IN VARCHAR2)
   IS
      CURSOR c_validate_stg_data (lv_process_flag VARCHAR,lv1_process_process_flag VARCHAR)
      IS
         SELECT *
           FROM XXAK_INV_MTL_ITEM_STG_T
          WHERE PROCESS_FLAG in  (lv_process_flag,lv1_process_process_flag);

      TYPE item_stg_tbl IS TABLE OF XXAK_INV_MTL_ITEM_STG_T%ROWTYPE;

      lt_item_stg_tbl   item_stg_tbl;
      ln_bulk_count NUMBER ;
      ln_transaction_id NUMBER;
	  

   BEGIN
      BEGIN
         gv_step := '21';

         IF gv_debug = 'Y'
         THEN
            write_log ('gv_step : ' || gv_step);
         END IF;
			
			gn_set_process_id := XXAK_ITEM_PROCESS_ID_S.nextval ;

         OPEN c_validate_stg_data(piv_process_flag,piv_process_flag2);

         LOOP
            FETCH c_validate_stg_data
               BULK COLLECT INTO lt_item_stg_tbl
               LIMIT 5000;

            ln_bulk_count := lt_item_stg_tbl.COUNT;

            FOR i IN 1 .. ln_bulk_count
            LOOP
               ln_transaction_id := mtl_system_items_interface_s.NEXTVAL;

INSERT
INTO mtl_system_items_interface
  ( process_flag,
    transaction_type,
    inventory_item_id,
    set_process_id,
    segment1,
    organization_id,
    description,
    long_description,
    primary_uom_code,
    transaction_id,
    last_update_date,
    last_updated_by,
    creation_date,
    created_by,
    last_update_login,
    END_DATE_ACTIVE ,
    INVENTORY_ITEM_STATUS_CODE,
    TEMPLATE_ID ,
    LIST_PRICE_PER_UNIT
  )
  VALUES
  (  1,
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE,'Create', 'CREATE','UPDATE'),
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE,'Create', null,lt_item_stg_tbl (i).inventory_item_id),    
    1,
    lt_item_stg_tbl (i).item_number,
    lt_item_stg_tbl (i).organization_id,
    lt_item_stg_tbl (i).description,
    lt_item_stg_tbl (i).long_description,
    lt_item_stg_tbl (i).primary_uom,    
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE,'Create', null,ln_transaction_id),  --ln_transaction_id,
    lt_item_stg_tbl (i).last_update_date,
    lt_item_stg_tbl (i).last_updated_by,
    lt_item_stg_tbl (i).creation_date,
    lt_item_stg_tbl (i).created_by,
    lt_item_stg_tbl (i).last_update_login,
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE, 'Disable',  sysdate,  NULL),
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE,'Create','Active','Disable','Inactive',null) ,
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE,'Create',259,null),
    DECODE(lt_item_stg_tbl (i).ITEM_UPDATE,'Create',10,null)
  );
             
             
               UPDATE XXAK_INV_MTL_ITEM_STG_T
                  SET int_transaction_id = ln_transaction_id
                WHERE record_id = lt_item_stg_tbl (i).record_id;
            END LOOP;

            EXIT WHEN c_validate_stg_data%NOTFOUND;
         END LOOP;

         CLOSE c_validate_stg_data;

         COMMIT;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_log (
               'Error Occured in load_data_interface_table Procedure : '
            || SUBSTR (SQLERRM, 1, 255));
   END load_data_interface_table;

   /****************************************************************************************************************************
   Name        : submit_item_import.
   Purpose      : Submits the Standard Item Import Program to process the items 
   Input Parameters : NA
   Output Parameters: NA
   ****************************************************************************************************************************/
PROCEDURE submit_item_import(piv_org_name IN VARCHAR2)
IS
cursor c_org_data
IS
SELECT distinct organization_id , DECODE(item_update,'Create',1,2) item_update_code
from XXAK_INV_MTL_ITEM_STG_T
where PROCESS_FLAG = 'V'
and organization_name = piv_org_name;

       lb_program_completed   BOOLEAN;
       ln_req_id              NUMBER;
       lv_rphase              VARCHAR2 (60);
       lv_rstatus             VARCHAR2 (60);
       lv_dphase              VARCHAR2 (60);
       lv_dstatus             VARCHAR2 (60);
       lv_message             VARCHAR2 (240);
	     ln_application_id      NUMBER;
       ln_resp_id        NUMBER;
       ln_user_id             NUMBER;
    

   BEGIN
----------------------------------------------
-- Initializing
----------------------------------------------
  ln_user_id := apps.fnd_profile.value('USER_ID');
  ln_application_id := apps.fnd_profile.value('RESP_APPL_ID');
  ln_resp_id := apps.fnd_profile.value('RESP_ID');

     fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_application_id);

    for C_org_rec in c_org_data
    loop
BEGIN

gv_step := '22';
IF gv_debug = 'Y'
THEN
write_log('gv_step : '|| gv_step);
END IF;

-------------------------------------------------------------
-- Submitting Item Import 
-------------------------------------------------------------

   ln_req_id  :=          fnd_request.submit_request ('INV',                      --application
                                     'INCOIN',          --program  Item Import Short Text
                                     NULL,
                                     --'Item Conversion',  --Description
                                     NULL,                        --Start Time
                                     false,                      --Sub Request
                                     C_org_rec.organization_id,       --Organization_id
                                     2,                    --Current Organization
                                     1,                       --Validate Items
                                     1,                        --Process items
                                     2,                --Delete Processed Rows
                                     null,           --Process Set
                                     c_org_rec.item_update_code  --Create or update items
                                    );
      COMMIT;


    lb_program_completed :=
         fnd_concurrent.wait_for_request (ln_req_id,
                                          60,
                                          99999,
                                          lv_rphase,
                                          lv_rstatus,
                                          lv_dphase,
                                          lv_dstatus,
                                          lv_message
                                         );
      IF NOT ((lv_dphase = 'COMPLETE') AND (lv_dstatus = 'NORMAL'))
      THEN
         write_log ('Item Import failed :' || TO_CHAR (ln_req_id));
		 write_errors(
         piv_program_name         => 'XXAK Item Conversion',
         pin_request_id           => gn_conc_request_id,
         pin_record_sr_no         => NULL,
         pin_batch_id             => NULL,
         piv_key_column_name      => 'Item Import Request ID',
         piv_key_column_value     => TO_CHAR (ln_req_id),
         piv_column_name          => 'submit_item_import',
		 piv_column_value         => SQLCODE,
		 piv_error_message    	  => SQLERRM);
      ELSE
         write_log ('Item Import completed :' || TO_CHAR (ln_req_id));
		 
      END IF;


      COMMIT;

  END;


   END loop;

   EXCEPTION
   WHEN OTHERS
   THEN
   write_log('Error in submit_item_import procedure - '||SQLERRM);
   
		 write_errors(
         piv_program_name         => 'XXAK Item Conversion',
         pin_request_id           => gn_conc_request_id,
         pin_record_sr_no         => NULL,
         pin_batch_id             => NULL,
         piv_key_column_name      => 'submit_item_import',
         piv_key_column_value     => 'Procedure went into Error.',
         piv_column_name          => NULL,
		 piv_column_value         => SQLCODE,
		 piv_error_message    	  => SQLERRM);

END submit_item_import;
   /****************************************************************************************************************************
   Name        : import_item_report.
   Purpose      : Print messages from the procedures into concurent program log file
   Input Parameters : piv_msg
   Output Parameters: NA
   ****************************************************************************************************************************/
  PROCEDURE import_item_report(piv_org IN VARCHAR2)
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   
   


   CURSOR cur_item_err IS
    SELECT msii.segment1,
           mie.message_name,
           mie.error_message,
           msii.transaction_id,
           msii.request_id,
           msii.description,
           msii.transaction_type
    FROM   mtl_interface_errors mie,
           mtl_system_items_interface msii
    WHERE  mie.transaction_id= msii.transaction_id
 AND    mie.table_name = 'MTL_SYSTEM_ITEMS_INTERFACE';

   TYPE item_err_tbl IS TABLE OF cur_item_err%ROWTYPE;
   l_item_err_tbl   item_err_tbl;

      CURSOR cur_item IS
    SELECT msii.item_number,
           msii.int_transaction_id,
           msii.request_id,
           msii.description,
           msii.transaction_type,
           msii.error_msg
    FROM   XXAK_INV_MTL_ITEM_STG_T msii
    WHERE  process_flag = 'E';

   TYPE item_tbl IS TABLE OF cur_item%ROWTYPE;
   l_item_tbl   item_tbl;
	
	cursor c_proc_item IS
	select msii.inventory_item_id,
		   msii.organization_id,
		    msii.request_id
	from mtl_system_items_interface msii
	where process_flag = '7';
	
   ln_bulk_count  NUMBER;
   ln_tot_count NUMBER := 0;
   ln_tot_err_count NUMBER :=0;
   ln_tot_err_val NUMBER :=0;
   ln_tot_err_int NUMBER :=0;
   ln_tot_processed NUMBER :=0;
   
   BEGIN

   gv_step := '23';
IF gv_debug = 'Y'
THEN
write_log('gv_step : '|| gv_step);
END IF;


    write_log('Begin -- import_report');

	
    FND_FILE.put_line (FND_FILE.LOG, ' ');
    FND_FILE.put_line (FND_FILE.LOG, ' ');
    FND_FILE.put_line (FND_FILE.LOG, ' ');
    FND_FILE.put_line (FND_FILE.LOG, 'Following items got Errored Out during Custom Validations on Staging Table');
    FND_FILE.put_line(FND_FILE.LOG, '---------------------------------------------------------------------------------------');
    FND_FILE.put_line(FND_FILE.LOG, 'ITEM NUMBER          ITEM DESCRIPTION    ERROR MESSAGE  ');
    FND_FILE.put_line(FND_FILE.LOG, '---------------------------------------------------------------------------------------');

    OPEN cur_item;
    LOOP
     FETCH cur_item BULK COLLECT INTO l_item_tbl LIMIT 5000;
     ln_bulk_count := l_item_tbl.COUNT;
     FOR indx IN 1..ln_bulk_count LOOP
      FND_FILE.put_line(FND_FILE.LOG, RPAD(l_item_tbl(indx).item_number, 16, ' ') ||'    '||RPAD(l_item_tbl(indx).description, 17, ' ') ||'    '||l_item_tbl(
      indx).error_msg);

     END LOOP;
     EXIT WHEN cur_item%NOTFOUND;
    END LOOP;
    CLOSE cur_item;
    COMMIT;
    FND_FILE.put_line(FND_FILE.LOG,
      '----------------------------------------------------------------------------------------------------------------------------');


    FND_FILE.put_line (FND_FILE.LOG, ' ');
    FND_FILE.put_line (FND_FILE.LOG, ' ');
    FND_FILE.put_line (FND_FILE.LOG, ' ');
    FND_FILE.put_line (FND_FILE.LOG, 'Following items are not processed Successfully by Item Import Program');
    FND_FILE.put_line(FND_FILE.LOG, '---------------------------------------------------------------------------------------');
    FND_FILE.put_line(FND_FILE.LOG, 'ITEM NUMBER             ITEM DESCRIPTION                       TRANSACTION TYPE       ERROR MESSAGE');
    FND_FILE.put_line(FND_FILE.LOG, '---------------------------------------------------------------------------------------');


    OPEN cur_item_err;
    LOOP
     FETCH cur_item_err BULK COLLECT INTO l_item_err_tbl LIMIT 5000;
     ln_bulk_count := l_item_err_tbl.COUNT;
     FOR indx IN 1..ln_bulk_count LOOP
      UPDATE XXAK_INV_MTL_ITEM_STG_T
      SET    process_flag = 'F',
             error_msg    = l_item_err_tbl(indx).message_name||l_item_err_tbl(indx).error_message,
             request_id   = l_item_err_tbl(indx).request_id,
             last_update_date = SYSDATE
      WHERE  int_transaction_id = l_item_err_tbl(indx).transaction_id;
      FND_FILE.put_line(FND_FILE.LOG, RPAD(l_item_err_tbl(indx).segment1, 16, ' ') ||'    '||RPAD(l_item_err_tbl(indx).description, 17, ' ') ||'    '||RPAD(
      l_item_err_tbl(indx).transaction_type,18,' ')||' '||l_item_err_tbl(indx).error_message);
     END LOOP;
     EXIT WHEN cur_item_err%NOTFOUND;
    END LOOP;
    CLOSE cur_item_err;
    COMMIT;

for c_proc_item_rec in c_proc_item
loop 
---------------------------------------------
-- Marking the Records Successfully Processed 
----------------------------------------------
UPDATE XXAK_INV_MTL_ITEM_STG_T
      SET    process_flag = 'P'
	where inventory_item_id = c_proc_item_rec.inventory_item_id
	and organization_id = c_proc_item_rec.organization_id;
	
end loop;	
commit;	


-----------------------------------------------
-- Collecting Statistics for Processed Items 
-----------------------------------------------

select count(*)
into ln_tot_count 
from XXAK_INV_MTL_ITEM_STG_T
where process_flag in ('N','P','E','F')
;

select count(*)
into ln_tot_err_count 
from XXAK_INV_MTL_ITEM_STG_T
where process_flag in ('E','F')
;

select count(*)
into ln_tot_err_val 
from XXAK_INV_MTL_ITEM_STG_T
where process_flag ='E' ;

select count(*)
into ln_tot_err_int 
from XXAK_INV_MTL_ITEM_STG_T
where process_flag ='F' ;

select count(*)
into ln_tot_processed 
from XXAK_INV_MTL_ITEM_STG_T
where process_flag ='P'
;



    FND_FILE.put_line(FND_FILE.LOG, '---------------------------------------------------------------------------------------');	
	FND_FILE.put_line(FND_FILE.LOG, ' 									Item Cleansing Statistics                           ');
	FND_FILE.put_line(FND_FILE.LOG, '																						 ');
	write_log('Total No. of Records : '||ln_tot_count);
	write_log('Total No. of Records Processed Successfully : '||ln_tot_processed);	
	write_log('Total No. of Error Records : '||ln_tot_err_count);
	write_log('Total No. of Records Errored Out During Custom validation : '||ln_tot_err_val);	
	write_log('Total No. of Records Errored Out by Standard Program : '||ln_tot_err_int);
    FND_FILE.put_line(FND_FILE.LOG, '---------------------------------------------------------------------------------------');	
	
    FND_FILE.put_line(FND_FILE.LOG,
      '----------------------------------------------------------------------------------------------------------------------------');


   EXCEPTION
   WHEN OTHERS 
   THEN 
write_errors(
         piv_program_name         => 'XXAK Item Conversion',
         pin_request_id           => gn_conc_request_id,
         pin_record_sr_no         => NULL,
         pin_batch_id             => NULL,
         piv_key_column_name      => NULL,
         piv_key_column_value     => NULL,
         piv_column_name          => 'import_item_report',
		 piv_column_value         => SQLCODE,
		 piv_error_message    	  => SQLERRM);

  END import_item_report;



   /*******************************************************************************************
   *  Name          : main                                                         			  *
   *  Object Type   : Procedure                                                               *
   *  Description   : This procedure is main procedure that calls the different procedures    *
   *                                                                    					  *
   *                                                                                          *
   *******************************************************************************************/
    PROCEDURE main (ERRBUF              OUT VARCHAR2,
                    RETCODE             OUT VARCHAR2,
                    piv_inv_org       IN     VARCHAR2, 
                    piv_debug_mode    IN     VARCHAR2)
IS

lv_process_flag VARCHAR2(10);
lv1_process_process_flag VARCHAR2(10);

BEGIN

-------------------------------------------
-- If the Program is Run in Debuig mode 
-------------------------------------------
IF piv_debug_mode = 'YES'
THEN
gv_debug := 'Y';
END IF;

 ----------------------------
-- Validate Data 
-----------------------------
validate_data;
---------------------------------------
-- Truncate Interface and Error tables
----------------------------------------
truncate_interface_tables;
-----------------------------------------
-- Update Items 
------------------------------------------
load_data_interface_table('V',null);
submit_item_import(piv_inv_org);
-------------------------------
-- Error Reporting
-------------------------------
import_item_report(piv_inv_org);

 
END main;

END XXAK_INV_ITEM_IMPORT_PKG;
/
SHOW ERRORS;
EXIT;