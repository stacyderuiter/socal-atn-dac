%%%%%%%%%
% need to edit to fit conventions and add additional fields...
%%%%%%%%%
% make date-times conform to ISO 8601:2004
ton = datenum(info.dephist_deploy_datetime_start, info.dephist_device_regset);
don = datenum(info.dephist_device_datetime_start, info.dephist_device_regset);
info.dephist_device_regset = 'yyyy-mm-dd HH:MM:SS.FFF';
info.dephist_deploy_datetime_start = datestr(ton, info.dephist_device_regset);
info.dephist_device_datetime_start = datestr(ton, info.dephist_device_regset);

info.date_created = datestr(datetime('now', 'TimeZone', 'UTC'), info.dephist_device_regset);
info.date_issued = info.date_created ;
info.date_modified = info.date_created ;
info.date_metadata_modified = info.date_created ;

% Add SOCAL BRS-specific info to info structure for nc file
% The next few entries will be same for all SOCAL deployments
info.acknowledgement = ;
info.cdm_data_type = 'trajectory';
info.comment = 'DTAG, suction cup attachment';
info.common_name = info.animal_species_common;

info.contributor_name = ;
info.contributor_email = ;
info.contributor_role = ;
info.contributor_role_vocabulary = ; % nerc url

info.conventions = 'CF-1.6,ACDD-1.3,IOOS-1.2';

info.creator_address = ;
info.creator_city = ;
info.creator_country = 'USA';
info.creator_email = ;
info.creator_institution = ;
info.creator_name = ;
info.creator_phone = ;
info.creator_postalcode = ;
info.creator_role = ;
info.creator_sector = ;
info.creator_state = ;
info.creator_type = 'person';
info.creator_url = 'https://www.sea.com/';

info.featureType = 'trajectory';
info.id = 'to be assigned by ATN DAC';
info.infoURL = ;
info.institution = '"SEA, Inc.",Cascadia Research Collective';
info.instrument = info.device_make ;
info.keywords = ;
info.keywords_vocabulary = ;

info.license = ;

info.metadata_link = 'to be determined by ATN DAC';
info.naming_authority = 'gov.noaa.ioos.atn';
info.ncei_template_version = 'NCEI Trajectory template v2.0';
