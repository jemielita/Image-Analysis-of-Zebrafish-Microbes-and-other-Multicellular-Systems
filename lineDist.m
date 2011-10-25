% SUMMARY: A GUI to choose a line along which to measure the average change in
% intensity over time
% GUI will be most applicable to measuring spatial and temporal variation
% in gut bacterial populations.
%
%INPUT:
%lineDist(): Opens up a GUI that allows the user to pick an image, and then
%create regions for which to calculate region properties (see USAGE below).
%The user will be prompted for the number of boxes and save location.
%lineDist(im): Same as above, but a particular image will be preloaded.
%lineDist(im, numBoxes): Same as above, but the number of boxes
%used will be preloaded.
%lineDist(im, numBoxes, labelMatrix): Same as above, but the label
%matrix used to find different regions will be preloaded. If this function
%call is used, no GUI will be opened and the program will return the region
%properties for all the regions in the label matrix.
%
%OUTPUT: [labelMatrix, lineProp ]= lineDist(varargin)
%          labelMatrix: contains all the regions that have been selected by
%          the program
%           lineProp: properties of all the regions that correspond to the
%           label matrix used.
% 
%USAGE:
%-Click the 'Draw Line' button. The user will then be able to draw a line on
%the figure. Once the line is placed another line will be created on the
%image axis, close to the first line placed. The green line can be moved
%around and rotated by the user. The blue line can only be moved
%perpendicular to the green line.
%These two lines define the boundaries of the regions that we will average
%over.
% Created by: Matthew Jemielita, July 19, 2011
% Substantial revisons: Matthew Jemielita, October 25, 2011



function [LabelMatrix_LineDist, lineProp] = lineDist(varargin)


global LabelMatrix_LineDist;

LabelMatrix_LineDist = zeros(1,1); %Label matrix that we'll fill with regions
%that we're going to calculate properties for.

%First parse the input variables


if(nargin==3)
    LabelMatrix_LineDist = varargin{3};
elseif(nargin==0)
    global im;  
    LineDistGUI(); %Run the program with the GUI
elseif(nargin==1)
    LineDistGUI(varargin{1});
elseif(nargin==2)
    LineDistGUI(varargin{1},varargin{2});
else
    disp('This program takes at most three arguments!');
    return
    
end

%While the GUI is open, pause this program
while(~isempty(findobj('Tag', 'LineDistGUI')))
    pause(0.5);
    
end

if(nargin==2)
    outputIm  = varargin{1};
else
    outputIm = im;
end
%Calculate the region properties for the selected image
lineProp = regionprops(LabelMatrix_LineDist, outputIm, 'MeanIntensity', 'Centroid');

end

%This GUI provides a way for the user to manually select the regions of
%interest to calculate a line distribution.
function LineDistGUI(varargin)


%Defining globabl variables

slope = 0; %slope of the first line used to find the region of interest
theta = 0; %arctan(slope)

xpos= [0 0]; %Position of first line
ypos= [ 0 0];

xpos2 = [0 0]; %Position of second line
ypos2 = [0 0];

region.position = [0 0;0 0; 0 0; 0 0];
region.mean = 0;

hLine1 = {};
hLine2 = {};


numBoxes = -1;

global LabelMatrix_LineDist;

LabelMatrix_LineDist = zeros(1,1); 


fGUI = figure('Tag', 'LineDistGUI', 'Name','Time Evolution along a line', 'Menubar','none', ...
    'Visible','off','Position',[100,100,1400,800]);
%Create the axis on which the image will be displayed.
axeshandle = axes('Position', [0.05 0.25 0.6 0.6], 'Parent', fGUI);

%Handles to find regions of interest in the image
hManipulate = uipanel('Title','Find Region','FontSize',11,...
'Units',  'normalized', 'Position',[.67 .65 .32 .35]);

%Load in the image that will be used to find the regions that will be
%characterized

hLoadImage   = uicontrol('Parent', hManipulate,'Style','pushbutton',...
    'String','Load Image','Units', 'normalized',...
    'Position',[0.1, 1-0.16*1,0.4,0.15],...
    'Callback',{@loadImage});

%Create the line along which to collect data
hDrawLine    = uicontrol('Parent', hManipulate,'Style','pushbutton',...
    'String','Draw Line','Units', 'normalized',...
    'Position',[0.1, 1-2*0.16,0.4,0.15],...
    'Callback',{@drawLine});
%Create a histogram over the regions bounded by the drawn lines
hCreateHist   = uicontrol('Parent', hManipulate,'Style','pushbutton',...
    'String','Create Ave. Regions','Units', 'normalized',...
    'Position',[0.1, 1-3*0.16,0.4,0.15],...
    'Callback',{@createHist});

%Set the number of boxes to use in the averaging
hSetNumBoxesText = uicontrol('Parent', hManipulate,...
    'Style','text','Units', 'normalized',...
    'String','Number of Boxes: ', 'Fontsize', 8,...
    'Position',[0.01 1-4*0.16 0.28 0.13]);

hSetNumBoxes= uicontrol('Parent', hManipulate, 'style','edit',...
                 'units','normalized',...
                 'position',[0.30 1-4*0.16 0.4 .10],...
                 'fontsize',8,...
                 'string','Number of Boxes', 'Callback',{@setNumBoxes});
  
set(fGUI, 'Visible', 'on')

%See if the user has provided an image, if so display it.
%If the user doesn't provide an image then make im global so that we can
%pass it to the master function

if(nargin==0)
   global im;
end

if(nargin==1 ||nargin==2)
    im = varargin{1};
    im = mat2gray(im);
    
    %Display the image of interest, the intensity scale is hardcoded
    %into the code
    hIm = imshow(im, [], 'Parent', axeshandle);
    
    LabelMatrix_LineDist = zeros(size(im));
end

if(nargin==2)
    numBoxes = varargin{2};
    
    set(hSetNumBoxes, 'String', num2str(numBoxes));
elseif(nargin>2)
    disp('Too many input parameters! The user only has to provide an image.');
    
end


%%Callback functions

%Load in an image

    function loadImage(source,eventdata)
        %User selects the image to use
        [filename, pathname, filterindex] = uigetfile('.tif', 'Select an Image' );
        
        if(filename~= 0)
            imInput = strcat(pathname, filesep, filename);
            im = imread(imInput);
            
            %Display the image of interest, the intensity scale is hardcoded
            %into the code
            hIm = imshow(im, [0 500], 'Parent', axeshandle);
            
            LabelMatrix_LineDist = zeros(size(im));
        end
        
    end

    function drawLine(source,eventdata)
        hLine1 = imline();
        setColor(hLine1, [0 1 0]);
        
        idLine1a = addNewPositionCallback(hLine1,@setSlope);
        idLine1b = addNewPositionCallback(hLine1, @setLine2);
        %Create another line parallel to this line and offset a little bit.
        %We'll use this two lines together to define a region to do our
        %calculations over.
        
        initPos = getPosition(hLine1);
        
        xpos(1) = initPos(1,1);
        xpos(2) = initPos(2,1);
        ypos(1) = initPos(1,2);
        ypos(2) = initPos(2,2);
             
        %Calculate the initial theta
        slope = (ypos(2) - ypos(1))/(xpos(2) - xpos(1));
        theta = atan(slope);
        
        xpos2 = xpos + cos(theta) * 80;
        ypos2 = ypos -sin(theta)*80;
        
        hLine2 = imline( axeshandle, xpos2 , ypos2);
        %Set Constrained position function. Only the second line will be
        %constrained to be parallel to the first line.
        setPositionConstraintFcn(hLine2,@confineLine2)
        
    end

%set the slope and arctan of the slope of the main line
    function setSlope(position)
        
        slope = (position(2,2)-position(1,2))/(position(2,1)-position(1,1));
        theta = atan(slope);
        %Set the position of this line to global memory. This will be used to
        %constrain the other line.
        xpos(1) = position(1,1);
        xpos(2) = position(2,1);
        ypos(1) = position(1,2);
        ypos(2) = position(2,2);
        
    end

    function setLine2(position)
        %When Line 1 is moved, rest Line 2 to be parallel to it.
        
        newPos = confineLine2(getPosition(hLine2));
        setPosition(hLine2, newPos);
    end

    function constrainedPos = confineLine2(position)
      constrainedPos = zeros(2,2);
      
      %Set the position of this line to be a line parallel to line 1, with
      %the same length, where the distance between the lines is given by
      %the magnitude of the distance between the first points of these two
      %lines.
      dist = ((position(1,1) - xpos(1))^2  + (position(1,2) - ypos(1))^2)^0.5;
     
      constrainedPos(:,1) = xpos + sin(theta) * dist;
      constrainedPos(:,2) = ypos - cos(theta)*dist;
     
      xpos2 = constrainedPos(:,1);
      ypos2 = constrainedPos(:,2);     
    end


%Set the number of boxes to be used in making the histogram

    function setNumBoxes(source, eventdata)
      
        user_string = get(source,'String');
        numBoxes = str2num(user_string);   
        
    end
%Create the necessary masks to produce a histogram over the regions we're
%interested in

    function createHist(source,eventdata)
        disp('Creating regions...');
        if(numBoxes == -1)
            disp('Set the number of boxes!');
        end
        
       %Going down the length of the two lines, we'll break the region up
       %into equally spaced regions and calculate statistics (for now just
       %the average pixel intensity) in that region.
       
       length = ((xpos(1) - xpos(2))^2 + (ypos(1) - ypos(2) )^2)^0.5;
      
       xPosLast = [ 0 0];
       yPosLast = [ 0 0];
       
       step = length/ numBoxes;
       
       xPosFirst = [xpos(1) xpos2(1)];
       yPosFirst = [ypos(1) ypos2(1)];
       
 
       %This code is somewhat sensitive to which direction is "up" on the
       %line. Should change the code at some point to make this distinction
       %irrelevant.
       
      
       %Create a mask that will contain the accumulated masks at all steps
       %of the algorithm.
       regionMask = zeros(size(im));
       
       for i=1: numBoxes       
           xPosLast(1)  = xPosFirst(1) + step*cos(theta);
           xPosLast(2)  = xPosFirst(2) + step*cos(theta);
           
           yPosLast(1) = yPosFirst(1) + step*sin(theta);
           yPosLast(2) = yPosFirst(2) + step*sin(theta);
           
           %Updating the structure for this region
           region(i).position = [xPosFirst(1) yPosFirst(1) ; xPosLast(1) yPosLast(1);...
               xPosLast(2) yPosLast(2); xPosFirst(2) yPosFirst(2)];
           
           
           %Creating the label matrix and displaying the regions that we've
           %created.
           hPoly = impoly(axeshandle, region(i).position);
           BW = createMask(hPoly);
           
           %Update the label matrix.
           LabelMatrix_LineDist(BW==1) = i;
           
           %Finding the edges of this mask.
           %Note: The edges of the region seem somewhat choppy because of the
           %edge filter used. To make a solid boundary we'd have to rewrite
           %this a bit.
           
           BWEdge = edge(BW, 'canny');
           
           regionMask(BWEdge) = 1;
           
           %Overlay this mask with the original image
           imRegion = imoverlay(im, logical(regionMask), [1 0 0]);
           
           imshow(imRegion, 'Parent', axeshandle);
           drawnow;
           
           xPosFirst = xPosLast;
           yPosFirst = yPosLast;
           
       end
       
       disp('Regions created!');
    end

end