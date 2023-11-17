CREATE OR REPLACE PACKAGE BODY APPS.XXAK_COMMON_ERR_PKG
AS
   /************************************************************************************/
   /*
   NAME         :  insert_error_log_prc
   DESCRIPTION  :  This procedure is used to update error log table

   PARAMETERS   :
   ==========
   NAME            TYPE   DESCRIPTION
   ==============      ===== =======================
   p_program_name   IN    Stores the Program Name
   p_request_id     IN    Stores the request_id
   p_record_sr_no   IN    Stores the record serial number
   p_batch_id       IN    Stores batch id
   p_key_column_name   IN    Stores the key column name
   p_key_column_value  IN    Stores the key column value
   p_column_name    IN    Stores the column name
   p_column_value   IN    Stores the column value
   p_error_message  IN    Stores the error message

 
   /************************************************************************************/

   PROCEDURE INSERT_ERROR_LOG_PRC (piv_program_name       IN VARCHAR2,
                                   pin_request_id         IN NUMBER,
                                   pin_record_sr_no       IN NUMBER,
                                   pin_batch_id           IN NUMBER,
                                   piv_key_column_name    IN VARCHAR2,
                                   piv_key_column_value   IN VARCHAR2,
                                   piv_column_name        IN VARCHAR2,
                                   piv_column_value       IN VARCHAR2,
                                   piv_error_message      IN VARCHAR2)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   /* ---------------Start of the Begin section for the procedure--------------------------*/


   BEGIN
      INSERT INTO XXAK_COMMON_ERROR_LOG_T (program_name,
                                          request_id,
                                          record_sr_no,
                                          batch_id,
                                          key_column_name,
                                          key_column_value,
                                          column_name,
                                          COLUMN_VALUE,
                                          error_message)
           VALUES (piv_program_name,
                   pin_request_id,
                   pin_record_sr_no,
                   pin_batch_id,
                   piv_column_name,
                   piv_column_value,
                   piv_key_column_name,
                   piv_key_column_value,
                   piv_error_message);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (
            FND_FILE.LOG,
               'Insertion failed int o table global_error_log_t due to'
            || '::'
            || SQLERRM);
         COMMIT;
   END INSERT_ERROR_LOG_PRC;
/********************* End of procedure Insert Error log Prc ************************/

END XXAK_COMMON_ERR_PKG;
/
SHOW ERRORS;
EXIT;