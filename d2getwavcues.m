function    [ct,ref_time,fs,fn,recdir] = d2getwavcues(recdir,prefix,suffix)
%
%    [ct,ref_time,fs,fn,recdir,recn] = d2getwavcues(recdir,prefix,suffix)
%     Get the cue table, reference time, sampling rate and file information
%     for a DTAG2 deployment.
%     ct has a row for each contiguous block in the deployment.
%     The columns of ct are:
%        File number (this is the sequential number of the file in the
%           directory, not the numerical suffix of the filename)
%        Start time in seconds since the reference time
%        Number of samples in the block
%        Error status of block (uncertain what codes mean)
%
%     Note: to convert the first column of ct to filename suffix, do:
%        ct(:,1) = recn(ct(:,1)) ;
%
%     markjohnson@st-andrews.ac.uk
%     bug fix: FHJ 8 april 2014
%     improved help 31/8/19
%     rough conversion for DTAG2 
%     sld33@calvin.edu July 2021

ct = [] ; ref_time = [] ; fs = [] ; fn = [] ; C = [] ; recn = [] ;

if nargin<2,
   help d2getcues
   recdir = [] ;
   return
end

if nargin<3 || isempty(suffix) || ~ischar(suffix),
   suffix = 'wav' ;
end

if ~isempty(recdir) && ~ismember(recdir(end),'/\'),
   recdir(end+1) = '/' ;
end

recdir(recdir=='\') = '/' ;      % use / for MAC compatibility
cuefname = [gettempdir '_' prefix suffix 'cues.mat'] ; 

if exist(cuefname,'file'),
   C = load(cuefname) ;
   if ~isfield(C,'vers') || C.vers ~= d3toolvers(),
      C = [] ;
   end
end
      
if isempty(C),
    [N,chips,fnames, ref_time, chnk] = socal_makecuetab(recdir, prefix) ;
    % ct should be File number
%        Start time of block (UNIX seconds)
%        Microsecond offset to first sample in block
%        Number of samples in the block
%        Status of block (1=zero-filled, 0=data bearing, -1=data gap)
    ct = [N.N(:, 1:2), zeros(size(N.N, 1), 1), N.N(:, 3:4)] ;
    fs = mean(round(N.N(:,5))); 
    fn = fnames ;
end

return
