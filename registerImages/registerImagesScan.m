%Goes through the entire scan and calculates the overlaped regions and
%allows the user to draw a bounding polygon around each region.




function  registerImagesScan(data,param)

im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));

%Data structure to save position
polyPosition = cell(length([param.regionExtent.Z]),1);
position = '';

%Going through each scan
for nScan = param.scans(1):param.scans(end)
    
    
    %And each color
%   for nColor =1:length(param.color)
        
nColor = 1;
        %And each z level
        h = waitbar(0, 'Constructing registered stack...');
        
        for zNum=1:size([param.regionExtent.Z])
        waitbar(zNum/length([param.regionExtent.Z]),h);    
            
            colorType = param.color(nColor);
            colorType =colorType{1};%Removing it from the cell.
            
            im = registerSingleImage(nScan, colorType, zNum, im, data,param);
            
            %Displaying the result
            imshow(im, [ 0 1000]);

        end
        clear h;
        
 %   end
    
    
end

end