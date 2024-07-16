@EndUserText.label: 'Projection View of ZATS_AK_ATTACHMENT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_AK_ATTACH_PROCESSOR
  as projection on ZATS_AK_ATTACHMENT
{
  key TravelId,
  key Id,
      Memo,
      Attachment,
      Filename,
      Filetype,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      // Syntax ': redirected to parent' is mandatory to be added if we are calling parent assosiation in child
      _Travel : redirected to parent ZATS_AK_TRAVEL_PROCESSOR
}
