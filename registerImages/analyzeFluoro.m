%analyzeFluoro: Calculate features of the fluorescence signal for all the
%scans in a given directory
%
%USAGE: [data, param] = analyzeFluoro(data, param, type)
%       For all the scans given in param, construct different types of
%       projections along the z-axis. All the projections made are stored
%       in the subdirectory gutOutline/FluoroScan_scanNum.mat. Where scanNum
%       is an integer giving the current scan. The .mat file contains
%       images of all the different projections for all the colors
%       analyzed.
%
%INPUT: data: unnecessary variable. Should be removed.
%       param: contains all the experimental parameters
%       type: string giving the type of projection to do on the data.
%           'mip': maximum intensity projection
%           'total number': only counts pixels above the threshold given by
%           param.thresh(nColor).
%           'total intensity': sum of all the pixel intensities in the
%           z-direction
%
%OUTPUT: data: no longer used.
%        param: experimental parameters. Currently analyzeFluoro.m doesn't
%        change any elements of param.


function [data, param] = analyzeFluoro(data,param, type)

%For each scan and color calculate all the desired features of the image.

%Preallocate memory for the registered image, and the output images.
im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));

switch lower(type)
    case 'mip'
        imOut.mip = zeros(size(im,1), size(im,2));
    case 'total number'
        imOut.totalNum = zeros(size(im,1), size(im,2));
    case 'total intensity'
        imOut.totalInten = zeros(size(im,1), size(im,2));
    case 'all'
        imOut.mip = zeros(size(im,1), size(im,2));
        imOut.totalNum = zeros(size(im,1), size(im,2));
        imOut.totalInten = zeros(size(im,1), size(im,2));
end    
    
%Create the mask that will be used to outline only the gut
[temp, imMask] = roifill(im, param.regionExtent.poly(:,1), param.regionExtent.poly(:,2));

if strcmp(data,'bpass stack')
    prompt = {'Pixel size of noise: ','Pixel size of object: '};
    dlg_title = 'Filter Options'; num_lines = 1;
    def = {'1','100'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    global Glnoise Globject;
    Glnoise = str2double(answer(1));
    Globject = str2double(answer(2));
end

for nScan=1:param.totalNumberScans
    %Going through each scan
    disp(['Analyzing scan ', num2str(nScan)]);
    for nColor=1:length(param.color)
        disp(['Analyzing color ', num2str(nColor)]);
        %and each color
        %Need to reset imOut for every scan and color
        switch lower(type)
            case 'mip'
                imOut.mip = zeros(size(im,1), size(im,2));
            case 'total number'
                imOut.totalNum = zeros(size(im,1), size(im,2));
            case 'total intensity'
                imOut.totalInten = zeros(size(im,1), size(im,2));
            case 'all'
                imOut.mip = zeros(size(im,1), size(im,2));
                imOut.totalNum = zeros(size(im,1), size(im,2));
                imOut.totalInten = zeros(size(im,1), size(im,2));
        end
        fprintf(2, 'Going through the stack');
        for nZ = 1:size(param.regionExtent.Z,1)
            fprintf(2, '.');
            color = param.color(nColor);
            color = color{1};
            %Load in this registered image
            im = registerSingleImage(nScan, color, nZ, im, data,param);
            
            im = double(im);
            %Apply the mask that outlines only the gut
            %Remove background intensity. In the red channel to background
            %pixel intenisty is ~ 109, while in the green it's 105
            switch nColor
                case 1
                    im = im-105;

                case 2
                    im = im-109;                  
            end
            index = find(im<0);
            im(index) = 0;%Suppress all negative values
                
            im(~imMask) = 0;
            %Calculate the desired features about this image
            
            switch lower(type)
                case 'mip'
                    index = find(im>imOut.mip);
                    imOut.mip(index) = im(index);
                case 'total intensity'
                    imOut.totalInten = imOut.totalInten + im;
                case 'total number'
                    %Only count pixel blocks that are above a certain
                    %threshold-these will be considered to be part of a
                    %certain bacterial population.
                    imOut.totalNum = imOut.totalNum + (im>param.thresh(nColor));
                case 'all'
                    index = find(im>imOut.mip);
                    imOut.mip(index) = im(index);
                    
                    imOut.totalInten = imOut.totalInten + im;
                    
                    index = find(im>param.thresh(nColor));
                    
                    %There must be a non-for-loop way of doing this.
                    for i=1:length(index)
                        imOut.totalNum(index(i)) = imOut.totalNum(index(i)) + 1;
                    
                    end
            end           
        end
        fprintf(2, '\n');
        
    dataOut(nColor) = imOut;
    end
    
    %% Saving the fluorescence data
    %Location that the results of the data will be saved to
    
    fprintf(2, 'Saving the result for this scan...');
    %param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
    cd(param.dataSaveDirectory);
    %And all of the data produced by this scan
    saveName = strcat('FluoroScan_', num2str(nScan), '.mat');
    save(saveName, 'dataOut','-v7.3');
    fprintf(2, 'done!\n');
    
end

end

