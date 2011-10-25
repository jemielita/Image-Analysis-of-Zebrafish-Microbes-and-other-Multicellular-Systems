% A GUI to choose a line along which to measure the average change in
% intensity over time
% GUI will be most applicable to measuring spatial and temporal variation
% in gut bacterial populations.


%LineDist(im)
%
%INPUT: im: (optional input) a test image that will be used to find the 
%region that we will create boxes in to find the average pixel intensity.
%
%USAGE:
%-Click the 'Draw Line' button. The user will then be able to draw a line on
%the figure. Once the line is placed another line will be created on the
%image axis, close to the first line placed. The green line can be moved
%around and rotated by the user. The blue line can only be moved
%perpendicular to the green line.
%These two lines define the boundaries of the regions that we will average
%over.

%Note: 
%-The code is a little bit buggy. Move the lines around a little bit,
%even if there initial positioning is perfect, to avoid any problems.
%-
%-Enter in the number of boxes that one wants to find averages for.
%-Press the 'Create Ave. Regions' button. The
%
% Created by: Matthew Jemielita, July 19, 2011



function [LabelMatrix] = LineDist(varargin)


fGUI = figure('Name','Time Evolution along a line', 'Menubar','none', ...
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

hSaveHist = uicontrol('Parent', hManipulate, 'Style', 'pushbutton',...
    'String', 'Save Ave. Regions', 'Units', 'normalized',...
    'Position',[0.1, 1-5*0.16,0.4,0.15],...
    'Callback', {@saveHist});
hCalcHist = uicontrol('Parent', hManipulate,'Style','pushbutton',...
    'String','Calc. Region Props. ','Units', 'normalized',...
    'Position',[0.1, 1-7*0.16,0.4,0.15],...
    'Callback',{@calcProp});
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


LabelMatrix = zeros(1,1); %Label matrix that we'll fill with regions
%that we're going to calculate properties for.
set(fGUI, 'Visible', 'on')

%See if the user has provided an image, if so display it.
if(nargin==1)
    im = varargin{1};
    im = mat2gray(im);
    
    %Display the image of interest, the intensity scale is hardcoded
    %into the code
    hIm = imshow(im, [], 'Parent', axeshandle);
    
    LabelMatrix = zeros(size(im));
    
elseif(nargin>1)
    disp('Too many input parameters! The user only has to provide an image.');
    
end


%%Callback functions

%Load in an image

    function loadImage(source,eventdata)
        %User selects the image to use
        [filename, pathname, filterindex] = uigetfile('.tif', 'Select an Image' );
        
        imInput = strcat(pathname, filesep, filename);
        im = imread(imInput);
        
        %Display the image of interest, the intensity scale is hardcoded
        %into the code
        hIm = imshow(im, [0 500], 'Parent', axeshandle);
        
        LabelMatrix = zeros(size(im));
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
        LabelMatrix(BW==1) = i;
        
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

%Calculate the average in the region of interest
    function calcProp(source,eventdata)
        disp('Calculating regions properies...');
        
        %Get the directory where the scans and images are stored
        rootDir = uigetdir;
        
        %Get the scan and image range to collect data for, along with the
        %root name of the scan folder and images
        
        prompt = {'Enter base name of scan folders: ', ...
            'Enter first scan to process: ', 'Enter last scan to process: ', ...
            'Enter base name of image files: ', 'Enter first image to process',...
            'Enter last image to process'};
        dlg_title = 'Scan and Image information'; num_lines= 1;
        def     = {'scan_','1','', 'image', '1', ''};  % default values
        answer  = inputdlg(prompt,dlg_title,num_lines,def);
        
        %Directory information
        dirNameRoot = char(answer(1));
        dirFirst = str2double(answer(2));
        dirLast = str2double(answer(3));
        
        %Image information
        fileNameRoot = char(answer(4));
        fileFirst = str2double(answer(5));
        fileLast = str2double(answer(6));

        %Going to be clumsy right now, just to get something on paper, this
        %loop should be hard coded for the 
        
        %for i =1:numBoxes
         %  region(i).mean = zeros(130,1);
           
        %end
        
        %Get a location to save the data to
        
        [fileName, pathName, filterIndex] =...
            uiputfile('*.mat' ,'Choose/ create a file to write data to');
        
        saveFile  = strcat(pathName, fileName);
        
        %Save information about the regions used in the calculations
        save(saveFile, 'region');
        
        for j =dirFirst:dirLast
        
          dirname = strcat(rootDir, filesep,dirNameRoot, num2str(j));
          cd(dirname);
          data = zeros(130,numBoxes);
         
          for k=fileFirst:fileLast
              % for k =fileFirst:fileLast
              k
              
              filename = strcat(fileNameRoot, num2str(k), '.tif');
              imIn = imread(filename);
              
              %Calculating the region properties
              b = regionprops(LabelMatrix, imIn, 'MeanIntensity');
              %Clumsily turning this into an array
              
              b
              for i= 1:numBoxes
                  data(k,i) = b(i).MeanIntensity;
                  data(k,i)
              end
              
              
          end
          
          outData(j).Data = data;
          
          save(saveFile, 'outData', '-append')
          
  
          
          
        %save(saveFile, 'data');
          j
        end
        saveFile = 'LineData.mat';
        save(saveFile, 'outData');
       
        disp('Region properties calculated!');
    end
end