%Function implements a Canny edge detector
%Usage: [gradImage, thetaImage] = gaussGrad(im, kernelSize, kernelSigma)

function [gradImage, thetaImage] = gaussGrad(im, kernelSize, kernelSigma)
    
im = double(im);

%Create the Gaussian kernel to use for edge detection
gaussKernel = fspecial('gaussian', kernelSize, kernelSigma);
%Calculate the gradient in the x and y direction

%Constructing the roberts derivative kernels
robertsKernelX = [1, 0 ; 0, -1];
robertsKernelY = [0, -1; 1, 0];

sobelX = fspecial('sobel');
sobelY = fspecial('sobel');

prewittY = [-1 -1 -1; 0 0 0;1 1 1];
prewittX = [-1 0 1;-1 0 1;-1 0 1];

%Convolve the gaussian kernel with a derivative filter in the x direction
gaussGradKernel = imfilter(gaussKernel,prewittX);
%Now filter the image with this kernel
gaussImX = imfilter(im, gaussGradKernel);

%And similarly in the y direction
%Convolve the gaussian kernel with a derivative filter in the x direction
gaussGradKernel = imfilter(gaussKernel,prewittY);
%Now filter the image with this kernel
gaussImY = imfilter(im, gaussGradKernel);

%Get magnitude of the gradient
gradImage = sqrt(double(gaussImY).^2 + double(gaussImX).^2);
%And the orientation

thetaImage = atan(double(gaussImX./gaussImY));

%thetaImage will contain NaN at places where gaussImX and gaussImY are 0
%Replace these with 0's-these are places where there is no preferred
%orientation
thetaImage(isnan(thetaImage)) = 0;


end