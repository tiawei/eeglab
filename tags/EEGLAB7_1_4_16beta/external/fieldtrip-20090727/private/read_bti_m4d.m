function [msi] = read_bti_m4d(filename);

% READ_BTI_M4D
%
% Use as
%   msi = read_bti_m4d(filename)

% Copyright (C) 2007, Robert Oostenveld
%
% $Log: not supported by cvs2svn $
% Revision 1.1  2009/01/14 09:12:15  roboos
% The directory layout of fileio in cvs sofar did not include a
% private directory, but for the release of fileio all the low-level
% functions were moved to the private directory to make the distinction
% between the public API and the private low level functions. To fix
% this, I have created a private directory and moved all appropriate
% files from fileio to fileio/private.
%
% Revision 1.3  2008/11/14 07:49:19  roboos
% use standard matlab strtrim function instead of deblank2
%
% Revision 1.2  2008/08/12 12:56:08  jansch
% fixed assignment of msi.grad. in original implementation only the references were
% stored. in the future this part should be taken care of by bti2grad so that the
% gradiometer references will be correctly handled in the tra-matrix
%
% Revision 1.1  2007/07/03 15:51:46  roboos
% new implementation, only tested on two datasets
%

[p, f, x] = fileparts(filename);
if ~strcmp(x, '.m4d')
  % add the extension of the header
  filename = [filename '.m4d'];
end

fid = fopen(filename, 'r');
if fid==-1
  error(sprintf('could not open file %s', filename));
end

% start with an empty header structure
msi = struct;

% these header elements contain strings and should be converted in a cell-array
strlist = {
  'MSI.ChannelOrder'
  };

% these header elements contain numbers and should be converted in a numeric array
%   'MSI.ChannelScale'
%   'MSI.ChannelGain'
%   'MSI.FileType'
%   'MSI.TotalChannels'
%   'MSI.TotalEpochs'
%   'MSI.SamplePeriod'
%   'MSI.SampleFrequency'
%   'MSI.FirstLatency'
%   'MSI.SlicesPerEpoch'
% the conversion to numeric arrays is implemented in a general fashion
% and all the fields above are automatically converted
numlist = {};

line = '';

msi.grad.label = {};
msi.grad.pnt   = zeros(0,3);
msi.grad.ori   = zeros(0,3);
while ischar(line)
  line = cleanline(fgetl(fid));
  if isempty(line) || (length(line)==1 && all(line==-1))
    continue
  end

  sep = strfind(line, ':');
  if length(sep)==1
    key = line(1:(sep-1));
    val = line((sep+1):end);
  elseif length(sep)>1
    % assume that the first separator is the relevant one, and that the
    % next ones are part of the value string (e.g. a channel with a ':' in
    % its name
    sep = sep(1);
    key = line(1:(sep-1));
    val = line((sep+1):end);
  elseif length(sep)<1
    % this is not what I would expect
    error('unexpected content in m4d file');
  end

  if ~isempty(strfind(line, 'Begin'))
    sep = strfind(key, '.');
    sep = sep(end);
    key = key(1:(sep-1));

    % if the key ends with begin and there is no value, then there is a block
    % of numbers following that relates to the magnetometer/gradiometer information.
    % All lines in that Begin-End block should be treated seperately
    val = {};
    lab = {};
    num = {};
    ind = 0;
    while isempty(strfind(line, 'End'))
      line = cleanline(fgetl(fid));
      if isempty(line) || (length(line)==1 && all(line==-1)) || ~isempty(strfind(line, 'End'))
        continue
      end
      ind = ind+1;
      % remember the line itself, and also cut it into pieces
      val{ind} = line;
      % the line is tab-separated and looks like this
      % A68	0.0873437	-0.075789	0.0891512	0.471135	-0.815532	0.336098
      sep = find(line==9); % the ascii value of a tab is 9
      sep = sep(1);
      lab{ind} = line(1:(sep-1));
      num{ind} = str2num(line((sep+1):end));

    end % parsing Begin-End block
    val = val(:);
    lab = lab(:);
    num = num(:);
    num = cell2mat(num);
    % the following is FieldTrip specific
    if size(num,2)==6
      msi.grad.label = [msi.grad.label; lab(:)];
      % the numbers represent position and orientation of each magnetometer coil
      msi.grad.pnt   = [msi.grad.pnt; num(:,1:3)];
      msi.grad.ori   = [msi.grad.ori; num(:,4:6)];
    else
      error('unknown gradiometer design')
    end
  end
  
  % the key looks like 'MSI.fieldname.subfieldname'
  fieldname = key(5:end);

  % remove spaces from the begin and end of the string
  val = strtrim(val);

  % try to convert the value string into something more usefull
  if ~iscell(val)
    % the value can contain a variety of elements, only some of which are decoded here
    if ~isempty(strfind(key, 'Index')) || ~isempty(strfind(key, 'Count')) || any(strcmp(key, numlist))
      % this contains a single number or a comma-separated list of numbers
      val = str2num(val);
    elseif ~isempty(strfind(key, 'Names')) || any(strcmp(key, strlist))
      % this contains a comma-separated list of strings
      val = tokenize(val, ',');
    else
      tmp = str2num(val);
      if ~isempty(tmp)
        val = tmp;
      end
    end
  end

  % assign this header element to the structure
  msi = setsubfield(msi, fieldname, val);

end % while ischar(line)

fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to remove spaces from the begin and end
% and to remove comments from the lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line = cleanline(line)
if isempty(line) || (length(line)==1 && all(line==-1))
  return
end
comment = findstr(line, '//');
if ~isempty(comment)
  line(min(comment):end) = ' ';
end
line = strtrim(line);
