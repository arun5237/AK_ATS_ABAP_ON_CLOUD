@EndUserText.label: 'Projection View of ZATS_AK_BOOKSUPPL'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_AK_BOOKSUPPL_PROCESSOR
  as projection on ZATS_AK_BOOKSUPPL
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      // Syntax ': redirected to parent' is mandatory to be added if we are calling parent assosiation in child
      _Booking : redirected to parent ZATS_AK_BOOKING_PROCESSOR,
      _Product,
      _SupplementText,
      _Travel  : redirected to ZATS_AK_TRAVEL_PROCESSOR
}
