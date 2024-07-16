CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsupplement.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    " This method is used to ensure that BookingSuppliment number also follows number range

    DATA: lv_max_booksupp_id TYPE /dmo/booking_supplement_id.

* Step 1: Get all the booking requests and their booksuppl data
    READ ENTITIES OF zats_ak_travel IN LOCAL MODE "Local mode means no authorization
    ENTITY Booking BY \_BookingSupplement
    FROM CORRESPONDING #( entities )
    LINK DATA(lt_booksupp).

    " Loop through unique BookingIds
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_booking_group>) GROUP BY <ls_booking_group>-BookingId.
* Step 2: Get the highest booksuppl number that is already there from incoming
      "  There will already be a booksuppl number only if update action is performed in the UI
      LOOP AT lt_booksupp INTO DATA(ls_booksupp) USING KEY entity
        WHERE source-TravelId = <ls_booking_group>-TravelId AND source-BookingId = <ls_booking_group>-BookingId.
        IF lv_max_booksupp_id < ls_booksupp-target-BookingSupplementId.
          lv_max_booksupp_id = ls_booksupp-target-BookingSupplementId. "This is to get max booksuppl id
        ENDIF.
      ENDLOOP.

* Step 3: Get the assigned booksuppl numbers for incoming request
      LOOP AT entities INTO DATA(ls_entity) USING KEY entity
        WHERE TravelId = <ls_booking_group>-TravelId AND BookingId = <ls_booking_group>-BookingId.
        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF lv_max_booksupp_id < ls_target-BookingSupplementId.
            lv_max_booksupp_id = ls_target-BookingSupplementId. "This is to get max booksuppl id
          ENDIF.
        ENDLOOP.
      ENDLOOP.

* Step 4: Loop over all the entities of booking with same booking id
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_travel>) USING KEY entity
              WHERE TravelId = <ls_booking_group>-TravelId AND BookingId = <ls_booking_group>-BookingId.
* Step 5: Assign new booking ids to the booking id inside each travel
        LOOP AT <ls_travel>-%target ASSIGNING FIELD-SYMBOL(<ls_booksuppl_wo_number>).
          APPEND CORRESPONDING #( <ls_booksuppl_wo_number> ) TO mapped-booksuppl
          ASSIGNING FIELD-SYMBOL(<ls_mapped_booksuppl>).
          IF <ls_mapped_booksuppl>-BookingSupplementId IS INITIAL.
            lv_max_booksupp_id += 1.
            <ls_mapped_booksuppl>-BookingSupplementId = lv_max_booksupp_id.
            <ls_mapped_booksuppl>-%is_draft = <ls_booksuppl_wo_number>-%is_draft.
            " %is_draft is to be added only if we are enabling DRAFT saving feature
          ENDIF.
        ENDLOOP.
      ENDLOOP.

    ENDLOOP.


  ENDMETHOD.

  METHOD calculateTotalPrice.
    DATA: lt_travel_ids TYPE STANDARD TABLE OF zats_ak_travel_processor WITH UNIQUE HASHED KEY key COMPONENTS travelid.

* Get unique travel ids from incoming data
    lt_travel_ids = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING travelid = TravelId ).

    MODIFY ENTITIES OF zats_ak_travel IN LOCAL MODE
    ENTITY Travel
    EXECUTE reCalcTotalPrice "We are calling method reCalcTotalPrice in class ZBP_ATS_AK_TRAVEL
    FROM CORRESPONDING #( lt_travel_ids ).

  ENDMETHOD.

ENDCLASS.
