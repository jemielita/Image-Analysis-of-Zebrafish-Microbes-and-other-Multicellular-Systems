% testthresh.m
%
% image: A
% Goal: Graphical User Interface to help
%       (1) Determine the threshold brightness – ignore intensities below this.
%       (2) Determine the "object size" to use for bandpass filtering
% Following Andy Demond’s procedure, thresh is a number between 0 and 1 
%   make a histogram of image intensities (as in fo4.m and fo4_rp.m) and 
%   neglect pixels that fall into the zero-to-thresh fraction of the distribution.
% calls filtthreshimg.m to threshold and filter
% An interactive, iterative function.  Input is a single image, A.  
%   The program asks for a threshold value and shows what the image 
%   looks like if all points below the threshold are black, and a
%   bandpass filter of "objsize" is used.
% The user can iterate and find the threshold and objsize that seem best.
%   These should be noted -- the function does not return them.
% 'Update' when checked, updates the right-side image.  Un-check before
%   exiting!

% April 25, 2007
% Raghuveer Parthasarathy
% last modified: June 29, 2010 -- use filtthreshimg to filter and threshold
%                Aug. 8, 2010 -- fixes GUI format issues

function testthresh(A)
% A nested function


%  Initialize and hide the GUI as it is being constructed.
fGUI = figure('Name','Threshold Testing', 'Menubar','none', ...
    'Visible','off','Position',[100,100,1000,800], 'Color', [0.7 0.3 0]);

% Construct the components.
% Create axes, for the images
buttonheight = 30; 
hsig = uicontrol('Style','text',...
    'String','testthresh.m -- 2007, R. Parthasarathy',...
    'FontWeight', 'bold', 'Position',[875,50,115,30]);
% Initialization
hupdate    = uicontrol('Style','checkbox',...
    'String','Update','FontWeight', 'bold', 'Units', 'normalized', ...
    'Position',[0.460,765/800,0.065,buttonheight/800],'value', 0, ...
    'Callback',{@update_Callback});
hjet    = uicontrol('Style','checkbox',...
    'String','Jet','FontWeight', 'bold', 'Units', 'normalized', ...
    'Position',[0.535,765/800,0.040,buttonheight/800],'value', 0, ...
    'Callback',{@jet_Callback});
hthreshtextinit = uicontrol('Style','text',...
    'String','threshold (0-1)', 'FontWeight', 'bold', 'Units', 'normalized',...
    'Position',[0.585,780/800,0.085,15/800]);
hthreshtext  = uicontrol('Style','edit',...
    'String','thresh', 'Units', 'normalized', ...
    'Position',[0.675,780/800,0.040,15/800], ...
    'Callback',{@threshtext_Callback});
hthresh = uicontrol('Style','slider', ...
    'Max', 0.9999, 'Min', 0.01, 'Value', 0.5, ...
    'SliderStep', [0.02 0.1], 'Units', 'normalized',...
    'Position', [0.720,780/800,0.140,15/800], ...
    'Callback',{@thresh_Callback});
hobjsizetextinit = uicontrol('Style','text',...
    'String','objsize (px)', 'FontWeight', 'bold', ...
     'Units', 'normalized', 'Position',[0.585,755/800,0.085,15/800]);
hobjsizetext  = uicontrol('Style','edit',...
    'String','objsize',  'Units', 'normalized', ...
    'Position',[0.675,755/800,0.040,15/800], ...
    'Callback',{@objsizetext_Callback});
hobjsize = uicontrol('Style','slider', ...
    'Max', 50, 'Min', 2, 'Value', 2, ...
    'SliderStep', [0.02 0.1],  'Units', 'normalized',...
    'Position', [0.720,755/800,0.140,15/800], ...
    'Callback',{@objsize_Callback});
hexit    = uicontrol('Style','pushbutton',...
    'String','Exit',  'Units', 'normalized',...
    'Position',[0.875,765/800,0.115,30/800],...
    'Callback',{@exit_Callback});
% Messages
hmsg    = uicontrol('Style','text',...
    'String','Message: ', 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left',  'Units', 'normalized', ...
    'Position',[0.050,780/800,0.400,15/800]);


% Initialize the GUI.
% Change units to normalized so components resize automatically.
set([fGUI, hupdate, hjet, hsig, hthreshtextinit, hthresh, hthreshtext, ... 
    hobjsizetextinit, hobjsizetext, hobjsize, hexit, hmsg], ...
    'Units','normalized');

% Create all variables here
thresh = 0.9;
objsize = 4;
A = double(A);
showlive = 0;
cmap = colormap('gray');

% Move the GUI to the center of the screen.
movegui(fGUI,'center')
% Make the GUI visible.
set(fGUI,'Visible','on');
figure(fGUI);
set(hthreshtext, 'String', sprintf('%.4f', thresh));
set(hthresh, 'Value', thresh);
set(hobjsizetext, 'String', sprintf('%d', objsize));
set(hobjsize, 'Value', objsize);
subplot(1,2,1)
imagesc(A);
colormap('gray');
title('Original image');
subplot(1,2,2)
colormap('gray');
imagesc(A);

% Callback functions


    function update_Callback(source,eventdata)
        % Show thresholded and filtered image
        showlive = get(source,'Value');
        while showlive==1
            % h = bpfilter(floor(objsize/2));
            % filtimg = imfilter(A, h, 'replicate'); % bandpass filter
%             filtimg = bpass(A,1,objsize);  % Use Grier et al. bandpass filter
%             [hs, bins] = hist(filtimg,100);
%             ch = cumsum(hs);
%             ch = ch/max(ch);
%             noiseind = find(ch > thresh); %
%             noiseind = noiseind(2); % The index value below which "thresh" fraction
%             % of the pixels lie
%             threshA = filtimg.*(filtimg > bins(noiseind));
            title(strcat('Thresholded and filtered: ', num2str([thresh objsize])));
            subplot(1,2,2); imagesc(filtthreshimg(A, objsize, thresh)); colormap(cmap);
            set(hmsg, 'String', sprintf('Threshold %.4f, objsize %d', thresh, objsize));
            pause(0.2)
        end
    end

    function jet_Callback(source,eventdata)
        % If checked, use the "jet" colormap; else "gray"
        jetopt = get(source,'Value');
        if jetopt
            cmap = colormap('jet');
        else
            cmap = colormap('gray');
        end
    end

    function threshtext_Callback(source,eventdata)
        % set thresh (text entry)
        thresh = str2double(get(source,'string'));
        set(hthresh, 'Value', thresh);
    end

    function thresh_Callback(hObject, source,eventdata)
        thresh = get(hObject,'Value');
        % Also update text entry box:
        set(hthreshtext, 'String', sprintf('%.4f', thresh));
    end

    function objsizetext_Callback(source,eventdata)
        % set objsize (text entry)
        objsize = round(str2double(get(source,'string')));
        set(hobjsize, 'Value', objsize);
    end

    function objsize_Callback(hObject, source,eventdata)
        objsize = round(get(hObject,'Value'));
        % Also update text entry box:
        set(hobjsizetext, 'String', sprintf('%d', objsize));
    end

    function exit_Callback(source,eventdata)
        % Exit
        if get(hupdate, 'Value')==1
            set(hmsg, 'String', 'UNCHECK the update box before exiting!');
            pause(0.6)
        else
            close all;
        end
    end

end
