CLASS zats_ak_mars DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: gt_final TYPE TABLE OF string.
    INTERFACES if_oo_adt_classrun .
    METHODS: process.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZATS_AK_MARS IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    me->process( ).
    out->write(
      EXPORTING
        data   = gt_final
    ).
  ENDMETHOD.


  METHOD process.
    DATA(lo_earth) = NEW zcl_earth( ).
    DATA(lo_planet1) = NEW zcl_planet1( ).
    DATA(lo_mars) = NEW zcl_mars( ).

    APPEND lo_earth->rocket_launch( ) TO gt_final.
    APPEND lo_earth->leave_orbit( ) TO gt_final.

    APPEND lo_planet1->enter_orbit( ) TO gt_final.
    APPEND lo_planet1->leave_orbit( ) TO gt_final.

    APPEND lo_mars->enter_orbit( ) TO gt_final.
    APPEND lo_mars->explore( ) TO gt_final.
  ENDMETHOD.
ENDCLASS.
