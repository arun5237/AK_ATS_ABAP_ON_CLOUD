@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Unmanaged - Root Travel BO'
@Metadata.allowExtensions: true
define root view entity ZATS_AK_UM_TRAVEL
  as select from /dmo/travel
  //composition of target_data_source_name as _association_name
  association [1] to ZATS_AK_UM_AGENCY       as _Agency       on $projection.AgencyId = _Agency.AgencyId
  association [1] to ZATS_AK_UM_CUSTOMER     as _Customer     on $projection.CustomerId = _Customer.CustomerId
  association [1] to I_Currency              as _Currency     on $projection.CurrencyCode = _Currency.Currency
  association [1] to /DMO/I_Travel_Status_VH as _TravelStatus on $projection.Status = _TravelStatus.TravelStatus
{
      @ObjectModel.text.element: [ 'Memo' ] // This will display 'description' value from Memo field below for travel_id
  key travel_id                                                             as TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZATS_AK_UM_AGENCY', element: 'AgencyId' } }]
      agency_id                                                             as AgencyId,
      _Agency.Name                                                          as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZATS_AK_UM_CUSTOMER', element: 'CustomerId' } }]
      customer_id                                                           as CustomerId,
      _Customer.CustomerName                                                as CustomerName,
      begin_date                                                            as BeginDate,
      end_date                                                              as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee                                                           as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price                                                           as TotalPrice,
      currency_code                                                         as CurrencyCode,
      description                                                           as Memo,
      @ObjectModel.text.element: [ 'TravelStatus' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Travel_Status_VH', element: 'Status' } }]
      status                                                                as Status,
      _TravelStatus._Text[Language = $session.system_language].TravelStatus as TravelStatus,
      createdby                                                             as Createdby,
      createdat                                                             as Createdat,
      lastchangedby                                                         as Lastchangedby,
      lastchangedat                                                         as Lastchangedat,
      _Agency,
      _Customer,
      _Currency,
      _TravelStatus
}
