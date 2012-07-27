%USAGE: im = overlayIm(imIn, mask)
%
%Function makes regions in mask show up as slightly more red than the rest
%of the image.

function im = overlayImage(varargin)

if nargin==2
    imIn = varargin{1};
    mask = varargin{2};
    
    imIn = mat2gray(imIn);
    
    im = zeros(size(imIn,1), size(imIn,2), 3);
    
    im(:,:,1) = imIn;
    im(:,:,2) = imIn;
    im(:,:,3) = imIn;
    
    im(:,:,1) = im(:,:,1) + 0.1*mask;
    
    im = mat2gray(im);
end

if nargin==4
    imIn = varargin{1};
    mask1 = varargin{2};
    mask2 = varargin{3};
    mask3 = varargin{4};
    
    imIn = mat2gray(imIn);
    
    im = zeros(size(imIn,1), size(imIn,2), 3);
    
    im(:,:,1) = imIn;
    im(:,:,2) = imIn;
    im(:,:,3) = imIn;
    
    
    %Regions that are in mask2 are blue (even if mask1 is also in that
    %region)
    mask1(mask2>0) = 0;
    mask1(mask3>0) = 0;
 
    im(:,:,1) = im(:,:,1) + 0.1*mask1;
    im(:,:,3) = im(:,:,3)  + 0.1*mask3;
    im(:,:,2) = im(:,:,2) + 0.1*mask2;
    im = mat2gray(im);
    
    
    
end
end