function    PA = photo_archive(depid, pdir)

%    PA = photo_archive(depid, pdir)
%
%    Generate a photo ID archive structure for a deployment.
%
%    Inputs:
%    depid is a string containing the deployment identifier.
%    pdir is where the photo ID data files are located
%
%    Returns:
%    PA is a photo ID archive structure with metadata fields pre-populated. 
%		 Change these as needed to the correct values.
%
%
%    Valid: Matlab, Octave
%    markjohnson@st-andrews.ac.uk
%    sld33@calvin.edu
%    last modified: july 2021

PA = [] ;
if nargin < 1
   help photo_archive
   return
end

X.depid = depid ;
X.type = 'photoid_archive' ;
X.name = 'PA' ;
X.full_name = 'photo_ID_archive' ;
X.description = 'Photo ID archive listing' ;

files = dir([pdir '/*']) ;
files = files(~ismember({files.name},{'.','..'}));
all_cols = {} ; 
exts = [];
if isempty(files),
	fprintf('No photo ID files found in pdir\n') ;
	return
else
    for f = [1:length(files)]
        [~,~,EXT] = fileparts(files(f).name);
        EXT = erase(EXT, '.');
        if EXT == "xlsx"
            p_data = readtable([pdir '/' files(f).name], 'VariableNamingRule', 'preserve');
            these_cols = p_data.Properties.VariableNames ;
            all_cols = union(all_cols, these_cols) ;
            clear p_data
        end
        exts = [exts, string(EXT)];
    end
end


X.file_names = join(erase(string(strvcat(files.name)), ' '), ',');
X.file_number = length(files) ;
X.file_format = char(join(exts,',')) ;
X.file_compression = 'none' ;
X.file_size = files.bytes ;
X.file_size_unit = 'bytes' ;
SA.file_location = 'Cascadia Research Collective, 218 1/2 W 4th Ave., Olympia, WA 98501 USA; SEA, Inc., Aptos, CA 95003, USA';
SA.file_contact_email = 'calambokidis@cascadiaresearch.org, brandon.southall@sea-inc.net' ;
SA.file_contact_person = 'John Calambokidis , Brandon Southall';
SA.file_contact_url = 'https://www.cascadiaresearch.org/, https://sea-inc.net/';
X.file_url = '' ;
X.file_doi = '' ;
X.archive_status = 'complete' ;
X.sampling = 'irregular' ;
X.data = [];
X.data_column_name = char(join(all_cols, ',')) ;
X.creation_date = datestr(now,'yyyy/mm/dd HH:MM:SS') ;
X.history = 'photo_archive' ;
PA = orderfields(X) ;
