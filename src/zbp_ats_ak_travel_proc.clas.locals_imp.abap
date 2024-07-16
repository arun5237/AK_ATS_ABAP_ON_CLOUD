CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD augment_create.

    DATA: lt_travel_create TYPE TABLE FOR CREATE zats_ak_travel.

    lt_travel_create = CORRESPONDING #( entities ).

    LOOP AT lt_travel_create ASSIGNING FIELD-SYMBOL(<ls_travel_create>).
      <ls_travel_create>-AgencyId = '070003'. "Defaulting AgencyId to 70003 during creation
      <ls_travel_create>-OverallStatus = 'O'. "Defaulting OverallStatus to Open during creation

* Now we need to specify control structure that we have changed AgencyId and OverallStatus
      <ls_travel_create>-%control-AgencyId = if_abap_behv=>mk-on.
      <ls_travel_create>-%control-OverallStatus = if_abap_behv=>mk-on.
    ENDLOOP.

    MODIFY AUGMENTING ENTITIES OF zats_ak_travel
    ENTITY Travel
    CREATE FROM lt_travel_create.

  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

ENDCLASS.
