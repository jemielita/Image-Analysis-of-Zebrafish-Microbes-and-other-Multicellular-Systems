% binavg.m
% 
% -------------------------------------------
% NOTE: Probably an unnecessary function -- can use histc and accummarray
%   see
%   http://blogs.mathworks.com/videos/2009/01/07/binning-data-in-matlab/
%   (and comments)
%   and the averaging function at the end of getGUVgradientedge.m
%   Raghu, Dec. 10, 2012
% -------------------------------------------
%
% Function to bin elements of each row of array, based on bins defined for
%   the first row.  Returns the mean and standard deviation of the values
%   in each bin, and the number of points (histogram).
% Ignores NaN elements of the input array in calculating mean, std
% Returns the mean and standard deviations of values that fall into each bin.
% For example, input array A can have row 1 be position values, x, and
%    the other rows be quantities depending on x:
%    A = [x1  x2  x3  ... xN ;
%         y11 y12 y13 ... y1N;
%         y21 y22 y23 ... y2N;
%         ...
%         yM1 yM2 yM3 ... yMN;
%    size(A) = [M+1 N] -- M=number of 'y's (can be zero), N = number of x pts.
%    Sort x's into bins and average within each bin, and also sort and
%        average the y's that correspond to those binned x's.
%
% Inputs:
%  A     - array of points to assign into bins -- see above
%
%  binlb - list of lower bounds of bins for x in increasing order.
%          (As in bindex.m.) 
%          The last element in this vector is the upper bound
%          of the last bin.
%          The number of bins is therefore nbins = length(binlb)-1.
%          NOTE: this vector must be sorted in increasing order.
%          I do not test for this property.
%
% Outputs:
%  mx    - mean value in each bin for each row (size M+1 rows x nbins columns)
%         If no x's fall into a bin, return NaN for the mean of that bin
%  std   - standard deviation of x values in each bin (size M-1 rows x nbins
%         columns)
%         If no x's fall into a bin, return NaN for the std of that bin
%  nx    - number of points (in each row) that contributed to each bin
%         (size 1 x nbins).  Note that nx provides a *histogram* of the
%         data.
%  ind   - array of indicies of the bin into which x fell (size 1 x N)
%  outN  - number of points of x that fall outside the range of the bins (i.e. <
%         binlb(1) and > binlb(end)) -- a number
%
% Uses "loop over bins" (Method 2) approach of bindex.m by John R. D'Errico
% Some syntax is also from this function.
% First creates array ind (same size as input x) that identifies which bin
% each element of x falls into.
%
% Raghuveer Parthasarathy
% June 3, 2007
% last modified Sept. 16, 2007 (ignore NaN)

function [mx, stdx, nx, ind, outN] = binavg(A, binlb)

binlb=binlb(:);
nbins=length(binlb)-1;
x=A(1,:);

if or((nbins<1),isempty(x))
  ind=[];
  mx = [];
  stdx = [];
  nx = [];
  outN = [];
  return
end

ind=zeros(1,length(x));
for j=1:nbins+1
    ind=ind+(x>=binlb(j));
end

mx   = zeros(size(A,1),nbins);
stdx = zeros(size(A,1),nbins);
nx = zeros(1,nbins);
for j=1:size(A,1)
    r = A(j,:);  % elements of row j
    for k = 1:nbins,
        rk = r(ind==k);
        nx(k) = sum(ind==k);
        if and(~isempty(rk),sum(~isnan(rk)>0))  % not empty, and not all NaN
            mx(j,k) = mean(rk(~isnan(rk)));
            stdx(j,k) = std(rk(~isnan(rk)));
        else
            mx(j,k) = NaN;
            stdx(j,k) = NaN;
        end
    end
end
outN = sum(ind==0) + sum(ind==max(binlb));
