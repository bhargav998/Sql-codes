CREATE OR REPLACE PACKAGE APPS.XXAK_COMMON_ERR_PKG
AS
   -- This package specification contains following procedure declarations.
   /******************************************************************************
   NAME        :  XXAK_COMMON_ERR_PKG.pks(Specification)

   DESCTIPTION :  This is a package specification. It contains definitions of procedure
               INSERT_ERROR_LOG_PRC


   PARAMETERS    :
   
    NAME           TYPE   DESCRIPTION
    ============   =====  ===============
    p_program_name  IN    Stores the Program Name
    p_request_id    IN    Stores the request_id
    p_record_sr_no  IN    Stores the record serial number
    p_batch_id      IN    Stores batch id
    p_key_column_name   IN    Stores the key column name
    p_key_column_value  IN    Stores the key column value
    p_column_name   IN    Stores the column name
    p_column_value  IN    Stores the column value
    p_error_message IN    Stores the error message
 
--*/ 

   PROCEDURE INSERT_ERROR_LOG_PRC (piv_program_name       IN VARCHAR2,
                                   pin_request_id         IN NUMBER,
                                   pin_record_sr_no       IN NUMBER,
                                   pin_batch_id           IN NUMBER,
                                   piv_key_column_name    IN VARCHAR2,
                                   piv_key_column_value   IN VARCHAR2,
                                   piv_column_name        IN VARCHAR2,
                                   piv_column_value       IN VARCHAR2,
                                   piv_error_message      IN VARCHAR2);
END XXAK_COMMON_ERR_PKG;
