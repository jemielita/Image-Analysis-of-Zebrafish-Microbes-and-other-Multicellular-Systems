%For an input giving the range of scans, regions, and colors to analyze,
%construct a structure that can store all the data we'll collect.
%
%NOTE: still needs to be tested more carefully for 

function data = initializeLineDistStruct(param)

%Get the directory that we're working out of.

dirName = param.directoryName;
data.directory = dirName;

%Then construct an array that contains all the scans that we're interested
%in analyzing.

scanNumber = param.scans;

if(strcmp(scanNumber,'all'))
   %Get the total number of scans in this folder
   checkScan = strcat(dirName, filesep, 'scan_*');
   numScans = length(dir(checkScan));
   
   %Potentially dangerous assumption, but we'll assume that the scans are
   %sequentially ordered, with none deleted.
   for i=1:numScans
       data.scan(i).directory = strcat('scan_', num2str(i));
   end
else
    for i=1:length(param.scans)
       data.scan(i).directory = strcat('scan_', num2str(param.scans(i) ));
    end
end


%For each of these scans constructed a sub-structure for each region and
%color requested.

for i=1:length(data.scan)
    
    if(strcmp(param.regions, 'all'))
        checkRegions = strcat(dirName, filesep,data.scan(i).directory,...
            filesep,'region_*');
        numRegions = length(dir(checkRegions));
        
        for j=1:numRegions
            data.scan(i).region(j).directory = strcat('region_', num2str(j));
        end
        
    else
        for j=1:length(param.regions)
            data.scan(i).region(j).directory =...
                strcat('region_', num2str(param.regions(j)));
        end
    end
    
    
    for j=1:length(data.scan(i).region)
        
        if(strcmp(param.color, 'all'))
            colorRegions = strcat(dirName, filesep, data.scan(i).directory,...
                filesep, data.scan(i).region(j).directory, filesep,...
                '*nm');
            colors =  dir(colorRegions);
            
            for k =1:length(colors)
                data.scan(i).region(j).color(k).name = colors(k).name;
                data.scan(i).region(j).color(k).im = zeros(2160,2560);
                %The size above should probably be a user-defined
                %parameter, but this is the upper bound of array sizes we
                %should expect-so if anything we're overallocating memory.
                %This is also potentially dangerous if we're working on a
                %computer with not a lot of memory.
               
                colorDirName = strcat(dirName, filesep,...
                    data.scan(i).directory, filesep, ...
                    data.scan(i).region(j).directory, filesep,...
                colors(k).name, filesep);
                data.scan(i).region(j).color(k).directory = colorDirName;
            end
            
        else
            %Write this part of the code
        end
    end
    

end



end