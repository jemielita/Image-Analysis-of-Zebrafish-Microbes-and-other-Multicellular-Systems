%Display the images from two different colors.
%USAGE: display2Color(im): Display the result of the two colors on top of
%each other. Note: im is an N X M X 3 grayscale image.
%       display2Color(im, '2Panel'). Displays the results on two separete
%       panels
%       display2Color(im, '2Panel', 'draw'). Displays the result in two
%       separate panels and makes it possible to draw  a bounding box on
%       either image that gets mirrored on the other images. Useful for
%       outlining regions of interest in both colors.
%Other features will be added (or stolen from the internet) as necessary
function poly = display2Color(imColor, panelType, polyOutput)

imColor = mat2gray(imColor); %If not done already, make the range of pixel intensities 0-1.






end