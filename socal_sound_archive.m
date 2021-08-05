function    SA = socal_sound_archive(depid, recdir)

%    SA = socal_sound_archive(depid, recdir)   % use default name
%
%    Generate a sound archive structure for a deployment.
%
%    Inputs:
%    depid is a string containing the deployment identifier.
%    recdir is the directory where the wav files are located (needed to
%    build dtag2 cuetab from scratch if it's not in the CAL file)
%
%    Returns:
%    X is a sound archive structure with metadata fields pre-populated. 
%		 Change these as needed to the correct values.
%
%
%    Valid: Matlab, Octave
%    markjohnson@st-andrews.ac.uk
%    Last modified: 7 June 2019
%    modified for SOCAL DTAG2 tags, sld33@calvin.edu july 2021

SA = [] ;
if nargin<1,
   help socal_sound_archive
   return
end

X.depid = depid ;
X.type = 'archive' ;
X.name = 'SA' ;
X.full_name = 'sound_archive' ;
X.description = 'Sound data archive listing' ;

if dtagtype(depid) == 3
    [ct,ref_time,fs,fn] = d3getcues([],depid) ;
    if isempty(fn),
        fprintf('No directory for this deployment - run d3getcues\n') ;
        return
    end
    audio_start_time = datestr(d3datevec(ref_time),'yyyy-mm-dd HH:MM:SS.FFF');
elseif dtagtype(depid) == 2
    try
        [N,chips,fnames, ref_time, chnk] = socal_makecuetab(recdir, depid) ;
        % N.N is the cuetab in DTAG2 format so it has
        % filenumber, pps_at_start,nsamples,number of errors,fs,compression
        if isstruct(N)
            N = N.N; % cuetab in dtag2 format
        end
        % we want dtag3 format with cols:
        %        1. File number
        %        2. Start time of block (seconds since ref time)
        %        %        documentation says this is there but it's not so it won't be for us either: Microsecond offset to first sample in block
        %        3. Number of samples in the block
        %        4. Status of block (1=zero-filled, 0=data bearing, -1=data gap)
        fs = mean(round(N(:,5)));
        fn = fnames ;
        ct = N(:, 1:4) ;
        % convert first column from "chip number" to file number
        ct(:,1) = 1:size(ct,1);
        % convert last col from # of errors to status of block (1=zero-filled, 0=data bearing, -1=data gap)
        ct(:,4) = 0; % all "data bearing" -- we know # errors but not where they are so can't document that in this cuetab
        audio_start_time = datestr(ref_time, 'yyyy-mm-dd HH:MM:SS.FFF');
    catch
        % if failure, look for CUETAB in CAL file
        % (problem is this doesn't give us file names so we need to make them).
        % and we assume they are same ones used to make existing cuetab
        wavlist = dir([recdir '/*.wav']);
        fn = {wavlist.name};
        DEPLOY = loadcal(depid);
        if isfield(DEPLOY, 'CUETAB')
            if isstruct(DEPLOY.CUETAB)
                if isfield(DEPLOY.CUETAB, 'N')
                    N = DEPLOY.CUETAB.N; % cuetab in dtag2 format
                end
            else
                N = DEPLOY.CUETAB;
            end
        end
        fs = mean(round(N(:,5)));
        fn = {'UNKNOWN'} ;
        ct = N(:, 1:4) ;
        % convert first column from "chip number" to file number
        ct(:,1) = 1:size(ct,1);
        % convert last col from # of errors to status of block (1=zero-filled, 0=data bearing, -1=data gap)
        ct(:,4) = 0; % all "data bearing" -- we know # errors but not where they are so can't document that in this cuetab
        if isfield(DEPLOY,'TAGON')
            audio_start_time = datestr(datenum(DEPLOY.TAGON(:)'), 'yyyy-mm-dd HH:MM:SS.FFF');
        else
            audio_start_time = 'UNKNOWN';
        end
    end
end

sz = zeros(length(fn),1) ;
for k=1:length(fn),
	sz(k) = sum(ct(ct(:,1)==k & ct(:,4)>=0,3)) ;
end

% change format of block status from 0==data to 1==data
kk = ct(:,4)>=0 ;
ct(kk,4) = ct(kk,4)==0 ;

for i = 1:length(fn)
    if ~endsWith(fn{i}, '.wav')
        fn{i} = [fn{1}, '.wav'];
    end
end

X.file_names =  char(join(fn, ','));
X.file_number = length(fn) ;
X.file_format = 'wav' ;
X.file_resolution = 16 ;
X.file_compression = 'none' ;
X.file_size = sz ;
X.file_size_unit = 'samples' ;
X.file_location = 'Southall Environmental Associates, Inc., Aptos, CA' ;
X.file_url = '' ;
X.file_doi = '' ;
X.file_contact_email = 'brandon.southall@sea-inc.net' ;
X.file_contact_person = 'Brandon Southall' ;
X.file_contact_url = 'https://www.sea.com/' ;
X.archive_status = 'complete' ;
X.channel_num = 1 ;
X.channel_separation = 0 ;
X.channel_separation_unit = 'm' ;
X.channel_sensitivity = -172 ;
X.channel_sensitivity_unit = 'Decibels re volt per micropascal' ;
X.channel_sensitivity_label = 'dB re V/\muPa' ;
X.channel_sensitivity_explanation = 'Total recording sensitivity from water to wav file denoting full-scale in the wav file as 1.0 Volt' ;
X.channel_sensitivity_includes_gain = 'yes' ;
X.channel_gain = 12 ;
X.channel_gain_unit = 'Decibels' ;
X.sampling = 'regular' ;
X.sampling_rate = fs ;
X.sampling_rate_unit = 'Hz' ;
X.sampling_3dB_low = 'UNKNOWN' ;
X.sampling_3dB_high = 'UNKNOWN' ;
X.data = ct ;
X.data_row_name = 'block' ;
X.data_column_name = 'file,time,samples,status' ;
X.data_column_description_status = '1=data,0=zero-filled,-1=gap' ;
X.data_column_description_file = 'number of file in file_names' ;
X.data_column_description_time = 'time in seconds since start_time' ;
X.data_column_description_samples = 'number of sound samples per channel in block' ;
X.contig_within_files = 'yes' ;
X.contig_across_files = 'yes' ;
X.start_time = audio_start_time ;
X.start_time_tzone = 'UTC' ;
X.calibration_method = 'UNKNOWN' ;
X.calibration_date = 'UNKNOWN' ;
X.selfnoise_file = fn{1} ;
X.selfnoise_cue_start = 0 ;
X.selfnoise_cue_end = 6 ;
X.selfnoise_cue_unit = 'second into file' ;
X.creation_date = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF') ;
X.history = 'd3getcues,sound_archive' ;
SA = orderfields(X) ;
