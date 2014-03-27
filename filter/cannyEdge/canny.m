%canny: Implements the Canny filter.
%
% USAGE edgeIm = canny(im, kernelSigma, findEdges)
%
% INPUT im: image to filter
%       kernelSigma: standard deviation of gaussian kernel used in canny
%       filter.
%       findEdges: (default: false) If false then only return the gradient
%       of the original image. If true then further filter the image to
%       find only the edges. If true the code will supress non-maximal
%       values in the gradient of the image and then clean up the edges
%       using a hysteresis threshold.
%
% OUTPUT edgeIm: if findEdges = true, this returns a logical mask giving the
%         predicted edges of the images. If findEdges = false, this returns
%         the gradient of the input image(type double,max val 1)
% AUTHOR Matthew Jemielita

function edgeIm = canny(im, kernelSigma, varargin)

switch nargin
    case 2
        findEdges = false;
    case 3
        findEdges = varargin{1};
    otherwise
   fprintf(2, 'Function takes either 2 or 3 inputs!\n');     
end
        
im = mat2gray(im);

kernelSize = ceil(7*kernelSigma);
%First compute the gradient of the image
[gradImage, thetaImage] = gaussGrad(im,kernelSize, kernelSigma);

if(findEdges==false)
   edgeIm = mat2gray(gradImage);
   return;
end


%Then surpess non-local maximum
%figure; imshow(gradImage, [])
[localMax] = nonMaximumSuppression(gradImage, thetaImage);

%figure; imshow(localMax);

%Then clean up edges beyond the hysteresis threshold
highThresh = graythresh(localMax);
lowThresh = (0.3)*highThresh;
hIm = hysThreshold(localMax, highThresh, lowThresh);


edgeIm = hIm;

end