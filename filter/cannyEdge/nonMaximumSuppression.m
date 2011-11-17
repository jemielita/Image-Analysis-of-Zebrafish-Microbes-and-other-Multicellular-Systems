%Function to surpress non-local maximum values in edge filtered images
%Something is fucked up with this code...not sure what because it worked
%yesterday.
function [localMax] = nonMaximumSuppression(gradImage, thetaImage)
gradImage = double(gradImage);
thetaImage = double(thetaImage);

%Interpolate the whole image for comparing local maximum
interpIm = interp2(gradImage);

%Calculate the value at each pixel when a unit vector in the direction of
%theta is added to it.
cosTheta = cos(thetaImage);
sinTheta = sin(thetaImage);

%Make an array that contains the pixel index at each point;
posArray = zeros(size(thetaImage,1),size(thetaImage,2),2);

for i=1:size(thetaImage,1)
   posArray(i,:,1) = i; 
end
for i=1:size(thetaImage,2)
    posArray(:,i,2) = i;
end

%Finding it in the direction of the gradient
[X,Y] = meshgrid(1:size(thetaImage,2), 1:size(thetaImage,1));

xInterp=  X+cosTheta;
yInterp =  Y+sinTheta;
interpGradPos = interp2(X,Y,gradImage,xInterp,yInterp);

%Finding it in the direction opposite to the gradient
xInterp=  X-cosTheta;
yInterp =  Y-sinTheta;
interpGradNeg = interp2(X,Y,gradImage,xInterp,yInterp);

%See if the amplitude of the image is greater at the pixel location than at
%the pixels in the direction of the gradient.
localMax = (gradImage>=interpGradNeg).*(gradImage>=interpGradPos);

%For each pixel location, find the value of the pixel closest to the pixel
%in question in the direction of the gradient


localMax = localMax.*gradImage;

end