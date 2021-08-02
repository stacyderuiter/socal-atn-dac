%#########################################################################
% INFORMATION SPECIFIC TO EACH DEPLOYMENT (edit each time)

% Set matlab path to include tools
addpath(genpath('C:/Users/Stacy DeRuiter/Dropbox/dtagtools/dtag4_from_fleur/matlab'))
addpath(genpath('C:/Users/Stacy DeRuiter/Dropbox/dtag/dtag4'))
addpath(genpath('C:/Users/Stacy DeRuiter/Dropbox/TagTools/matlab'))
savepath



% Deployment ID. Usually these follow the standard
% DTAG protocol of: 
% 2-letter Latin species initials, 2-digit year, underscore,
% 3-digit Julian day of year, 1-letter animal of the day.
depid = 'bw211b' ;

% Make a name for the nc file that you are going to create. (The project may
% wish to have a convention for this that includes something other than
% just the deployment ID). The ".nc" extension need not be included.
ncname = 'bw14_211b'; % if nc file and depid are the same 
% ncname = [depid 'your_addition_here'] ; # to append something

% Give the directory where the raw tag data (wav, swv, etc.) are stored.
% This can be a full path or relative to your working directory.
% Before starting, all .dtg files should be unpacked to get wav, swv, etc.
% files.
base_dir = 'E:/ATN/';
recdir = [base_dir ncname '/TAG data/dtg'] ;  
% directory where focal follow data are
ffdir = [base_dir ncname '/FOCAL FOLLOW data'] ;  
%directory where photo id data are
pdir = [base_dir ncname '/PHOTO ID data'] ;  

settagpath('cal', [base_dir ncname '/TAG data'], ... % where *cal.xml files are
    'prh', [base_dir ncname '/TAG data']); % where *prh.mat files are

% Make an info structure for the deployment. Using initials 'bs' puts
% Brandon Southall's name as the data owner/contact person. To change this,
% edit the informaiton in the files: user/researchers.csv. 
% user/species.csv has information about various study species 
% (if additions are needed). 

d3getcues(recdir, depid, 'swv') ;

% get the calibration constants & metadata for this tag
[CAL, DEPLOY] =  d3loadcal(ncname) ;

% add more info
info = make_info(depid, 'D3', depid(1:2), 'bs');
info.depid = ncname; % because the depid is short (no year)
% The next few entries will be same for all SOCAL deployments
info.project_name = 'SOCAL BRS';
info.project_datetime_start = '2010/08/01'; % may be able to be more precise?
info.project_datetime_end = '2016/03/26'; % may be able to be more precise?
info.dephist_deploy_locality = 'Southern California Bight';
info.dephist_deploy_method = 'suction cup';
% Add deployment-specific tagon location information here:
info.dephist_deploy_location_lat = DEPLOY.TAGON.POSITION(1); % lat in decimal degrees
info.dephist_deploy_location_long = DEPLOY.TAGON.POSITION(2); % lon in decimal degrees


% #########################################################################
% Read in metadata about acoustic data in wav files, save in SA structure
d3getcues(recdir, depid) ;
SA = sound_archive(depid);
SA.file_location = 'SEA, Inc., Aptos, CA 95003, USA';
SA.file_contact_email = info.provider_email;
SA.file_contact_person = info.provider_name;
SA.file_contact_url = 'https://sea-inc.net/';

% #########################################################################
% Create structure with metadata about focal follow data (in excel file)
FA = focal_follow_archive(ffdir);
% need to write func :)

% #########################################################################
% Create structure with metadata about photo ID data
% note: there is an excel file and an example photo
PA = photo_archive(pdir);

% #########################################################################
% Save NC file

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

% Read in the raw data, for example using one of the following:
X = d3readswv_commonfs(recdir, depid, 25) ;		% decimates to a common 25 Hz sampling rate

% In all cases, X will contain three fields:
%  X.x is the actual data in a cell array with one sensor channel per cell
%     To access the 8th sensor channel, you do X.x{8}
%     To access the first three sensor channels (assuming they are all the same size,
%     you do [X.x{1:3}]
%     If you used the 'info' option, X.x will be empty.
%  X.fs is a vector with the sampling rate for each sensor channel, in Hz
%  X.cn is a vector of the channel numbers - these are the id numbers that DTAGs use
%     to figure out what kind of data is in each sensor channel. Use d3channames(X) 
%     to find out which channels are present and in what order they are listed in X.x.
%     You can also do d3channames(recdir,depid) to see what sensors are in a dataset
%     before reading it in.

% Generate sensor structures for each of the data types.
[~,~,~,type] = d3channames(X.cn) ;
% temperature and pressure
it = find(strcmp(type,'tempr')) ; 
ip = find(strcmp(type,'press')) ; 
ib = find(strcmp(type, 'press.bridge')) ;
P = sens_struct(X.x{ip}, X.fs(ip), ncname, 'press') ;	% pressure

if isfield(CAL.PRESS.TC,'SRC') && strcmp(CAL.PRESS.TC.SRC,'TEMPR'),
   fst = X.fs(it(1)) ;
   t = fixoutage(X.x{it(1)});
   T = sens_struct(t, X.fs(it(1)));
   T = apply_cal(T, CAL.TEMPR) ;
elseif ~isempty(ib),
   % convert the bridge voltage to temperature
   t = fixoutage([X.x{ib}], X.fs(ib(1)), 0.1, 3) ;
   T = sens_struct(t, X.fs(ib(1)), ncname, 'temp') ;
   T = apply_cal(T, CAL.PRESS.BRIDGE) ;
   T.data = T.data(:, 2) ;
end

t = interp2length(T, P) ;
P = apply_cal(P, CAL.PRESS, t) ;

% acceleration
ia = find(strcmp(type, 'acc')) ;
A = sens_struct([X.x{ia}], X.fs(find(ia, 1)), ncname, 'acc') ; % acceleration
A = apply_cal(A, CAL.ACC) ;
A.data = A.data .* 9.81 ; % convert to m/sec/sec

% magnetic field
%  grab the data
im = find(strcmp(type,'mag')) ;
M = [X.x{im}] ; 
% if there are 6 columns interp to 3
if length(im) > 3,
   [M, ~, fsm] = interpmag(M, X.fs(im(1))) ;
   fsm = fsm(1) ;
end
% make into a sensor data structure
M = sens_struct(M, fsm, ncname, 'mag') ;
% decimate back to right sampling rate
M = decdc(M, 2) ;
% apply cal constants to convert from volts to uT
M = apply_cal(M, CAL.MAG, T) ;


% #########################################################################
% Read in PRH file, create more sensor data structures

loadprh(ncname) ;
OTAB = DEPLOY.OTAB ;

% Accel and mag in whale frame
Mw = tag2animal(M, OTAB) ;
Aw = tag2animal(A, OTAB) ;

% pitch, roll, heading
[pitch, roll] = a2pr(Aw) ;
head = m2h(Mw, Aw) ;
head = head + DEPLOY.DECL / 180 * pi ;      % adjust heading for declination angle in radians

pitch = sens_struct(pitch, Aw.sampling_rate, ncname, 'pitch');
pitch.axes = 'FRU';
pitch.frame = 'animal';
pitch.unit = 'rad';
pitch.unit_name = 'radians';

roll = sens_struct(roll, Aw.sampling_rate, ncname, 'roll');
roll.axes = 'FRU';
roll.frame = 'animal';
roll.unit = 'rad';
roll.unit_name = 'radians';

head = sens_struct(head, Mw.sampling_rate, ncname, 'head');
head.axes = 'FRU';
head.frame = 'animal';
head.unit = 'rad';
head.unit_name = 'radians';


% #########################################################################




% Plot the pressure and check if it is correct when the animal surfaces.
% If not, do the following:
[P,pc] = fix_pressure(P,T);
% The calibration corrections are noted in P but you also need to add them
% to the calibration structure in case you want to do the calibration again
% for example, at a different sampling rate. 
CAL.PRESS.poly(2)=pc.poly(2);	% update the CAL for the pressure sensor offset
CAL.PRESS.tcomp=pc.tcomp;		% and the temperature compensation

% Plot the pressure again. If it is still not correct when the animal surfaces
% and the '0' pressure seems to be changing over time, do the following:
P1 = fix_offset_pressure(P,300,300);
% Plot P1 and adjust the last two numbers (300) up or down as required to
% make the surfacings look reasonable. See the help on fix_offset_pressure for
% guidance. When P1 looks good, rename it as P.

% Apply and check the calibration on the accelerometer as follows. This will
% try to improve the calibration based on the data. Note that auto_cal_acc does
% not implement any axis conversions, i.e., it ignores the accelerometer MAP. This
% is because the calibration polynomial in CAL.ACC works on the sensor axes not the
% tag axes. The MAP is applied in a later step.
[AA,ac] = auto_cal_acc(A,CAL.ACC) ;
% Plot AA or norm2(AA) to make sure it looks good. If it does, save the
% improved calibration:
CAL.ACC = ac ;

% Apply the calibration and map to get the final tag-frame accelerometer data:
A = apply_cal(A,CAL.ACC) ;

% Once you have made changes to the CAL structure, save them to a cal file for this
% deployment:
save([depid 'cal.mat'],'CAL')
% You can retrieve this file later using CAL=d4findcal(depid);

% It is also a good idea to save the data you have got so far just in case something
% goes wrong. You can add more data later.
save_nc(ncname,info,P,T,A) ;

% Generate an RMS jerk vector with a sampling rate of e.g., 5 Hz. This takes some
% time to run because it reads the entire high-rate accelerometer data.
J = d3rmsjerk(recdir,depid,CAL.ACC.poly,5);
add_nc(ncname,J) ;

% GPS grab processing
% 1. Pre-process the grabs to get the pseudo-ranges. This can take a day or more
%    depending on the number of grabs and the speed of your computer.
d3preprocgps(recdir,depid) ;

% 2. Gather the results from the pre-processing into an OBS structure.
OBS = d3combineobs(recdir,depid) ;

% 3. Get estimates of the start position of the tag and its clock offset with respect
%    to GPS time. If you have good estimates for these already, proceed to step 4. 
%	  Most likely you know the rough start position (e.g., within 0.5 degree) but are
%	  not sure about the clock offset. In which case, do this:
[tc,rerr] = gps_timesearch(OBS,[lat,long],[-30 30],200) ;
% In this line, [-30 30] defines the clock offset time range to search, i.e., -30 to 30 
% seconds with respect to true time. This is plenty for normal clock offsets that come
% about from 
% tc is an estimate of the time offset between the tag clock and GPS time, in seconds.
% rerr is an estimate of the location error (in metres) that will result in the first
% GPS location if you use this clock offset. If rerr is less than a few hundred
% metres, give tc a try in step 4 below. If rerr is high, then either your starting
% position estimate is not good or you need to allow a larger/different time offset
% search. Either way, one of the following steps might be needed.

% If you don't know within +/- 2 degrees what the start position is, do the following:
check_sv_elevation(OBS,latr,longr,tc,THR) ;
% If you know the starting point within +/- 2 degrees (e.g., as a result of
% running check_sv_elevations, run the following:
find_start_point(OBS,latr,longr,tc,THR) ;
% This will tell you a likely starting point for the GPS track.
% Now you can try to get the time offset using gps_timesearch as above.

% 4. Run the GPS processor to compute the track. This can take several hours
%    if there were a lot of grabs.
[POS,N,gps] = gps_posns(OBS,[lat,long],tc,THR);

% 5. Save the result. First save all of the outputs in a .mat file.
save([depid 'trk.mat'],'POS','N','gps')
% Then generate a nc file for the GPS tracking data

gpst = etime(datevec(POS.T),repmat(get_start_time(info),size(POS.T,1),1)) ;
POS=sens_struct([POS.lat POS.lon],POS.T,depid,'pos');
save_nc([depid 'trk'],info,POS)	% info was defined at line 21 above
