% boxcarpad.m
%
% program to perform a boxcar smoothing of a 1D array using convolution
% (conv function).  Pads the ends of the array with their mirror images, to
% avoid edge effects in the convolution.  (Of course, the edge points are
% therefore not smoothed in the same way as the body.)
% User specifies boxcar size (Nbox), which also specifies the 'edge' region
%    (Nbox must be an odd integer -- verified)
%
% Raghuveer Parthasarathy
% March, 2004

function [smx] = boxcarpad(x, Nbox)

% make sure Nbox, the boxcar size, is an odd integer
if (mod(Nbox,2)==0), Nbox = round(Nbox+1); end

N = max(size(x));  % size of 1D array x

% create the mirror-padded array padx, of size N + 2*(Nbox-1)
for j=1:(Nbox-1), 
    padx(j) = x(Nbox-j);
    padx(Nbox+N-1+j) = x(N-j+1);
end
for j=1:N, padx(Nbox-1+j) = x(j); end

boxcar = ones(Nbox,1)/Nbox;  % normalized boxcar
tempsmx = conv(padx, boxcar);  
% the convolution has size N + 2*(Nbox-1) + Nbox - 1 = N + 3*Nbox - 3
% keep only the central N points
smx = tempsmx(((Nbox-1)/2 + Nbox) : (N + (Nbox-1)/2 + Nbox - 1));

% make sure smx is not transposed relative to x
if ((size(x,1)>size(x,2))*(size(smx,1)>size(smx,2)) ~= 1)
    smx = transpose(smx);
end