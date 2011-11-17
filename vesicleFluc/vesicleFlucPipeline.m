%Pipeline for analyzing vesicle fluctuations.
%Currently testing the use of edge finding and interpolation to get more
%data points.


%% Loading in an image

im = imread('1a5ms200fps_0988.tif');

%Cropping it
rect = [221.5100   77.5100  117.9800  101.9800];
im = imcrop(im, rect);


%% Using a canny filter on the image.

%Consider seeing what happens if a bilateral filter is used.

imC = canny(im,2);

%This is ad-hoc-needs to be fixed in the future.
imC = bwareaopen(imC, 40);

%% Calculate properties of the vesicle
    %(to be used for vesicle rigidity measurements)
    numTheta = 100;
    guv = vesicleProp(imC, numTheta);


    %% Plot the result
    imagesc(im);
    colormap gray
    hold on
    plot((guv.R).*cos(guv.phi)+ guv.ctr(1), guv.ctr(2) + (guv.R).*sin(guv.phi), 'xy');
%% Calculate the autocorrelation function
  xi = autocorrGUV(guv);