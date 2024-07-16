@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Unmanaged - Customer Master Data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZATS_AK_UM_CUSTOMER
  as select from /dmo/customer
  association [1] to I_Country as _Country on $projection.CountryCode = _Country.Country
{
  key customer_id                                                           as CustomerId,
      first_name                                                            as FirstName,
      last_name                                                             as LastName,
      title                                                                 as Title,
      concat(concat(title, concat(' ', first_name)),concat(' ', last_name)) as CustomerName, //Custom field
      street                                                                as Street,
      postal_code                                                           as PostalCode,
      city                                                                  as City,
      country_code                                                          as CountryCode,
      phone_number                                                          as PhoneNumber,
      email_address                                                         as EmailAddress,
      _Country
}
