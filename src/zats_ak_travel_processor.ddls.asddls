@EndUserText.label: 'Projection View of ZATS_AK_TRAVEL'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZATS_AK_TRAVEL_PROCESSOR
  as projection on ZATS_AK_TRAVEL
{
          @ObjectModel.text.element: [ 'Description' ]
          //            @Consumption.valueHelpDefinition: [{
          //            entity.name: 'ZATS_AK_TRAVEL',
          //            entity.element: 'TravelId'
          //             }]
  key     TravelId,
          @ObjectModel.text.element: [ 'AgencyName' ]
          @Consumption.valueHelpDefinition: [{ // For VH, get assosiation and alias name of field in /DMO/I_Agency
          entity.name: '/DMO/I_Agency',
          entity.element: 'AgencyID'
           }]
          AgencyId,
          @Semantics.text: true
          _Agency.Name        as AgencyName,
          @ObjectModel.text.element: [ 'CustomerName' ]
          @Consumption.valueHelpDefinition: [{
          entity.name: '/DMO/I_Customer',
          entity.element: 'CustomerID'
           }]
          CustomerId,
          @Semantics.text: true
          _Customer.FirstName as CustomerName,
          BeginDate,
          EndDate,
          BookingFee,
          TotalPrice,
          CurrencyCode,
          @Semantics.text: true
          Description,
          // Below annotation indicates that Statustext field holds the description of OverallStatus
          @ObjectModel.text.element: [ 'StatusText' ]
          @Consumption.valueHelpDefinition: [{
          entity.name: '/DMO/I_Overall_Status_VH',
          entity.element: 'OverallStatus'
           }]
          OverallStatus,
          CreatedBy,
          CreatedAt,
          LastChangedBy,
          LastChangedAt,
          @Semantics.text: true
          StatusText,
          Criticality,
          /* Associations */
          _Agency,
          // This is done so that booking details data can be displayed in Booking tab in MDE ZATS_AK_TRAVEL_PROCESSOR_MDE
          _Booking : redirected to composition child ZATS_AK_BOOKING_PROCESSOR,
          // This is done so that attachment details data can be displayed in Attach tab in MDE ZATS_AK_TRAVEL_PROCESSOR_MDE
          _Attachment : redirected to composition child ZATS_AK_ATTACH_PROCESSOR,
          _Currency,
          _Customer,
          _OverallStatus,
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_AK_VE_CALC' //Indicates the processing class
          @EndUserText.label: 'CO2 Tax'
  virtual CO2Tax      : abap.int4, //Virtual Element declarion. This is calculated virtually and not available in DB
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_AK_VE_CALC' //Indicates the processing class
          @EndUserText.label: 'Flight Day'
  virtual dayOfFlight : abap.char( 9 ) //Virtual Element declarion. This is calculated virtually and not available in DB
}
