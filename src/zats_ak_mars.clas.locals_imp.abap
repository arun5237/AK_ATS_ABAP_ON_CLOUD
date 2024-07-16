*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS zcl_earth DEFINITION.
  PUBLIC SECTION.
    METHODS: rocket_launch RETURNING VALUE(rv_text) TYPE string,
      leave_orbit RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_earth IMPLEMENTATION.

  METHOD rocket_launch.
    rv_text = 'Launched Rocket from Earth'.
  ENDMETHOD.

  METHOD leave_orbit.
    rv_text = 'Left Earth Orbit'.
  ENDMETHOD.

ENDCLASS.

CLASS zcl_planet1 DEFINITION.
  PUBLIC SECTION.
    METHODS: enter_orbit RETURNING VALUE(rv_text) TYPE string,
      leave_orbit RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.
CLASS zcl_planet1 IMPLEMENTATION.
  METHOD enter_orbit.
    rv_text = 'Enter Orbit of Planet 1'.
  ENDMETHOD.

  METHOD leave_orbit.
    rv_text = 'Leave orbit of Planet 1'.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_mars DEFINITION.
  PUBLIC SECTION.
    METHODS: enter_orbit RETURNING VALUE(rv_text) TYPE string,
      explore RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.
CLASS zcl_mars IMPLEMENTATION.
  METHOD enter_orbit.
    rv_text = 'Enter Orbit of Mars'.
  ENDMETHOD.

  METHOD explore.
    rv_text = 'Explore Mars'.
  ENDMETHOD.
ENDCLASS.
