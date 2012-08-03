% imagebinRP.m
% Averages 2D image into "bins" of mxm pixels, i.e. rescaling by 1/m
%   If N is not an integer multiple of m, ignore "remainder" pixels at
%   right, bottom edges
% Similar to imresize, but more reliable since avoids "unknown" filtering
% Inputs: 
%   A = input image (can be double, uint8, or uint16); 2D or 3D.  If
%       3D, *bin each 3D slice* (no binning in "z")
%   binsize = bin size (forced to be integer)
%
% Raghuveer Parthasarathy
% August 17, 2007
% January 26, 2012: Allow binning of each slice of a 3D image
% last modified  January 26, 2012

function Anew = imagebinRP(A, binsize)

binsize = round(binsize);  % force to be integer
imclass = class(A);  % Determine the image class
A = double(A);

N = size(A);
Ndim = length(N);  % number of dimensions
if Ndim==3
    Nz = N(3); % number of slices
else
    Nz = 1;
end
Nnew = [floor(N(1)/binsize) floor(N(2)/binsize)];  % size of 2D images
Anew2D = zeros(Nnew);
Anew = zeros([Nnew Nz]);
for q = 1:Nz
    for j=1:Nnew(1)
        for k=1:Nnew(2)
            Abox = A((j-1)*binsize+1:(j*binsize),(k-1)*binsize+1:(k*binsize),q);  % pixels of A
            Anew2D(j,k) = mean(Abox(:));  % This is the slowest part
        end
    end
    Anew(:,:,q) = Anew2D;
end

if strcmp(imclass, 'uint8')       % 8-bit image (0-255)
    Anew = uint8(Anew);
elseif strcmp(imclass, 'uint16')  % 16-bit image (0-65535)
    Anew = uint16(Anew);
end
