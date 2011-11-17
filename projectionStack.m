%Calculates a projection for each of the stack of scans given in the input
%data.
%Currently there is only support for maximum intensity projection, but
%other types of projections can be added later.

function data = projectionStack(data, param, projectionType)

%For the workbar
wNum = 1;

for nScan=1:length(data.scan)
    %Going through each scan
    for nRegion=1:length(data.scan(nScan).region)
        %Going through each region in this scan
        for nColor=1:length(data.scan(nScan).region(nRegion).color)
            %and each color
            
            %Progress bar
            mess = strcat('Scan ',...
                num2str(nScan), ', region ', num2str(nRegion), ', color ',...
                num2str(nColor), '.');
            mess
            workbar(wNum/param.numIm, mess, 'Calculating maximum intensity projections...');
            wNum = wNum +1;
            
            %Get the number of scans in this folder.
            %In the future we should add in support to limit the upper and
            %lower bounds.
            imFiles = strcat(data.scan(nScan).region(nRegion).color(nColor).directory, 'pco*.tif');
            numIm = length(dir(imFiles));
            
            imDir = data.scan(nScan).region(nRegion).color(nColor).directory;
            
            %Calculating a projection for this particular stack
            switch lower(projectionType)

                case 'mip'
                    
                    for i=param.minImage:param.maxImage
                        imName = strcat (imDir, 'pco', num2str(i), '.tif');
                        im = imread(imName);
                        
                        index = find(im>data.scan(nScan).region(nRegion).color(nColor).im);
                        data.scan(nScan).region(nRegion).color(nColor).im(index)= im(index);
                        
                        disp(imName);
                    end
                    
                otherwise
                    
            end

        end
    end
end


end