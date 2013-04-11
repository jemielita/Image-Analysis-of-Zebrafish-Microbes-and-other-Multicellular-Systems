function mean = localmean(f, nhood)
%LOCALMEAN Computes an array of local means
% MEAN = LOCALMEAN(F, NHOOD) computes the mean at the center of every
% neighborhood of F defined by NHOOD, an array of zeros and ones where the
% nonzero elements specify the neighbors used in computation of the local
% means. The size of NHOOD  must be odd in each dimension; the default is
% ones(3). Output MEAN is an array the same size as F containing the local
% mean at each point
%
% Taken from digital image processing, Gonzalez and Woods

if nargin==1
    nhood = ones(3)/9;
else
    nhood = nhood/sum(nhood(:));
end
mean = imfilter(double(f), nhood, 'replicate');
end
