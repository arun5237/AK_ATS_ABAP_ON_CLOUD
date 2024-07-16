@EndUserText.label: 'Projection View of ZATS_AK_BOOKING'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_AK_BOOKING_PROCESSOR
  as projection on ZATS_AK_BOOKING
{
  key TravelId,
  key BookingId,
      BookingDate,
      @Consumption.valueHelpDefinition: [{
      entity.name: '/DMO/I_Customer',
      entity.element: 'CustomerID'
       }]
      CustomerId,
      @Consumption.valueHelpDefinition: [{
      entity.name: '/DMO/I_Carrier',
      entity.element: 'AirlineID'
       }]
      CarrierId,
      @Consumption.valueHelpDefinition: [{
      entity.name: '/DMO/I_Connection',
      entity.element: 'ConnectionID',
      additionalBinding: [{  //Here additionalBinding is provided to ensure that only relevant  AirlineIds
      localElement: 'CarrierId', // are displayed based on CarrierId as ConnectionID
      element: 'AirlineID' }] }]
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      @Consumption.valueHelpDefinition: [{
      entity.name: '/DMO/I_Booking_Status_VH',
      entity.element: 'BookingStatus'
       }]
      BookingStatus,
      LastChangedAt,
      /* Associations */
      _BookingStatus,
      _BookingSupplement : redirected to composition child ZATS_AK_BOOKSUPPL_PROCESSOR,
      _Carrier,
      _Connection,
      _Customer,
      // Syntax ': redirected to parent' is mandatory to be added if we are calling parent assosiation in child
      _Travel            : redirected to parent ZATS_AK_TRAVEL_PROCESSOR
}
