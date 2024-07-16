@EndUserText.label: 'Projection View of ZATS_AK_BOOKING for Approver'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_AK_BOOKING_APPROVER
  as projection on ZATS_AK_BOOKING
{
  key TravelId,
  key BookingId,
      BookingDate,
      CustomerId,
      CarrierId,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LastChangedAt,
      /* Associations */
      _BookingStatus,
      _Carrier,
      _Connection,
      _Customer,
      // Syntax ': redirected to parent' is mandatory to be added if we are calling parent assosiation in child
      _Travel : redirected to parent ZATS_AK_TRAVEL_APPROVER
}
