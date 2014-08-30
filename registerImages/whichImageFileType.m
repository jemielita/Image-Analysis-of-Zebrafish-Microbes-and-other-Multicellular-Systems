
    %Check the save type for a particular image
    
    function  [whichType, imFileName] = whichImageFileType(scanDir, regNum, param, imNum, colorNum)
    imFileNameTiff = ...
        strcat(scanDir,  'region_', num2str(regNum),filesep,...
        param.color(colorNum), filesep,'pco', num2str(imNum),'.tif');
    
    imFileNamePng = ...
        strcat(scanDir,  'region_', num2str(regNum),filesep,...
        param.color(colorNum), filesep,'pco', num2str(imNum),'.png');
    
    typeList = [exist(imFileNameTiff{1}, 'file') exist(imFileNamePng{1}, 'file')];
    
    
    %See if we have a png or tiff type of file. If we
    %have both return an error-we should only have one
    %of these in the directory
    whichType = find(typeList==2, 2);
    if(length(whichType)==2)
        fprintf(2, 'Directory can only contain png or tiff versions of the images!\n');
        whichType = 0;
    end
    
    
    
    switch whichType
        case 1
            imFileName = imFileNameTiff{1};
        case 2
            imFileName = imFileNamePng{1};
    end
            
    
    end