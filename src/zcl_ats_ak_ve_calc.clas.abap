CLASS zcl_ats_ak_ve_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

*    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ats_ak_ve_calc IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.

    DATA: lt_calc_Data TYPE STANDARD TABLE OF zats_ak_travel_processor WITH DEFAULT KEY.
    DATA: lv_rate TYPE p DECIMALS 2 VALUE '0.025'.

    CHECK NOT it_original_data IS INITIAL.

    lt_calc_Data = CORRESPONDING #( it_original_data ).

    LOOP AT lt_calc_Data ASSIGNING FIELD-SYMBOL(<ls_calc_data>).
      <ls_calc_data>-CO2Tax = <ls_calc_data>-TotalPrice * lv_rate.
      cl_scal_utils=>date_compute_day(
        EXPORTING
          iv_date           = <ls_calc_data>-BeginDate
        IMPORTING
*          ev_weekday_number =
          ev_weekday_name   = DATA(lv_day_name)
      ).

      <ls_calc_data>-dayOfFlight = lv_day_name. "Try to find a function or method and pass the result
    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_calc_Data ).

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
  ENDMETHOD.
ENDCLASS.
