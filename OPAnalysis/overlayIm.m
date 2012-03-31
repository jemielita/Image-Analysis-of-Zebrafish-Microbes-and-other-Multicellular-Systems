%USAGE: im = overlayIm(imIn, mask)
%
%Function makes regions in mask show up as slightly more red than the rest
%of the image.

function im = overlayIm(imIn, mask)

imIn = mat2gray(imIn);

im = zeros(size(imIn,1), size(imIn,2), 3);

im(:,:,1) = imIn;
im(:,:,2) = imIn;
im(:,:,3) = imIn;

im(:,:,1) = im(:,:,1) + 0.1*mask;

im = mat2gray(im);

end