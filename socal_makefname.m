function    fname = socal_makefname(recdir, prefix,type,chip,SILENT,ndigits)
%
%    fname = makefname(recdir, prefix,type,[chip,SILENT,ndigits])
%     Generate a standard filename for a given tag deployment
%     and file type. Optional chip number is used for SWV, AUDIO,
%     GTX and LOG files.
%     Valid file types are:
%     RAW,CAL,PRH,AUDIT,SWV,GTX,AUDIO,LOG
%
%     mark johnson
%     majohnson@whoi.edu
%     last modified: 24 June 2006
%      sld33@calvin.edu, july 2021, support for nonstandard directory
%      structure with 2-digit dtg file numbers

fname = [] ; 

global TAG_PATHS
if isempty(recdir)
    if isempty(TAG_PATHS) | ~isfield(TAG_PATHS,type),
        if isempty(SILENT),
            fprintf(' No %s file path - use settagpath\n', type) ;
        end
        fname = -1 ;   % indicate an error
        return
    else
        recdir = getfield(TAG_PATHS,type) ;
    end
end

if nargin < 3,
   help socal_makefname
   return
end

if nargin<4,
   chip = 1 ;
   SILENT = [] ;
end

if nargin<5,
   SILENT = [] ;
end

if nargin>=4,
   if isstr(chip),         % swap arguments if silent comes first
      chip = SILENT ;
      SILENT = 's' ;
   end
end

if nargin<6 | isempty(ndigits),
   ndigits = 2 ;
end

if length(prefix)~=9,
   if isempty(SILENT),
      fprintf(' Tag deployment name must have 9 characters e.g., sw05_199a') ;
   end
   return
end

shortname = prefix([1:2 6:9]) ;
subdir = prefix(1:4) ;
if ndigits==2,
   pref = sprintf('%s%02d',shortname,chip) ;
else
   pref = sprintf('%s%03d',shortname,chip) ;
end

% make appropriate suffix for the given file type
switch upper(type),
   case 'RAW'
         suffix = strcat(prefix,'raw.mat') ;
   case 'CAL'
         suffix = strcat(prefix,'cal.mat') ;
   case 'PRH'
         suffix = strcat(prefix,'prh.mat') ;
   case 'AUDIT'
         suffix = strcat(prefix,'aud.txt') ;
   case 'SWV'
         suffix = [pref '.swv'] ;
         type = 'AUDIO' ;
   case 'GTX'
         suffix = [pref '.gtx'] ;
         type = 'AUDIO' ;
   case 'AUDIO'
         suffix = [pref '.wav'] ;
   case 'LOG'
         suffix = [pref '.txt'] ;
         type = 'AUDIO' ;
   otherwise
         fprintf(' Unknown file type: %s', type) ;
         return
end
        
% try to make filename
fname = sprintf('%s/%s',recdir,suffix) ;
