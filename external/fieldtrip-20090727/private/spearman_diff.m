function s = spearman_diff(cfg, dat, design)

%SPEARMAN_DIFF computes the difference in rank-correlation 
%coefficient between two variables, between conditions '1'
%and '2' as they are labeled by design 

%The input-data should be formatted as follows:
% first dimension : signals (or signal-combinations)
% second dimension: repetitions
% third dimension : frequencies (optional), or the two signals which will be correlated
% fourth dimension (optional): the two signals which will be correlated
% the last dimension should have length two, since this dimension contains the two variables 
% that are to be rank-correlated

%$Log: not supported by cvs2svn $
%Revision 1.3  2006/10/04 06:59:58  roboos
%renamed th eoption cfg.factor into ivar
%
%Revision 1.2  2006/04/12 12:48:38  roboos
%renamed cfg.randomfactor=>cfg.factor
%
%Revision 1.1  2006/01/05 15:41:36  jansch
%first implementation, to be called by statistics_random.m
%

if ~isfield(cfg, 'factor') & prod(size(design)) ~= max(size(design)),
  error('cannot determine the labeling of the trials');
elseif ~isfield(cfg, 'factor')
  cfg.ivar = 1;
end

nsgn = size(dat,1);
nrpt = size(dat,2);
if length(size(dat))==3,
  nfrq = 1;
  n    = size(dat,3);
else
  nfrq = size(dat,3);
  n    = size(dat,4);
end

if n ~= 2,
  error('the last dimension of the input should be 2');
end

selA = find(design(cfg.ivar, :) == 1);
selB = find(design(cfg.ivar, :) == 2);

%if length(selA) ~= length(selB)
%  error('inappropriate design');
%end
%NONSENSE

for k = 1:nsgn
  for j = 1:nfrq
     datA = squeeze(dat(k, selA, j, :)); %datA = trials x 2
     datB = squeeze(dat(k, selB, j, :)); %datB = trials x 2
     
     [srtA, indA]     = sort(datA); 
     datA(indA(:,1),1) = [1:size(datA,1)]';
     datA(indA(:,2),2) = [1:size(datA,1)]';
     
     [srtB, indB]     = sort(datB); 
     datB(indB(:,1),1) = [1:size(datB,1)]';
     datB(indB(:,2),2) = [1:size(datB,1)]';

     denomA     = size(datA,1) * (size(datA,1)^2-1) / 6;
     rccA(k, j) = 1 - sum(diff(datA, [], 2).^2) / denomA;

     denomB     = size(datB,1) * (size(datB,1)^2-1) / 6;
     rccB(k, j) = 1 - sum(diff(datB, [], 2).^2) / denomB;
  end
end

s = rccA - rccB;

