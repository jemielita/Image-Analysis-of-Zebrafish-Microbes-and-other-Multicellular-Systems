%Function to cycle through a series of tiff images


function [rect] = cropGUI(varargin)
if nargin==1
    imDir = varargin{1};
elseif nargin==0
    imDir = uigetdir();
else
    disp('Function requires either 0 or 1 inputs!');
    return
end

cropGUIinternal(imDir);

 while(~isempty(findobj('Tag', 'cropGUI')))
            handles = findobj('Tag', 'cropGUI');
            paramTemp = guidata(handles);
            rect = paramTemp.rect;
            pause(0.5);
 end
        


end

function [] = cropGUIinternal(imDir)


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
maxScan = 144;
color = '488nm';
region = 'region_1';

index = 1;

fN = [imDir, filesep, 'scan_',num2str(scan), filesep,region,...
    filesep, color, filesep, 'pco', num2str(index), '.tif'];
im = imread(fN);
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
            case 'uparrow'
                if(scan~=maxScan)
                    scan = scan+1;
                end

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
        fN = [imDir, filesep, 'scan_',num2str(scan), filesep,region,...
            filesep, color, filesep, 'pco', num2str(index), '.tif'];
            titleV = ['scan: ', num2str(scan), '   index: ', num2str(index)];
            title(titleV);
        im = imread(fN);
        
        set(hIm, 'CData', im);
                    
        
        
        
    end

end