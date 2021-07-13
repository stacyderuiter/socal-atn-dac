function		[H,TEMP,P] = lps22hh(cal,pr,tr)

%		[h,t,p] = lps22hh(cal,pr,tr)
%		Inputs:
%		cal is a cal structure for pressure
%		pr is the raw pressure value (integer)
%		tr is the raw temperature value (integer)
%
%		Returns:
%		h is height in metres
%		t is temperature in degrees C
%		p is pressure in millibars

if ~isfield(cal,'cal'),
	fprintf(' Cal structure for ms5837 must contain a cal field\n') ;
	return
end
	
C = cal.cal ;
C(C<0) = C(C<0)+2^16 ;

% Below calibration assumes data format:
% <WDLEN SENS="PRES"> 16,8 </WDLEN>

if ~isfield(cal,'poffs'),
	cal.poffs = 0 ;
end
	
if ~isfield(cal,'toffs'),
	cal.toffs = -10000 ;
end

% temperature calculation
TEMP = (tr-cal.toffs)/100 ;  % temperature in degC

% pressure calculation
P = (pr-cal.poffs*256)/4096 ;  			% pressure in millibars
H = 44308*(1-(P/1013.25).^0.1903) ;    % height in metres
