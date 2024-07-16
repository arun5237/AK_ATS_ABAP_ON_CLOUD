@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attchment View on top of ZATS_AK_ATTACH'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZATS_AK_ATTACHMENT
  as select from zats_ak_attach
  // Composition view - to specify parent and also join condition
  association to parent ZATS_AK_TRAVEL as _Travel on $projection.TravelId = _Travel.TravelId
{
  key travel_id             as TravelId,
      @EndUserText.label: 'Attachment ID'
  key id                    as Id,
      @EndUserText.label: 'Comments'
      memo                  as Memo,
      // We need to specify the field from the view that holds file type and file name
      //    as the values for mimeType and fileName. This annotation indicates that the
      //    field 'Attachment' is going to store large attahment fiels like pdf
      @Semantics.largeObject: {
      mimeType: 'Filetype',
      fileName: 'Filename',
      contentDispositionPreference: #INLINE
      }
      @EndUserText.label: 'Attachment'
      attachment            as Attachment,
      @EndUserText.label: 'File Name'
      filename              as Filename,
      @Semantics.mimeType: true
      @EndUserText.label: 'File Type'
      filetype              as Filetype,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Travel
}
