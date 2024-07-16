CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    TYPES: tt_travel_failed   TYPE TABLE FOR FAILED zats_ak_um_travel,
           tt_travel_reported TYPE TABLE FOR REPORTED zats_ak_um_travel. "++ Custom types added

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Travel.

    METHODS read FOR READ
      IMPORTING keys FOR READ Travel RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Travel.

    METHODS set_booked_status FOR MODIFY
      IMPORTING keys FOR ACTION Travel~set_booked_status RESULT result.

* Custom method which will capture messages from old legacy code and convert it
*  into a format that RAP understands
    METHODS map_messages
      IMPORTING
        iv_cid          TYPE string OPTIONAL
        iv_travel_id    TYPE /dmo/travel_id OPTIONAL
        it_messages     TYPE /dmo/t_message
      EXPORTING
        ev_failed_added TYPE abap_bool
      CHANGING
        ct_failed       TYPE tt_travel_failed
        ct_reported     TYPE tt_travel_reported.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

* Step 1: Data declaration
    DATA: lt_messages TYPE /dmo/t_message.
    DATA: ls_travel_in TYPE /dmo/travel.
    DATA: ls_travel_out TYPE /dmo/travel.

* Loop the incoming data from Fiori app/EML
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_travel_create>).
* Step 2: Get the incoming data in a structure that our legacy code can understand
*  Using CONTROL indicates that we are capturing only the fields that are changed in UI screen
      ls_travel_in = CORRESPONDING #( <ls_travel_create> MAPPING FROM ENTITY USING CONTROL ).

* Step 3: Call the legacy code(old code) to set data into transaction buffer
*  In real case, you can call your BAPI that creates items/ invoices etc.
      /dmo/cl_flight_legacy=>get_instance(  )->create_travel(
        EXPORTING
          is_travel             = CORRESPONDING /dmo/s_travel_in( ls_travel_in )
        IMPORTING
          es_travel             = ls_travel_out
          et_messages           = DATA(lt_create_messages)
      ).

* Step 4: Handle the incoming messages
      /dmo/cl_flight_legacy=>get_instance(  )->convert_messages(
        EXPORTING
          it_messages = lt_create_messages
        IMPORTING
          et_messages = lt_messages
      ).

* Step 5: Map the messages to the RAP output
      me->map_messages(
        EXPORTING
          iv_cid          = <ls_travel_create>-%cid
          iv_travel_id    = <ls_travel_create>-TravelId
          it_messages     = lt_messages
        IMPORTING
          ev_failed_added = DATA(lv_data_failed)
        CHANGING
          ct_failed       = failed-travel
          ct_reported     = reported-travel
      ).

      IF lv_data_failed = abap_true.
        INSERT VALUE #( %cid = <ls_travel_create>-%cid
                        travelid = <ls_travel_create>-TravelId
                       ) INTO mapped-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

* Step 1: Data declaration
    DATA: lt_messages TYPE /dmo/t_message.
    DATA: ls_travel_in TYPE /dmo/travel.
    DATA: ls_travel_updt TYPE /dmo/s_travel_inx. "This will give the fields changed in UI

* Loop the incoming data from Fiori app/EML
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_travel_update>).
* Step 2: Get the incoming data in a structure that our legacy code can understand
*  Using CONTROL indicates that we are capturing only the fields that are changed in UI screen
      ls_travel_in = CORRESPONDING #( <ls_travel_update> MAPPING FROM ENTITY USING CONTROL ).
      ls_travel_updt-travel_id = ls_travel_in-travel_id.
      ls_travel_updt-_intx = CORRESPONDING #( <ls_travel_update> MAPPING FROM ENTITY ).

* Step 3: Call the legacy code(old code) to set data into transaction buffer
*  In real case, you can call your BAPI that creates items/ invoices etc.
      /dmo/cl_flight_legacy=>get_instance(  )->update_travel(
        EXPORTING
          is_travel              = CORRESPONDING /dmo/s_travel_in( ls_travel_in )
          is_travelx             = ls_travel_updt
        IMPORTING
          et_messages              = DATA(lt_update_messages)
      ).

* Step 4: Handle the incoming messages
      /dmo/cl_flight_legacy=>get_instance(  )->convert_messages(
        EXPORTING
          it_messages = lt_update_messages
        IMPORTING
          et_messages = lt_messages
      ).

* Step 5: Map the messages to the RAP output
      me->map_messages(
        EXPORTING
          iv_cid          = <ls_travel_update>-%cid_ref
          iv_travel_id    = <ls_travel_update>-TravelId
          it_messages     = lt_messages
        IMPORTING
          ev_failed_added = DATA(lv_data_failed)
        CHANGING
          ct_failed       = failed-travel
          ct_reported     = reported-travel
      ).

    ENDLOOP.

  ENDMETHOD.

  METHOD delete.

    DATA: lt_messages TYPE /dmo/t_message.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_travel_delete>).
      /dmo/cl_flight_legacy=>get_instance(  )->delete_travel(
        EXPORTING
          iv_travel_id = <ls_travel_delete>-TravelId
        IMPORTING
          et_messages  = DATA(lt_delete_messages)
      ).

* Handle the incoming messages
      /dmo/cl_flight_legacy=>get_instance(  )->convert_messages(
        EXPORTING
          it_messages = lt_delete_messages
        IMPORTING
          et_messages = lt_messages
      ).

* Map the messages to the RAP output
      me->map_messages(
        EXPORTING
          iv_cid          = <ls_travel_delete>-%cid_ref
          iv_travel_id    = <ls_travel_delete>-TravelId
          it_messages     = lt_messages
        IMPORTING
          ev_failed_added = DATA(lv_data_failed)
        CHANGING
          ct_failed       = failed-travel
          ct_reported     = reported-travel
      ).

    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    DATA: lt_messages TYPE /dmo/t_message.
    DATA: ls_travel_out TYPE /dmo/travel.
    DATA: lv_failed TYPE abap_boolean.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_travel_read>) GROUP BY <ls_travel_read>-TravelId.

      /dmo/cl_flight_legacy=>get_instance(  )->get_travel(
        EXPORTING
          iv_travel_id           = <ls_travel_read>-TravelId
          iv_include_buffer      = abap_false
        IMPORTING
          es_travel              = ls_travel_out
          et_messages            = DATA(lt_read_messages)
      ).

* Handle the incoming messages
      /dmo/cl_flight_legacy=>get_instance(  )->convert_messages(
        EXPORTING
          it_messages = lt_read_messages
        IMPORTING
          et_messages = lt_messages
      ).

* Map the messages to the RAP output
      me->map_messages(
        EXPORTING
          iv_travel_id    = <ls_travel_read>-TravelId
          it_messages     = lt_messages
        IMPORTING
          ev_failed_added = DATA(lv_data_failed)
        CHANGING
          ct_failed       = failed-travel
          ct_reported     = reported-travel
      ).

      IF lv_data_failed = abap_false.
        INSERT CORRESPONDING #( ls_travel_out MAPPING TO ENTITY ) INTO TABLE result.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD set_booked_status.

* Read all travel instances
    READ ENTITIES OF zats_ak_um_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status ) " bcz we need only Status
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      <ls_travel>-Status = 'A'. "Approved
    ENDLOOP.

* Return the total amount in mapped so the RAP will modify this data to DB
    MODIFY ENTITIES OF zats_ak_um_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Status )
    WITH CORRESPONDING #( lt_travel ).

  ENDMETHOD.

  METHOD map_messages.

    ev_failed_added = abap_false.

    LOOP AT it_messages INTO DATA(ls_message).
      IF ls_message-msgty = 'E' OR ls_message-msgty = 'A'.
        APPEND VALUE #( %cid = iv_cid
                        travelid = iv_travel_id
                        %fail-cause = /dmo/cl_travel_auxiliary=>get_cause_from_message( msgid = ls_message-msgid
                                                                                        msgno = ls_message-msgno
                                                                                        is_dependend = abap_false )
                      ) TO ct_failed.
        ev_failed_added = abap_true.
      ENDIF.

      APPEND VALUE #( %msg = new_message( id = ls_message-msgid
                                          number = ls_message-msgno
                                          v1 = ls_message-msgv1
                                          v2 = ls_message-msgv2
                                          v3 = ls_message-msgv3
                                          v4 = ls_message-msgv4
                                          severity = if_abap_behv_message=>severity-information
                                        )
                       %cid = iv_cid
                       travelid = iv_travel_id
                     ) TO ct_reported.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZATS_AK_UM_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZATS_AK_UM_TRAVEL IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
* This place can be used to Commit Word like calling BAPI_TRANSACTION_COMMIT
    /dmo/cl_flight_legacy=>get_instance(  )->save( ).

  ENDMETHOD.

  METHOD cleanup.

    /dmo/cl_flight_legacy=>get_instance(  )->initialize( ).

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
