%Calculate features of the fluorescence signal for all image stacks
%produced.

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

for nScan=1:length(data.scan)
    %Going through each scan
    
    for nColor=1:length(param.color)
        %and each color
        
        for nZ = 1:size(param.regionExtent.Z,1)
            
            color = param.color(nColor);
            color = color{1};
            %Load in this registered image
            im = registerSingleImage(nScan, color, nZ, im, data,param);
            
            im = double(im);
            %Apply the mask that outlines only the gut
            im(~imMask) = 0;
            %Calculate the desired features about this image
            
            switch lower(type)
                case 'mip'
                    imOut.mip(im>imOut.mip) = im;
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
        %Normalizing the total intensity and the maximum intensity
        %projection by the intensity of a single bacteria
        imOut.totalInten = imOut.totalInten/param.thresh(nColor);
        imOut.mip = imOut.mip/param.thresh(nColor);
        data.scan(nScan).allReg.color(nColor).intenData = imOut;

    end
end

end

