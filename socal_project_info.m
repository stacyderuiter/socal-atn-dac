%%%%%%%%%
% need to edit to fit conventions and add additional fields...
%%%%%%%%%
% make date-times conform to ISO 8601:2004
ton = datenum(info.dephist_deploy_datetime_start, info.dephist_device_regset);
don = datenum(info.dephist_device_datetime_start, info.dephist_device_regset);
dmade = datenum(info.dtype_datetime_made, info.dephist_device_regset);
cdate = datenum(info.creation_date, info.dephist_device_regset);
info.dephist_device_regset = 'yyyy-mm-dd HH:MM:SS.FFF'; % for matlab
info.dephist_deploy_datetime_start = datestr(ton, info.dephist_device_regset);
info.dephist_device_datetime_start = datestr(ton, info.dephist_device_regset);
info.deploy_id = info.depid ;
info.dtype_datetime_made = datestr(dmade, info.dephist_device_regset);
info.creation_date = datestr(cdate, info.dephist_device_regset);
info.dephist_device_tzone = 'UTC';
% note the T and Z are not in the date-times (ISO 8601 indicators); 
% matlab can't deal natively with this
% could possibly fix e.g. https://www.mathworks.com/matlabcentral/fileexchange/34095-date-vector-number-to-iso-8601-date-string
% but would break compatibility with some current tagtools

info.date_created = datestr(datetime('now', 'TimeZone', 'UTC'), info.dephist_device_regset);
info.date_issued = info.date_created ;
info.date_modified = info.date_created ;
info.date_metadata_modified = info.date_created ;

% Add SOCAL BRS-specific info to info structure for nc file
% The next few entries will be same for all SOCAL deployments
info.acknowledgement = 'US Navy Office of Naval Research,NOAA National Marine Fisheries Service';
info.cdm_data_type = 'trajectory';
info.comment = 'DTAG, suction cup attachment';
info.common_name = info.animal_species_common;

info.contributor_name = 'Brandon Southall';
info.contributor_email = 'brandon.southall@sea-inc.net';
info.contributor_role = 'principalInvestigator';
info.contributor_role_vocabulary = 'https://vocab.nerc.ac.uk/collection/G04/current/'; % nerc url

info.conventions = 'CF-1.6,ACDD-1.3,IOOS-1.2';

info.creator_address = '9099 Soquel Drive, Suite 8';
info.creator_city = 'Aptos';
info.creator_country = 'USA';
info.creator_email = 'rosscnichols@gmail.com';
info.creator_institution = 'Southall Environmental Associates, Inc.';
info.creator_name = 'Ross Nichols';
info.creator_phone = '831 601 1437';
info.creator_postalcode = '95003';
info.creator_role = 'contributor, processor';
info.creator_sector = 'academic';
info.creator_state = 'California';
info.creator_type = 'person';
info.creator_url = 'https://www.sea.com/';

info.featureType = 'trajectory';
info.id = 'to be assigned by ATN DAC';
info.infoURL = 'to be assigned by ATN DAC';
info.institution = '"SEA, Inc.",Cascadia Research Collective';
info.instrument = info.device_make ;
info.keywords = 'EARTH SCIENCE > AGRICULTURE > ANIMAL SCIENCE > ANIMAL ECOLOGY AND BEHAVIOR, EARTH SCIENCE > OCEANS, EARTH SCIENCE > BIOLOGICAL CLASSIFICATION > ANIMALS/VERTEBRATES > MAMMALS, EARTH SCIENCE > BIOLOGICAL CLASSIFICATION > ANIMALS/VERTEBRATES > MAMMALS > CETACEANS > TOOTHED WHALES, EARTH SCIENCE > BIOLOGICAL CLASSIFICATION > ANIMALS/VERTEBRATES > MAMMALS > CETACEANS > BALEEN WHALES, EARTH SCIENCE > BIOSPHERE > ECOSYSTEM DYNAMICS, EARTH SCIENCE > BIOSPHERE > ECOSYSTEMS > ANTHROPOGENIC/HUMAN INFLUENCED ECOSYSTEMS, EARTH SCIENCE > BIOSPHERE > ECOSYSTEMS > MARINE ECOSYSTEMS, EARTH SCIENCE > HUMAN DIMENSIONS > ENVIRONMENTAL IMPACTS, EARTH SCIENCE > HUMAN DIMENSIONS > ENVIRONMENTAL IMPACTS > CONSERVATION, EARTH SCIENCE > OCEANS > MARINE ENVIRONMENT MONITORING, EARTH SCIENCE > OCEANS > OCEAN ACOUSTICS';
info.keywords_vocabulary = 'GCMD Earth Science Keywords. Version 10.0';

info.license = 'These data may be used and redistributed for free, but are not intended for legal use, since they may contain inaccuracies. No person or group associated with these data makes any warranty, expressed or implied, including warranties of merchantability and fitness for a particular purpose, or assumes any legal liability for the accuracy, completeness or usefulness of this information. This disclaimer applies to both individual use of these data and aggregate use with other data. It is strongly recommended that users read and fully comprehend associated metadata prior to use. Please acknowledge data provider and the U.S. Animal Telemetry Network (ATN) or the specified citation as the source from which these data were obtained in any publications and/or representations of these data. Communication and collaboration with dataset authors are strongly encouraged.';

info.metadata_link = 'to be determined by ATN DAC';
info.naming_authority = 'gov.noaa.ioos.atn';
info.ncei_template_version = 'NCEI Trajectory template v2.0';

info.platform = 'animal';
info.platform_AphiaID = info.AphiaID ;
info.platform_vocabulary = 'https://mmisw.org/ont/ioos/platform';
info.processing_level = 'NetCDF file created from PRH and CAL files in SOCAL BRS project archive';
info.dephist_deploy_method = 'small boat approach and carbon-fiber pole';

info.project = 'Southern California Behavioral Response Study (SOCAL-BRS)';
info.project_name = info.project; %animaltags compatibility
info.project_datetime_start = datestr([2010 06 01 0 0 0], info.dephist_device_regset);
info.project_datetime_end = datestr([2015 10 01 0 0 0], info.dephist_device_regset);
info.publisher_country = 'USA';
info.publisher_email = 'atndata@ioos.us';
info.publisher_institution='US Animal Telemetry Network Data Assembly Center (US ATN DAC)';
info.publisher_name='Integrated Ocean Observing System Animal Telemetry Network (IOOS ATN)';
info.publisher_type='institution';
info.publisher_url='https://atn.ioos.us';
info.scientific_name = info.animal_species_science ;
info.sea_name='Southern California Bight, Pacific Ocean';
info.dephist_deploy_locality = info.sea_name; % animaltags compatibility
info.standard_name_vocabulary='CF Standard Name Table v77';

info.time_coverage_start = info.dephist_device_datetime_start ;
% info.time_coverage_duration & duration_seconds are set in prh2nc
info.time_coverage_end  = datestr(datenum(datevec(ton) + ...
    [0 0 0 0 0 str2num(info.time_coverage_duration_seconds)] ), ...
    info.dephist_device_regset); % taken from duration of depth data

info.tag_id = info.device_serial;
info.title = join(string({info.scientific_name, ...
    'data from', info.device_model, 'tag', ...
    '(deployment id', info.deploy_id, ')'})); % need to construct from other fields?
info.summary = join(string({info.common_name, ...
    '(deployment id', info.deploy_id, ')', ...
        'tagged with', ...
    info.device_make, info.tag_id, 'on', ...
    info.dephist_deploy_datetime_start, ...
    'in the', info.sea_name, ...
    'as part of the project', info.project})) ;% need to construct from other fields?

info = orderfields(info);