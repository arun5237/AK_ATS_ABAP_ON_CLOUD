@EndUserText.label: 'Projection View of ZATS_AK_TRAVEL for Approver'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZATS_AK_TRAVEL_APPROVER
  as projection on ZATS_AK_TRAVEL
{
          @ObjectModel.text.element: [ 'Description' ]
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
          // This is done so that booking details data can be displayed in Booking tab in MDE ZATS_AK_TRAVEL_APPROVER_MDE
          _Booking : redirected to composition child ZATS_AK_BOOKING_APPROVER,
          _Currency,
          _Customer,
          _OverallStatus
}
