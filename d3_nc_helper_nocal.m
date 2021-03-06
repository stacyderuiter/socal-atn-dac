%#########################################################################
% matlab setup

% make sure you have everything from: github.com/stacyderuiter/socal-atn-dac
% depending on your matlab version you may need to do this once, or
% everytime

% adjust paths to match your machine :)

% Set matlab path to include tools
% nominally available at https://www.soundtags.org/dtags/dtag-toolbox/
addpath(genpath('C:\Users\Ross Nichols\Documents\GitHub\socal-atn-dac\dtagtools\matlab'))
% these are from the animaltags.org project
% most up to date version in Mark Johnson's computer
% next best github.com/stacyderuiter/TagTools/matlab
addpath(genpath('C:\Users\Ross Nichols\Documents\GitHub\socal-atn-dac\animaltagtools\matlab'))
addpath(genpath('C:\Users\Ross Nichols\Documents\GitHub\socal-atn-dac'))
savepath

%#########################################################################
% INFORMATION (PERHAPS) SPECIFIC TO EACH DEPLOYMENT

% Deployment ID. Usually these follow the standard
% DTAG protocol of: 
% 2-letter Latin species initials, 2-digit year, underscore,
% 3-digit Julian day of year, 1-letter animal of the day.
% This should match THE DTG FILE NAMES
depid = 'bw193a'; %'bw211b' ;

% Make a name for the nc file that you are going to create. Make sure the
% year is included in this one
ncname = 'bw13_193a'; % 'bw13_214c'; % 'bw13_193a'; %'bw14_211b'; % if nc file and depid are the same 
% ncname = [depid 'your_addition_here'] ; # to append something, might work

% Give the directory where the raw tag data (wav, swv, etc.) are stored.
% This can be a full path or relative to your working directory.
% Before starting, all .dtg files should be unpacked to get wav, swv, etc.
% files. This probably needs to be set only once, should then work for every
% tag.

base_dir = 'X:/SEA_PROJECTS/DTAG ARCHIVE/Blue Whale/';
% where dtg files are found
recdir = [base_dir ncname '/TAG data/dtg'] ;  
% where nc files should be saved
ncdir = [base_dir ncname];
% directory where focal follow data are
ffdir = [base_dir ncname '/FOCAL FOLLOW data'] ;  
%directory where photo id data are
pdir = [base_dir ncname '/PHOTO ID data'] ;

settagpath('cal', [base_dir ncname '/TAG data'], ... % where *cal.xml files are
    'prh', [base_dir ncname '/TAG data']); % where *prh.mat files are

%#########################################################################

% Make initial nc file with PRH data and some metadata. 
% Using initials 'bs' puts
% Brandon Southall's name as the data owner/contact person. To change this,
% edit the information in the files: TagTools/matlab/tagiofuns/researchers.csv. 
% TagTools/matlab/tagiofuns/species.csv has information about various study species 
% (if additions are needed). 

socal_prh2nc(ncname, 'bs', 'socal_project_info', 1, ncdir, recdir);

% note: if you get the message:
% Cue file for bw14_211b not found - run d3getcues or read_d3
% Don't worry - it's hard to suppress but not causing trouble.
% if in doubt start a new matlab session and run:
% load_nc([ncdir '/' ncname]) ;
% info
% (to check results)

% pitch, roll, heading
load_nc([ncdir '/' ncname]) ;
[CAL, DEPLOY] =  d3loadcal(ncname) ;
[pitch, roll] = a2pr(Aa) ;
head = m2h(Ma, Aa) ;
head = head + DEPLOY.DECL / 180 * pi ;      % adjust heading for declination angle in radians

pitch = sens_struct(pitch, Aa.sampling_rate, ncname, 'pitch');
pitch.axes = 'FRU';
pitch.frame = 'animal';
pitch.unit = 'rad';
pitch.unit_name = 'radians';
add_nc([ncdir '/' ncname], pitch)
% you'll get warnings like:  "Warning: unknown sensor type pitch. Set
% metadata manually"

roll = sens_struct(roll, Aa.sampling_rate, ncname, 'roll');
roll.axes = 'FRU';
roll.frame = 'animal';
roll.unit = 'rad';
roll.unit_name = 'radians';
add_nc([ncdir '/' ncname], roll)

head = sens_struct(head, Ma.sampling_rate, ncname, 'head');
head.axes = 'FRU';
head.frame = 'animal';
head.unit = 'rad';
head.unit_name = 'radians';
add_nc([ncdir '/' ncname], head)


% #########################################################################
% Read in metadata about acoustic data in wav files, save in SA structure
SA = socal_sound_archive(ncname, recdir);

% save it in the nc file
add_nc([ncdir '/' ncname], SA)

% #########################################################################
% Create structure with metadata about focal follow data (in excel file)
FA = focal_follow_archive(ncname, ffdir);
add_nc([ncdir '/' ncname], FA)

% #########################################################################
% Create structure with metadata about photo ID data
% note: there is an excel file and an example photo
PA = photo_archive(ncname, pdir);
add_nc([ncdir '/' ncname], PA)

% clean up
clear all

% #########################################################################
% What to archive:
% 1. .nc file
% 2. .wav files
% 3. .dtg files (?)
% 4. focal follow files (?)
% 5. photo ID files (?)

% #########################################################################
% ALTERNATIVE: READING IN RAW DATA RATHER THAN USING EXISTING PRH FILE
% NOT COMPLETE - COULD COMPLETE IF NEEDED.
% Possible benefit: stores a bit more information about the cal constants
% used to convert from volts to sci units. 
% Issues: buggier, takes longer, you will not recreate the exact data that
% is in the current prh files.

