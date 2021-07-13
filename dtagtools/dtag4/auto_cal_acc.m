function    [A,cal] = auto_cal_acc(A,fs,cal)

%     [A,cal] = auto_cal_acc(A)					% A is a sensor structure
%		or
%     [A,cal] = auto_cal_acc(A,cal)				% A is a sensor structure
%		or
%     [A,cal] = auto_cal_acc(A,fs)				% A is a matrix
%		or
%     [A,cal] = auto_cal_acc(A,fs,cal)			% A is a matrix
%
%     markjohnson@st-andrews.ac.uk
%     Last modified: 28 dec 2019

DO_CROP = 1 ;          % use 0 to bypass the crop step
fa = 0.5 ;             % target analysis sampling rate in Hz

if nargin<1,
	help auto_cal_acc
	return
end
	
if isstruct(A),   % if A is a sensor-structure, extract the data
	if nargin>1,
		cal = fs ;
	else
		cal = [] ;
	end
	[Ad,fs] = sens2var(A) ;
else
	if nargin<2 || isstruct(fs),
		fprintf(' Sampling rate is required with matrix data\n') ;
		return
	end
	if nargin<3,
		cal = [] ;
	end
	Ad = A ;
end

J = sum(diff(Ad).^2,2) ;   % find where A is changing rapidly
J(end+1) = J(end) ;

if fs>fa,      % if A is sampled faster than fa, decimate it.
   df = ceil(fs/fa) ;
   Ad = decdc(Ad,df) ;
   fsd = fs/df ;
   J = abs(decdc(J,df)) ;  % decimate the jerk as well
else
   fsd = fs ;
end

fstr = 9.81 ;		% earth's gravitational acceleration in m/s2
if DO_CROP,       % if requested, open the crop gui on A
   [Ad,tc] = crop(Ad,fsd) ;
   J = crop_to(J,fsd,tc) ; % apply the same crop to J
end

if isempty(cal),
	cal.poly = [1 0;1 0;1 0] ;
else
	if isfield(cal,'POLY'),
		cal.poly = cal.POLY ;
		cal = rmfield(cal,'POLY') ;
	end
end

thr = prctile(J,75) ;   % data selection
k = find(J<thr) ;
AA = Ad(k,:) ;
[AA,cc,sigma] = spherical_ls(AA,fstr,cal,2) ;

% update CAL
if sigma(2)>=sigma(1),
	fprintf(' Deviation not improved (was %3.2f%%, now %3.2f%%)\n',sigma*100) ;
	return
end

fprintf(' Deviation improved from %3.2f%% to %3.2f%%\n',sigma*100) ;
cal = cc;

% apply cal to the complete accelerometer signal

if isstruct(A),
	if ~isfield(A,'history') || isempty(A.history),
		A.history = 'auto_cal_acc' ;
	else
		A.history = [A.history ',auto_cal_acc'] ;
   end
   A=do_cal(A,cal);
else
   A=do_cal(A,fs,cal);
end


