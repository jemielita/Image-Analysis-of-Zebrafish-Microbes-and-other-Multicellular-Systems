%Function to cycle through a series of tiff images


function [rect] = cropGUI(varargin)
if nargin==1
    imDir = varargin{1};
    loadSeries = 1;
    nameRoot = '';
elseif nargin==0
    imDir = uigetdir();
    loadSeries = 1;
    nameRoot = '';
elseif nargin ==2
    imDir = varargin{1};
    nameRoot = varargin{2};
    loadSeries = 0;
else
    disp('Function requires either 0 or 1 inputs!');
    return
end

cropGUIinternal(imDir, loadSeries, nameRoot);

 while(~isempty(findobj('Tag', 'cropGUI')))
            handles = findobj('Tag', 'cropGUI');
            paramTemp = guidata(handles);
            rect = paramTemp.rect;
            pause(0.5);
 end
        


end

function [] = cropGUIinternal(imDir, loadSeries, nameRoot)


h_fig = figure;

set(h_fig, 'tag', 'cropGUI');
myhandles = guihandles(h_fig); 

myhandles.rect = [];
guidata(h_fig,myhandles)

%Variables to let us know where we are in the image stacks
scan = 1;

minN = 0;
maxN = 50;

minScan = 1;
maxScan = 146;
color = '488nm';
region = 'region_1';

index = 1;

if loadSeries ==1
fN = [imDir, filesep, 'scan_',num2str(scan), filesep,region,...
    filesep, color, filesep, 'pco', num2str(index), '.tif'];
im = imread(fN);
else
    fN = [imDir, filesep, nameRoot, sprintf('%03d', 1), '.TIF'];
    im = imread(fN, 1);
end
hIm = imshow(im,[]);


imcontrast;
set(h_fig,'KeyPressFcn',{@key_Callback,h_fig});

hRect = [];
    function key_Callback(varargin)

        val = varargin{1,2}.Key;

        switch val
            case 'leftarrow'
                %The left arrow key was pressed
                if(index~=minN)
                    index = index-1;
                end
            case 'rightarrow'
                %The right arrow key was pressed
                if(index~=maxN)
                    index = index+1;
                end
            case 'downarrow'
                if(scan~=minScan)
                    scan = scan-1;
                end
                title(num2str(scan));
            case 'uparrow'
                if(scan~=maxScan)
                    scan = scan+1;
                end
                title(num2str(scan));
            case 'c'
                hRect = imrect;
                
                
            case 'return'
                hApi = iptgetapi(hRect);
                
                try
                    rect= hApi.getPosition();
                    myhandles.rect = rect; 
                    guidata(h_fig,myhandles) 
                    title('Cropping rectangle saved!');
                catch
                    title('Rectangle hasnt been clicked on!');
                end
                
                
                   
              
               
        end
        if loadSeries ==1
            fN = [imDir, filesep, 'scan_',num2str(scan), filesep,region,...
                filesep, color, filesep, 'pco', num2str(index), '.tif'];
            im = imread(fN);
        else
            fN = [imDir, filesep, nameRoot, sprintf('%03d', scan), '.TIF'];
            im = imread(fN, index);
        end
        
        
        set(hIm, 'CData', im);
                    
        
        
        
    end

end