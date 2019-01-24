% Program:  dog.m
%
% Summary:  Difference of Gaussian filtering for blob detection.  Kernels
%           constructed using fspecial.m.  Only a single convolution is used per
%           kernel, using conv2.m.
%
% Inputs:   im - 2D image array
%           sig1 - stddev of Gaussian 1 (~signal size)
%           sig2 - stddev of Gaussian 2 (~noise)
%           kersize - length of square gaussian kernel in pixels
%
% Outputs:  im_dog - filtered image
%
% Author:   Brandon Schlomann
%
% Date:     March 20, 2018 - First written.
%


function im_dog = dog(im,sig1,sig2,kersize,lkeepsize)

% default parameter values
if ~exist('sig1','var')||isempty(sig1)
    sig1 = 19;
end

if ~exist('sig2','var')||isempty(sig1)
    sig2 = 1;
end

if ~exist('kersize','var')||isempty(kersize)
    kersize = 19;
end

if ~exist('lkeepsize','var')||isempty(lkeepsize)
    lkeepsize = 1;
end

% construct kernels
h1 = fspecial('gaussian',kersize,sig1);
h2 = fspecial('gaussian',kersize,sig2);

% perform convolutions
im1 = conv2(h1,double(im));
im2 = conv2(h2,double(im));

% take difference
im_dog = im2 - im1;

% resize
if lkeepsize
    height = size(im,1);
    width = size(im,2);
    im_dog = imresize(im_dog,[height,width]);
end

end