% Function which...
%
% To do:

function [gutOutline, gutOutlinePoly, gutMiddleTop, gutMiddleBottom, gutMiddlePolyTop, gutMiddlePolyBottom] = obtainMotilityMask(imPath,filetype,resReduce)

%% Read first image
ims=dir(strcat(imPath,filesep,filetype));
info = imfinfo(strcat(imPath,filesep,ims(1).name));
nNumCols = info(1).Height;
nNumRows = info(1).Width;
im=imread(strcat(imPath,filesep,ims(1).name),'PixelRegion', {[1 resReduce nNumCols], [1 resReduce nNumRows]});

% Initialize variables
continueBool = 0;

%% Draw gut outline, gut center
while (continueBool ~= 1)
    
    close all;
    
    % Draw the boundary and gut center. Try to draw the centerline in a way
    % you'd want orthogonal vectors to orient themselves
    figure;
    imH = imshow(histeq(im), []);
    %imC = imcontrast(imH);
    gutOutline = impoly;
    gutOutlinePoly = getPosition(gutOutline);
    setColor(gutOutline, 'red'); 
    gutMiddleTop = impoly('Closed', false);
    gutMiddleBottom = gutMiddleTop;
    gutMiddlePolyTop=getPosition(gutMiddleTop);
    gutMiddlePolyBottom = getPosition(gutMiddleBottom);
    setColor(gutMiddleTop,'green'); 
    setColor(gutMiddleBottom,'green'); 
    
    % Prompt user to see if they want to continue or redraw
    continueBool=menu('Are you satisfied with your drawing?', ...
        'Yes', 'No');
    
    close all;

end

close all;

end