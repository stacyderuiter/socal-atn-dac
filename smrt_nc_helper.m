% make smrt nc
% Add dtag, smrt, and animaltags tool boxes to your matlab path
addpath(genpath('F:\FBarchivalTags\cal-workshop-materials\dtag-matlab'))

addpath('F:\FBarchivalTags\cal-workshop-materials\smrt-matlab')

addpath(genpath('F:\FBarchivalTags\cal-workshop-materials\animaltags-matlab'))

% ONLY if you do not have the signal processing tool box, uncomment and run:
addpath('F:\FBarchivalTags\cal-workshop-materials\matlab-toolbox-supplement\nansuite')
addpath('F:\FBarchivalTags\cal-workshop-materials\matlab-toolbox-supplement\octave\signal')


% ONLY if you do not have the statistics tool box, uncomment and run:
addpath('F:\FBarchivalTags\cal-workshop-materials\matlab-toolbox-supplement\octave\statistics')

savepath()

% change the datapath to match where the data files are on your machine.
datapath = 'F:\FBarchivalTags\cal-workshop-materials\Zica-20190113-151361\';
depid = 'Zica-20190113-151361';

nc_filename = read_smrt_gps([datapath 'SMfiles'], ... % recdir
                            depid, ... % depid
                            [datapath 'DAP580\Zica-20190113-151361-FastGPS.csv'], ... % gps_file
                            [datapath 'DAP580\Zica-20190113-151361-Archive.csv'], ... % archive_file
                            [depid '-workshop-demo'], ... % output nc file nameS
                            'zc');

nc_filename

Zica0113 = load_nc(nc_filename);

Zica0113
Zica0113.GPS_position
Zica0113.info

format bank
get_start_time(Zica0113.info)

[S,fields] = combine_csv([datapath 'SMfiles'], depid);

tp = etime(datevec(S(:,1)), ...
           repmat(get_start_time(Zica0113.info), size(S,1),1)) ...
           + S(:,2) / 1e6;  % seconds since tag on

% interpolate dive depth and temperature to regular sampling interval
fsp = 0.5 ;
% desired output time stamps, in seconds since start
t = (0.5/fsp : 1/fsp : max(tp))';
% press data is in col 4, temp in col 5 of S
p = interp1(tp, S(:,4), t);
tt = interp1(tp, S(:,5), t);
T = sens_struct(tt, fsp, depid, 'temp') ;  % temperature
P = sens_struct(p, fsp, depid, 'press') ;  % pressure

recdir = [datapath 'SMfiles']

X = d3readswv(recdir,depid);

CAL = d4readattr(hex2dec('30046408')) ;

Zica0113.info.dephist_deploy_location_lat = 32.7275 ;
Zica0113.info.dephist_deploy_location_lon = -118.8661 ;

[F,did,recn,recdir] = getrecfnames(recdir, depid);
did = sprintf('%x',did(1)) ;
F = strcat(F, '.swv, ');
F
did

Zica0113.info.dtype_source = [F{:}];
Zica0113.info.dtype_nfiles = length(F);
Zica0113.info.device_serial = did;
Zica0113.info.sensors_list = [Zica0113.info.sensors_list, 'hydrophone, pressure, tri-axial accelerometer, tri-axial magnetometer, temperature'];
Zica0113.info

SA = sound_archive(depid);
SA.file_location = 'Marine Ecology and Telemetry Research, Seabeck, WA 98380, USA';
% SA.file_contact_email = Zica0113.info.provider_email;
% SA.file_contact_person = Zica0113.info.provider_name;
SA.file_contact_url = 'http://www.marecotel.org/';
SA

SA.data

[Padj, pc] = fix_pressure(P, T, 2);

%plot native
plott(P, Padj)

%plot inline
[ax, h] = plott(P, Padj);
yl = [-2, 1];
set(ax, 'ylim', yl)

% data probably in X.x{1:3} but we can check based on channel names
[chan_names,chan_descrips] = d3channames(X.cn);
iacc = ~cellfun('isempty', regexp(chan_descrips, 'accel'));
A_fs = X.fs(find(iacc, 1));

A = sens_struct([X.x{find(iacc)}], A_fs, depid, 'acc') ; % acceleration


Ac = auto_cal_acc(A,CAL.ACC);

%plot inline
plott(A, Ac)

A = Ac;
clear Ac

imag = ~cellfun('isempty', regexp(chan_descrips, 'magnet'));
imagt = ~cellfun('isempty', regexp(chan_descrips, 'temper'));
imag = imag & ~imagt ;

M = sens_struct([X.x{find(imag)}], X.fs(find(imag, 1)), depid, 'mag') ; 

Td = interp2length(T, M);
Pd = interp2length(Padj, M);
cal = CAL.MAG ; 
cal.poly = [1 0;1 0;1 0] ;

mag_strength = 45.8; % expected field strength in uT

if length(X.x)==7, % if there is an internal temperature channel (2019 tags) -- could also search for "mag temp" in channel name
    Tint = sens_struct(X.x{7}*4096+15, X.fs(7), depid, 'temp');
    Tint.name = 'Tint' ;
    Tint.description = 'internal temperature from LIS44' ;
    [Mc,cal1] = auto_cal_mag(M, cal, mag_strength, [Td.data Td.data Tint.data Pd.data/100] ,[60 600 0 0]);
    Mc.cal_tsrc = 'T,T,Tint,P/100' ;
else  % otherwise, approximate internal temperature by slowing down external temperature
    % make Pd.data with no neg to avoid complex numbers
    Pd_pos = Pd.data;
    Pd_pos(Pd.data < 0) = 0;
    [Mc,cal1] = auto_cal_mag(M, cal, mag_strength, [Td.data Td.data Td.data Pd.data/100 sqrt(Pd_pos/100)], [300 60 800 0 0]);
    Mc.cal_tsrc = 'T,T,T,Tsq,P/100,(T-20).^2' ;
end

%plot inline
plott(M, Mc)

M = Mc;
clear Mc

%plot native
plott(Padj, A, M)
% use this figure to find the time of tag-off

A_lo = decdc(A, A.sampling_rate * 2); % decimate to 0.5 Hz for plotting and tag-to-whale conversion (to match depth data)
%plot inline
[ax, h] = plott(Padj, A_lo);
set(ax, 'xlim', [12.8, 12.9]);

%plot native
[ax, h] = plott(Padj, A_lo);

toa = [0, 46128];
A_crop = crop_to(A,toa);
A_lo = crop_to(A_lo, toa);
M_crop = crop_to(M, toa);
depth_crop = crop_to(Padj, toa);
temp_crop = crop_to(T, toa);

%plot inline
plott(depth_crop, A_crop, temp_crop)

nA = norm2(A_crop.data);
plot(nA); 
grid on;

A_crop.data(1:A.sampling_rate,:) = 0;
M_crop.data(1:M.sampling_rate,:) = 0;

vv = norm2(M_crop.data) ;
mag_field_strength = mean(vv, 'omitnan')
mag_field_sd = std(vv, 'omitnan') 


save_nc('Zica-20190113-151361-workshop-demo-tagframe', A_crop, M_crop, depth_crop, temp_crop,...
        Zica0113.GPS_position, Zica0113.GPS_satellites, Zica0113.GPS_residual, ...
        Zica0113.batt, Zica0113.wet); 

PRH = prh_predictor1(depth_crop, A_lo, 200);

PRH

median(PRH, 1)

OTAB = [0 0  0.5         -1.87         -1.52]

Aw = tag2animal(A_crop, OTAB) ;

Mw = tag2animal(M_crop, OTAB) ;

%plot native
plott(depth_crop, Aw)

%plot inline
plott(depth_crop, Aw)

Aw5 = decdc(Aw, Aw.sampling_rate / 5);
Mw5 = decdc(Mw, Mw.sampling_rate / 5);

[pitch, roll] = a2pr(Aw5);
[head vm incl] = m2h(Mw5, Aw5) ;

mean(incl, 'omitnan') / pi * 180

DECL = 11.8 / 180 * pi; % from above NOAA data - in radians
head = head + DECL ;      % adjust heading for declination angle in radians
%plot inline
[ax, h] = plott(depth_crop.data, depth_crop.sampling_rate, pitch, Aw5.sampling_rate, ...
                roll, Aw5.sampling_rate, head, Mw5.sampling_rate);
ylabel(ax(1), 'Depth')
ylabel(ax(2), 'Pitch')
ylabel(ax(3), 'Roll')
ylabel(ax(4), 'Heading')
set(ax(1), 'YDir', 'reverse')

Aw.name = 'Aw';
Mw.name = 'Mw';
depth_crop.name = 'depth';
% Tint_crop.name = 'internal_temp';

if ~isstruct(pitch)
pitch = sens_struct(pitch, Aw5.sampling_rate, depid, 'pitch');
pitch.axes = 'FRU';
pitch.frame = 'animal';
pitch.unit = 'rad';
pitch.unit_name = 'radians';

roll = sens_struct(roll, Aw5.sampling_rate, depid, 'roll');
roll.axes = 'FRU';
roll.frame = 'animal';
roll.unit = 'rad';
roll.unit_name = 'radians';

head = sens_struct(head, Mw5.sampling_rate, depid, 'head');
head.axes = 'FRU';
head.frame = 'animal';
head.unit = 'rad';
head.unit_name = 'radians';
end

wet = crop_to(Zica0113.wet,toa);
batt = crop_to(Zica0113.batt,toa);
wet.conductivity_threshold = 80;

save_nc('Zica-20190113-151361-workshop-demo-cal', Aw, Mw, depth_crop, temp_crop, ... % this tag has no Tint sensor
            Zica0113.info, SA,...
            wet, batt, ...
            pitch, roll, head,...
        Zica0113.GPS_position, Zica0113.GPS_satellites, Zica0113.GPS_residual); 
