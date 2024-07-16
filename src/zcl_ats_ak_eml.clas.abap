CLASS zcl_ats_ak_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: lv_opr TYPE c VALUE 'C'.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ATS_AK_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    CASE lv_opr.
      WHEN 'R'. "Read

*1. Read all fields
        READ ENTITIES OF zats_ak_travel "Specify the root BO here
        ENTITY Travel " We chose Travel here as its given as alias for ZATS_AK_TRAVEL in Behavior Defn ZATS_AK_TRAVEL
        ALL FIELDS WITH
        VALUE #( ( TravelId = '00000010' )
                 ( TravelId = '00000024' )
                 ( TravelId = '00087874' ) "This travel id doesn't exist in DB
                )
        RESULT DATA(lt_result) "inline declaration for result tab
        FAILED DATA(lt_failed)  "inline declaration for failed entries, i.e, TravelId = '00087874'
        REPORTED DATA(lt_messages).
*        Display result data
*        out->write( data = lt_result ).
*        out->write( data = lt_failed ).
*2. Read certain fields
        READ ENTITIES OF zats_ak_travel "Specify the root BO here
        ENTITY Travel " We chose Travel here as its given as alias for ZATS_AK_TRAVEL in Behavior Defn ZATS_AK_TRAVEL
        FIELDS ( TravelId AgencyId TotalPrice CurrencyCode ) WITH
        VALUE #( ( TravelId = '00000010' )
                 ( TravelId = '00000024' )
                 ( TravelId = '00087874' ) "This travel id doesn't exist in DB
                )
        RESULT DATA(lt_result2) "inline declaration for result tab
        FAILED DATA(lt_failed2)  "inline declaration for failed entries, i.e, TravelId = '00087874'
        REPORTED DATA(lt_messages2).
*        Display result data
*        out->write( data = lt_result2 ).
*        out->write( data = lt_failed2 ).

      WHEN 'C'. "Create
        DATA(lv_description) = 'Test Travel Creation through EML'.
        DATA(lv_agency) = '010123'.
        DATA(lv_customer) = '000124'.

        MODIFY ENTITIES OF zats_ak_travel
        ENTITY Travel
        CREATE FIELDS ( TravelId AgencyId CustomerId BeginDate EndDate Description OverallStatus )
        WITH VALUE #(
                     (
                       %CID = 'ARUN_TEST' "This needs to be passed as it holds temp session id. Refer slide 73
                       TravelId = '00007878'
                       AgencyId = lv_agency
                       CustomerId = lv_customer
                       BeginDate = cl_abap_context_info=>get_system_date( )
                       EndDate = cl_abap_context_info=>get_system_date( ) + 30
                       Description = lv_description
                       OverallStatus = 'N'
                       )
                       ( %CID = 'ARUN_TEST2' "This needs to be passed as it holds temp session id. Refer slide 73
                       TravelId = '00007879'
                       AgencyId = lv_agency
                       CustomerId = lv_customer
                       BeginDate = cl_abap_context_info=>get_system_date( )
                       EndDate = cl_abap_context_info=>get_system_date( ) + 30
                       Description = lv_description
                       OverallStatus = 'N'
                       )
                       ( %CID = 'ARUN_TEST3' "This needs to be passed as it holds temp session id. Refer slide 73
                       TravelId = '00007878' "This should fail as 2245 is already created above
                       AgencyId = lv_agency
                       CustomerId = lv_customer
                       BeginDate = cl_abap_context_info=>get_system_date( )
                       EndDate = cl_abap_context_info=>get_system_date( ) + 30
                       Description = lv_description
                       OverallStatus = 'N'
                       )
         )
          MAPPED DATA(lt_mapped)
          FAILED lt_failed
          REPORTED DATA(lt_message).

        COMMIT ENTITIES. "To commit changes

*        Display result data
        out->write( data = lt_mapped ).
        out->write( data = lt_failed ).

      WHEN 'U'. "Update

        lv_description = 'Test Travel Updation through EML'.
        lv_agency = '010123'.

        MODIFY ENTITIES OF zats_ak_travel
        ENTITY Travel
        UPDATE FIELDS ( AgencyId Description )
        WITH VALUE #(
                     ( TravelId = '00000008'
                       AgencyId = lv_agency
                       Description = lv_description
                       )
                       ( TravelId = '00000009'
                       AgencyId = lv_agency
                       Description = lv_description
                       )
         )
          MAPPED lt_mapped
          FAILED lt_failed
          REPORTED lt_message.

        COMMIT ENTITIES. "To commit changes

*        Display result data
        out->write( data = lt_mapped ).
        out->write( data = lt_failed ).

      WHEN 'D'. "Delete

 MODIFY ENTITIES OF zats_ak_travel
        ENTITY Travel
        DELETE FROM
        VALUE #(
                     ( TravelId = '3278' )
         )
          MAPPED lt_mapped
          FAILED lt_failed
          REPORTED lt_message.

        COMMIT ENTITIES. "To commit changes

*        Display result data
        out->write( data = lt_mapped ).
        out->write( data = lt_failed ).

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
