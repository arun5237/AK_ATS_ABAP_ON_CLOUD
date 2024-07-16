CLASS lsc_zats_ak_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zats_ak_travel IMPLEMENTATION.

  METHOD save_modified.

    DATA: lt_travel_log_update TYPE STANDARD TABLE OF /dmo/log_travel.
    DATA: lt_FINAL_CHANGES TYPE STANDARD TABLE OF /dmo/log_travel.

    IF update-travel IS NOT INITIAL. "Update is an internal table provided by RAP to check the updated details
      lt_travel_log_update = CORRESPONDING #( update-travel MAPPING travel_id = TravelId ).

      LOOP AT update-travel ASSIGNING FIELD-SYMBOL(<ls_update_travel>).
        ASSIGN lt_travel_log_update[ travel_id = <ls_update_travel>-TravelId ]
          TO FIELD-SYMBOL(<ls_travel_log_db>).

        GET TIME STAMP FIELD <ls_travel_log_db>-created_at.

* %control contains all fields of Travel that are changed. That is, if user changed CustomerId,
*  then %control-CustomerId = '01'(= if_abap_behv=>mk-on ). If its not changed, it will be '00'
        IF <ls_update_travel>-%control-CustomerId = if_abap_behv=>mk-on.
          <ls_travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
          <ls_travel_log_db>-changed_field_name = 'CustomerId'.
          <ls_travel_log_db>-changed_value = <ls_update_travel>-CustomerId.
          <ls_travel_log_db>-changing_operation = 'CHANGE'.
          APPEND <ls_travel_log_db> TO lt_final_changes.
        ENDIF.

        IF <ls_update_travel>-%control-AgencyId = if_abap_behv=>mk-on.
          <ls_travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
          <ls_travel_log_db>-changed_field_name = 'AgencyId'.
          <ls_travel_log_db>-changed_value = <ls_update_travel>-AgencyId.
          <ls_travel_log_db>-changing_operation = 'CHANGE'.
          APPEND <ls_travel_log_db> TO lt_final_changes.
        ENDIF.

      ENDLOOP.

      INSERT /dmo/log_travel FROM TABLE @lt_final_changes.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculatetotalprice.
    METHODS validateheaderdata FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateheaderdata.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE travel.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.

    TYPES: gty_entity_create TYPE TABLE FOR CREATE zats_ak_travel,
           gty_entity_update TYPE TABLE FOR UPDATE zats_ak_travel,
           gty_entity_report TYPE TABLE FOR REPORTED zats_ak_travel,
           gty_entity_fail   TYPE TABLE FOR FAILED zats_ak_travel.

    METHODS reuse_draft_tab_valid
      IMPORTING it_entities_c TYPE gty_entity_create OPTIONAL
                it_entities_u TYPE gty_entity_update OPTIONAL
      EXPORTING
                et_reported   TYPE gty_entity_report
                et_failed     TYPE gty_entity_fail.
ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    DATA: ls_result LIKE LINE OF result.

* 1. Get the data of current instance
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel)
    FAILED DATA(lt_faield).

* 2. Loop travel data
    LOOP AT lt_travel INTO DATA(ls_travel).
* 3. Check is Overall Status is 'Cancelled'  or 'rejected'
      IF ls_travel-OverallStatus = 'X' OR ls_travel-OverallStatus = 'R'.
        DATA(lv_auth) = abap_false.
* 4. Check for authorization in org
* Uncomment below code ince you have authorisation object
*        AUTHORITY-CHECK OBJECT 'CUSTOM_OBJ'
*        ID 'FIELD_NAME' FIELD field1.
*        IF sy-subrc IS INITIAL.
*          lv_auth = abap_true.
*        ENDIF.
      ELSE.
        lv_auth = abap_true.
      ENDIF.

* 5. If no authorization, reject user from Editing the request. That is, disable 'Edit button'
      ls_result = VALUE #( TravelId = ls_travel-TravelId
                            %update = COND #( WHEN lv_auth EQ abap_false "COND is condition, %update indicates whether upd is needed
                            THEN if_abap_behv=>auth-unauthorized
                            ELSE if_abap_behv=>auth-allowed )
                            %action-copyTravel = COND #( WHEN lv_auth EQ abap_false
                            THEN if_abap_behv=>auth-unauthorized
                            ELSE if_abap_behv=>auth-allowed )
                            ).

      APPEND ls_result TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: ls_entity TYPE STRUCTURE FOR CREATE zats_ak_travel.
    DATA: lv_travel_id_max TYPE /dmo/travel_id.

* Step 1: Ensure that IMPORTING TravelId is empty
*   Here, itab 'entities' is already provided by RAP that provides user input during travel request creation.
*    Refer class ZCL_ATS_AK_EML for 'create' as entity is passed
    LOOP AT entities INTO ls_entity WHERE TravelId IS NOT INITIAL.
* MAPPED is the export table that provides the output. It will have entities and its associations.
*    Refer class ZCL_ATS_AK_EML for 'create' syntax 'MAPPED DATA(lt_mapped)'
      APPEND CORRESPONDING #( ls_entity ) TO mapped-travel.
    ENDLOOP.

* To get entities without travel ids
    DATA(lt_entities_wo_travelid) = entities.
    DELETE lt_entities_wo_travelid WHERE TravelId IS NOT INITIAL.

* Step 2: Get the sequence number from SNRO number range
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01' "Get 1 number at a time
            object            = CONV #( '/DMO/TRAVL' )
            quantity          = CONV #( lines( lt_entities_wo_travelid ) ) "The number of entries for which travel id should be created
          IMPORTING
            number            = DATA(lv_num_range_key)
            returncode        = DATA(lv_ret_code)
            returned_quantity = DATA(lv_ret_quantity)
        ).
*    CATCH cx_nr_object_not_found.
*    CATCH cx_number_ranges.
      CATCH cx_number_ranges INTO DATA(lx_num_ranges).
* Step 3: IF there is an exception, throw an error
        LOOP AT lt_entities_wo_travelid INTO ls_entity.
* Specific error messages are passed to 'reported' ex_tab
          APPEND VALUE #( %cid = ls_entity-%cid %key = ls_entity-%key %msg = lx_num_ranges ) TO reported-travel.
          APPEND VALUE #( %cid = ls_entity-%cid %key = ls_entity-%key ) TO failed-travel.
        ENDLOOP.
        EXIT. "Terminate program
    ENDTRY.

    CASE lv_ret_code.
      WHEN '1'.
* Step 4: Handle special cases where the number range exceeded critical %
        LOOP AT lt_entities_wo_travelid INTO ls_entity.
          APPEND VALUE #( %cid = ls_entity-%cid %key = ls_entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
            textid                = /dmo/cm_flight_messages=>number_range_depleted
            severity              = if_abap_behv_message=>severity-warning
          ) ) TO reported-travel.
        ENDLOOP.
      WHEN '2' OR '3'.
* Step 5: The number range returned the last available number or exhausted
*        LOOP AT lt_entities_wo_travelid INTO ls_entity.
        APPEND VALUE #( %cid = ls_entity-%cid %key = ls_entity-%key
                        %msg = NEW /dmo/cm_flight_messages(
          textid                = /dmo/cm_flight_messages=>not_sufficient_numbers
          severity              = if_abap_behv_message=>severity-warning
        ) ) TO reported-travel.
        APPEND VALUE #( %cid = ls_entity-%cid %key = ls_entity-%key
                        %fail-cause = if_abap_behv=>cause-conflict ) TO failed-travel.
*        ENDLOOP.
    ENDCASE.

* Step 6: Final check for all the numbers

* ASSERT is a command that asserts that a given condition is true.
*  If it is, all fine, nothing happens. But if it doesn’t… we have a DUMP.
    ASSERT lv_ret_quantity = lines( lt_entities_wo_travelid ).

* Step 7: Loop incoming travel data and assign the numbers from number range
*           and also return MAPPED table with data which will then go back to RAP framework

    lv_travel_id_max = lv_num_range_key - lv_ret_quantity.
    LOOP AT lt_entities_wo_travelid INTO ls_entity.
      lv_travel_id_max += 1.
      ls_entity-TravelId = lv_travel_id_max.

      APPEND VALUE #( %cid = ls_entity-%cid %key = ls_entity-%key
                      %is_draft = ls_entity-%is_draft ) TO mapped-travel.
      " %is_draft is to be added only if we are enabling DRAFT saving feature
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.
    " This methos is used to ensure that Booking number also follows number range

    DATA: lv_max_booking_id TYPE /dmo/booking_id.

* Step 1: Get all the travel requests and their booking data
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE "Local mode means no authorization
    ENTITY Travel BY \_Booking
    FROM CORRESPONDING #( entities )
    LINK DATA(lt_bookings).

    " Loop through unique TravelIds
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_travel_group>) GROUP BY <ls_travel_group>-TravelId.
* Step 2: Get the highest booking number that is already there from incoming
      "  There will already be a booking number only if update action is performed in the UI
      LOOP AT lt_bookings INTO DATA(ls_booking)
        WHERE source-TravelId = <ls_travel_group>-TravelId.
        IF lv_max_booking_id < ls_booking-target-BookingId.
          lv_max_booking_id = ls_booking-target-BookingId. "This is to get max booking id
        ENDIF.
      ENDLOOP.

* Step 3: Get the assigned booking numbers for incoming request
      LOOP AT entities INTO DATA(ls_entity)
        WHERE TravelId = <ls_travel_group>-TravelId.
        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF lv_max_booking_id < ls_target-BookingId.
            lv_max_booking_id = ls_target-BookingId. "This is to get max booking id
          ENDIF.
        ENDLOOP.
      ENDLOOP.

* Step 4: Loop over all the entities of travel with same travel id
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_travel>)
              WHERE TravelId = <ls_travel_group>-TravelId.
* Step 5: Assign new booking ids to the booking id inside each travel
        LOOP AT <ls_travel>-%target ASSIGNING FIELD-SYMBOL(<ls_booking_wo_number>).
          APPEND CORRESPONDING #( <ls_booking_wo_number> ) TO mapped-booking
          ASSIGNING FIELD-SYMBOL(<ls_mapped_booking>).
          IF <ls_mapped_booking>-BookingId IS INITIAL.
            lv_max_booking_id += 10.
            <ls_mapped_booking>-BookingId = lv_max_booking_id.
            <ls_mapped_booking>-%is_draft = <ls_booking_wo_number>-%is_draft.
            " %is_draft is to be added only if we are enabling DRAFT saving feature
          ENDIF.
        ENDLOOP.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD copyTravel.
    DATA: lt_travel TYPE TABLE FOR CREATE zats_ak_travel\\Travel.
    DATA: lt_booking TYPE TABLE FOR CREATE zats_ak_travel\\Travel\_Booking.
    DATA: lt_booksupp TYPE TABLE FOR CREATE zats_ak_travel\\Booking\_BookingSupplement.

* Step 1: Remove incoming travel instances that has empty %CID
    READ TABLE keys WITH KEY %cid = '' INTO DATA(lv_key_with_empty_cid).
    ASSERT lv_key_with_empty_cid IS INITIAL. "If this is statement is false, system will dump.

* Step 2: Read all travel, booking and booking supplement using EML
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys ) "Reads travel data based on keys
    RESULT DATA(lt_travel_read_result)
    FAILED DATA(lt_failed).

    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( lt_travel_read_result )"Reads booking data based on travel data
    RESULT DATA(lt_booking_read_result)
    FAILED lt_failed.

    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Booking BY \_BookingSupplement
    ALL FIELDS WITH CORRESPONDING #( lt_booking_read_result )"Reads booksuppl data based on booking data
    RESULT DATA(lt_booksuppl_read_result)
    FAILED lt_failed.

* Step 3: Fill itab for travel data creation - based on %cid
    LOOP AT lt_travel_read_result ASSIGNING FIELD-SYMBOL(<ls_travel>).
      APPEND VALUE #( %cid = keys[ %tky = <ls_travel>-%tky ]-%cid "KEY entity is only added to avoid compiler warning
      %data = CORRESPONDING #( <ls_travel> EXCEPT TravelId ) )
       TO lt_travel ASSIGNING FIELD-SYMBOL(<ls_new_travel>).

      <ls_new_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
      <ls_new_travel>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
      <ls_new_travel>-OverallStatus = 'O'.

* Step 4: Fill itab for booking data creation - based on %cid_ref = travel's %cid
      APPEND VALUE #( %cid_ref = keys[ %tky = <ls_travel>-%tky ]-%cid ) "KEY entity is only added to avoid compiler warning
      TO lt_booking ASSIGNING FIELD-SYMBOL(<ls_cba_booking>).

      LOOP AT lt_booking_read_result ASSIGNING FIELD-SYMBOL(<ls_booking_read>) WHERE TravelId = <ls_travel>-TravelId.
        APPEND VALUE #( %cid = keys[ %tky = <ls_travel>-%tky ]-%cid && <ls_booking_read>-BookingId "KEY entity is only added to avoid compiler warning
                        %data = CORRESPONDING #( lt_booking_read_result[ %tky = <ls_booking_read>-%tky ] EXCEPT TravelId ) )
        TO <ls_cba_booking>-%target ASSIGNING FIELD-SYMBOL(<ls_new_booking>).
        <ls_new_booking>-BookingStatus = 'N'.


* Step 5: Fill itab for booking supplement data creation
        APPEND VALUE #( %cid_ref = keys[ %tky = <ls_travel>-%tky ]-%cid && <ls_booking_read>-BookingId )  "KEY entity is only added to avoid compiler warning
        TO lt_booksupp ASSIGNING FIELD-SYMBOL(<ls_cba_booksupp>).

        LOOP AT lt_booksuppl_read_result ASSIGNING FIELD-SYMBOL(<ls_booksupp_read>)
          WHERE TravelId = <ls_travel>-TravelId AND BookingId = <ls_booking_read>-BookingId.
          APPEND VALUE #( %cid = keys[ %tky = <ls_travel>-%tky ]-%cid && <ls_booking_read>-BookingId
                                        && <ls_booksupp_read>-BookingSupplementId "KEY entity is only added to avoid compiler warning
                        %data = CORRESPONDING #( <ls_booksupp_read> EXCEPT TravelId BookingId ) )
        TO <ls_cba_booksupp>-%target.

        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

* Step 6: Modify Entity EML to create new instance using above data
    MODIFY ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode  )
    WITH lt_travel
    CREATE BY \_Booking FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId BookingStatus )
    WITH lt_booking
    ENTITY Booking
    CREATE BY \_BookingSupplement FIELDS ( BookingSupplementId SupplementId Price CurrencyCode LastChangedAt )
    WITH lt_booksupp
    MAPPED DATA(lt_mapped_create).

    mapped-travel = lt_mapped_create-travel.

  ENDMETHOD.

  METHOD get_instance_features.

* Step 1: Read Travel data with status
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_status)
    FAILED DATA(lt_travel_failed).

* Step 2: Return result with booking creation possible or not
    READ TABLE lt_travel_status INTO DATA(ls_travel_status) INDEX 1.
    IF ( ls_travel_status-OverallStatus = 'X' ). "Indicates that Travel request is rejected
      DATA(lv_allow) = if_abap_behv=>fc-o-disabled.
    ELSE.
      lv_allow = if_abap_behv=>fc-o-enabled.
    ENDIF.

* Here, %action indicates whether Accept Travel & Reject Travel buttons are either
*  enabled or not based on Overall status(dynamic feature control)
    result = VALUE #( FOR travel IN lt_travel_status
    ( %tky = travel-%tky
      %action-acceptTravel = COND #( WHEN ls_travel_status-OverallStatus = 'A'
                                     THEN if_abap_behv=>fc-o-disabled
                                     ELSE if_abap_behv=>fc-o-enabled )
      %action-rejectTravel = COND #( WHEN ls_travel_status-OverallStatus = 'X'
                                     THEN if_abap_behv=>fc-o-disabled
                                     ELSE if_abap_behv=>fc-o-enabled )
      %assoc-_Booking = lv_allow ) ).
  ENDMETHOD.

  METHOD reCalcTotalPrice.
*1.  Define a structure where we can store all the booking fees and currency code
    TYPES: BEGIN OF ty_amount_per_curr,
             amount   TYPE /dmo/total_price,
             currency TYPE /dmo/currency_code,
           END OF ty_amount_per_curr.
    DATA: lt_amount_per_curr TYPE STANDARD TABLE OF ty_amount_per_curr.

*2.  Read all travel instances, subsequent bookings using EML
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BookingFee CurrencyCode ) " bcz we need only BookingFee & CurrencyCode to calculate total price
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel BY \_Booking " \_ This is how composition data is read
    FIELDS ( FlightPrice CurrencyCode )
    WITH CORRESPONDING #( lt_travel ) "We need to read Booking only based on LT_TRAVEL
    RESULT DATA(lt_booking).

    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Booking BY \_BookingSupplement " \_ This is how composition data is read
    FIELDS ( Price CurrencyCode )
    WITH CORRESPONDING #( lt_booking ) "We need to read BookingSupp only based on LT_booking
    RESULT DATA(lt_booksupp).

*3.  Delete the values w/o any currency
    DELETE lt_travel WHERE CurrencyCode IS INITIAL.
    DELETE lt_booking WHERE CurrencyCode IS INITIAL.
    DELETE lt_booksupp WHERE CurrencyCode IS INITIAL.

*4.  Total all booking and supplement amounts which are in common currency
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      "Set the first value for total price by adding the 'Booking Fee' from Travel Header.
      lt_amount_per_curr = VALUE #( ( amount = <ls_travel>-BookingFee currency = <ls_travel>-CurrencyCode ) ) .

*5.  Loop at all amounts and compare with target currency
      LOOP AT lt_booking INTO DATA(ls_booking) WHERE TravelId = <ls_travel>-TravelId.
        COLLECT VALUE ty_amount_per_curr( amount = ls_booking-FlightPrice currency = ls_booking-CurrencyCode )
        INTO lt_amount_per_curr.
      ENDLOOP.

      LOOP AT lt_booksupp INTO DATA(ls_booksupp) WHERE TravelId = <ls_travel>-TravelId.
        COLLECT VALUE ty_amount_per_curr( amount = ls_booksupp-Price currency = ls_booksupp-CurrencyCode )
        INTO lt_amount_per_curr.
      ENDLOOP.

      CLEAR <ls_travel>-TotalPrice.

*6.  Perform currency conversion
      LOOP AT lt_amount_per_curr INTO DATA(ls_amount_per_curr).

        IF ls_amount_per_curr-currency = <ls_travel>-CurrencyCode.
          <ls_travel>-TotalPrice += ls_amount_per_curr-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING
              iv_amount               = ls_amount_per_curr-amount
              iv_currency_code_source = ls_amount_per_curr-currency
              iv_currency_code_target = <ls_travel>-CurrencyCode
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
            IMPORTING
              ev_amount               = DATA(lv_conv_amt)
          ).
          <ls_travel>-TotalPrice += lv_conv_amt.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

*7.  Return the total amount in mapped so the RAP will modify this data to DB
    MODIFY ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #( lt_travel ).

  ENDMETHOD.

  METHOD calculateTotalPrice.
* Here we are calling internal action's method reCalcTotalPrice

    MODIFY ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    EXECUTE reCalcTotalPrice "This is how we call internal action's method reCalcTotalPrice
    FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateHeaderData.

* 1. Read TRAVEL data
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

* 2. Declare sorted ITAB to hold customer ids
    DATA: lt_customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

* 3. Extract unique customer ids into LT_CUSTOMERS
    lt_customers = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).
    DELETE lt_customers WHERE customer_id IS INITIAL.

* 4. Validate in bound customers with customer id from DB
    IF NOT lt_customers IS INITIAL.
      SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @lt_customers
      WHERE customer_id = @lt_customers-customer_id
      INTO TABLE @DATA(lt_cust_db).
    ENDIF.

* 5. Compare LT_TRAVEL with LT_CUST_DB and eliminate the remaining
    LOOP AT lt_travel INTO DATA(ls_travel).
      IF ( ls_travel-CustomerId IS INITIAL OR NOT line_exists( lt_cust_db[ customer_id = ls_travel-CustomerId ] ) ).
* 6. Inform RAP to terminate Create operation
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky %element-customerid = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
          textid                = /dmo/cm_flight_messages=>customer_unkown
          customer_id           = ls_travel-CustomerId
          severity              = if_abap_behv_message=>severity-error
        )  ) TO reported-travel.
      ENDIF.
* 7. Validate dates
*      IF ls_travel-BeginDate IS INITIAL.
*        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
*        APPEND VALUE #( %tky = ls_travel-%tky %element-BeginDate = if_abap_behv=>mk-on
*                        %msg = NEW /dmo/cm_flight_messages(
*          textid                = /dmo/cm_flight_messages=>enter_begin_date
*          begin_date           = ls_travel-BeginDate
*          severity              = if_abap_behv_message=>severity-error
*        )  ) TO reported-travel.
*      ENDIF.
*
*      IF ls_travel-EndDate IS INITIAL.
*        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
*        APPEND VALUE #( %tky = ls_travel-%tky %element-EndDate = if_abap_behv=>mk-on
*                        %msg = NEW /dmo/cm_flight_messages(
*          textid                = /dmo/cm_flight_messages=>enter_end_date
*          end_date           = ls_travel-EndDate
*          severity              = if_abap_behv_message=>severity-error
*        )  ) TO reported-travel.
*      ENDIF.
*
*      IF ls_travel-EndDate < ls_travel-BeginDate.
*        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
*        APPEND VALUE #( %tky = ls_travel-%tky %element-EndDate = if_abap_behv=>mk-on
*                        %msg = NEW /dmo/cm_flight_messages(
*          textid                = /dmo/cm_flight_messages=>begin_date_bef_end_date
*          begin_date         = ls_travel-BeginDate
*          end_date           = ls_travel-EndDate
*          severity              = if_abap_behv_message=>severity-error
*        )  ) TO reported-travel.
*      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD precheck_create.

    reuse_draft_tab_valid(
      EXPORTING
        it_entities_c = entities
*      it_entities_u =
      IMPORTING
        et_reported   = reported-travel
        et_failed     = failed-travel
    ).

  ENDMETHOD.

  METHOD precheck_update.

    reuse_draft_tab_valid(
      EXPORTING
*      it_entities_c =
        it_entities_u = entities
      IMPORTING
        et_reported   = reported-travel
        et_failed     = failed-travel
    ).

  ENDMETHOD.

  METHOD reuse_draft_tab_valid.

    DATA: lt_entities TYPE gty_entity_update.
    DATA: lv_operation TYPE if_abap_behv=>t_char01.
    DATA: lt_agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.
    DATA: lt_customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

* Step 1: Check whether Creation or Updation is passed
    ASSERT NOT ( it_entities_c IS INITIAL EQUIV it_entities_u IS INITIAL ).

* Step 2: Perform validation only if agency OR customer was changed
    IF it_entities_c IS NOT INITIAL.
      lt_entities = CORRESPONDING #( it_entities_c ).
      lv_operation = if_abap_behv=>op-m-create.
    ELSE.
      lt_entities = CORRESPONDING #( it_entities_u ).
      lv_operation = if_abap_behv=>op-m-update.
    ENDIF.

    " Delete records where Agency Id is not changed or customer id is not changed
    DELETE lt_entities WHERE %control-AgencyId = if_abap_behv=>mk-off
      AND %control-CustomerId = if_abap_behv=>mk-off.

* Step 3: Get all unique Agency Ids and Customer Ids in a table
    lt_agencies = CORRESPONDING #( lt_entities DISCARDING DUPLICATES MAPPING agency_id = AgencyId EXCEPT * ).
    lt_customers = CORRESPONDING #( lt_entities DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

* Step 4: Get all valid Agency Id and Customer Id from DB
    SELECT FROM /dmo/agency FIELDS agency_id, country_code
    FOR ALL ENTRIES IN @lt_agencies WHERE agency_id = @lt_agencies-agency_id
    INTO TABLE @DATA(lt_agency_cc).

    SELECT FROM /dmo/customer FIELDS customer_id, country_code
    FOR ALL ENTRIES IN @lt_customers WHERE customer_id = @lt_customers-customer_id
    INTO TABLE @DATA(lt_CUSTOMER_cc).

* Step 5: Loop at incoming data and compare Agency and Customer against DB data
    LOOP AT lt_entities INTO DATA(ls_entity).
      READ TABLE lt_agency_cc WITH KEY agency_id = ls_entity-AgencyId INTO DATA(ls_agency).
      CHECK sy-subrc = 0.
      READ TABLE lt_CUSTOMER_cc WITH KEY customer_id = ls_entity-CustomerId INTO DATA(ls_customer).
      CHECK sy-subrc = 0.
      IF ls_agency-country_code NE ls_customer-country_code.
* Step 6: Raise an error if country doesn't match
        APPEND VALUE #( %cid = COND #( WHEN lv_operation = if_abap_behv=>op-m-create THEN ls_entity-%cid_ref )
                        %is_draft = ls_entity-%is_draft
                        %fail-cause = if_abap_behv=>cause-conflict
         ) TO et_failed.

        APPEND VALUE #( %cid = COND #( WHEN lv_operation = if_abap_behv=>op-m-create THEN ls_entity-%cid_ref )
                        %is_draft = ls_entity-%is_draft
                        %msg = NEW /dmo/cm_flight_messages(
                                      textid = VALUE #( msgid = 'SY'
                                                        msgno = 499
                                                        attr1 = 'The country code for Agency and Customer is not matching' )
                                      agency_id = ls_entity-AgencyId
                                      customer_id = ls_entity-CustomerId
                                      severity = if_abap_behv_message=>severity-error
                                      )
                        %element-agencyid = if_abap_behv=>mk-on
        ) TO et_reported.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD acceptTravel.

* Perform the change of BO instance to change status ( this modifies data in db )
    MODIFY ENTITIES OF zats_ak_travel
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky
                                   %is_draft = ls_key-%is_draft
                                   OverallStatus = 'A' ) ).

* Read the BO instance we want to modify (read the modified data from above step )
    READ ENTITIES OF zats_ak_travel
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_results).

* Map the data to RESULT as user can view changes in UI
    result = VALUE #( FOR ls_travel IN lt_results ( %tky = ls_travel-%tky
                                                 %param = ls_travel ) ).

  ENDMETHOD.

  METHOD rejectTravel.

* Perform the change of BO instance to change status ( this modifies data in db )
    MODIFY ENTITIES OF zats_ak_travel
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky
                                   %is_draft = ls_key-%is_draft
                                   OverallStatus = 'X' ) ).

* Read the BO instance we want to modify (read the modified data from above step )
    READ ENTITIES OF zats_ak_travel
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_results).

* Map the data to RESULT as user can view changes in UI
    result = VALUE #( FOR ls_travel IN lt_results ( %tky = ls_travel-%tky
                                                 %param = ls_travel ) ).

  ENDMETHOD.

ENDCLASS.
