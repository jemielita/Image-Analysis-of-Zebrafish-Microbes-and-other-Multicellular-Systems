%Implements the Canny filter

function edgeIm = canny(im, kernelSigma)
im = mat2gray(im);

kernelSize = ceil(7*kernelSigma);
%First compute the gradient of the image
[gradImage, thetaImage] = gaussGrad(im,kernelSize, kernelSigma);

%Then surpess non-local maximum
%figure; imshow(gradImage, [])
[localMax] = nonMaximumSuppression(gradImage, thetaImage);

%Then clean up edges beyond the hysteresis threshold
highThresh = 1.25*graythresh(localMax);
lowThresh = (0.6)*highThresh;
hIm = hysThreshold(localMax, highThresh, lowThresh);


edgeIm = hIm;

end