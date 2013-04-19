%batchMontage: For a given file directory construct a montage of all the
%MIP of images from that stack.
%
% AUTHOR: Matthew Jemielita, April 18, 2013

function [] = batchMontage
%% Variables
% 
% micronToPixel = 0.1625;
% scaleBarWidth = 0.05; %Fraction of image width taken up by scale bar
% 
% montageSpaceWidth = 0.05; %Fraction of final montage taken up by spacing between images.
% %% Loading in montage parameters
% fileDir = uigetdir(pwd, 'Select directory to merge files from');
% 
% prompt = {'Directory structure (* symbol: fish number)',...
%           'Color (Options: r, g, rg, gr)',...
%           'Fish numbers',...
%           'Scale bar size in microns (leave empty if none)',...
%           'Initial intensity for images',...
%           'Final size (height of image in pixels)',...
%           'Crop Image (yes, no)',...
%           'Rotate Image (yes, no)',...
%           'Save Image (yes,no)',...
%           'Scan number to load (Currently only single value)'};
% dlgTitle = 'Parameters for making montage';
% numLines = 1;
% defaultAns = {'fish*',...
%                'rg',...
%                '1:6',...
%                '100',...
%                '',...
%                '1000',...
%                'no',...
%                'yes',...
%                'yes',...
%                '1'};
% answer = inputdlg(prompt, dlgTitle, numLines, defaultAns);
% 
% 
% dirStruct = answer{1};
% colorList = answer{2};
% 
% if(strcmp(answer{3}, 'all'))
%     %Write this code
% else
%     eval(['fishNumbers =' answer{3}]);
% end
% 
% scaleBarSize = str2num(answer{4});
% 
% 
% %Not using this for now
% %eval(['initInten = ',answer{5}]);
% 
% minInten = 0; maxInten = 1000;
% intenLim = zeros(length(fishNumbers), length(colorList),2);
% intenLim(:,:,1) = minInten;
% intenLim(:,:,2) = maxInten;
% 
% finalSize = str2num(answer{6}); finalSize= round(finalSize);
% 
% cropImage = answer{7};
% rotateImage = answer{8};
% saveImage = answer{9};
% scanNum = str2num(answer{10});
% 
% %% Adjust each image independently
% 
% figure;
% 
% 
% for nF = 1:length(fishNumbers)
%     %Replace wildcard in directory structure with this fish nubmer
%     fishStr = [fileDir filesep dirStruct];
%     repNum = regexp(fishStr, '*');
%     fishStr(repNum) = num2str(nF);
%      
%     fishStr = [fishStr filesep 'gutOutline'];
%     
%     %Load in each color
%     for nC=1:length(colorList)
%         switch colorList(nC)
%             case 'r'
%                 thisColor = '568nm';
%             case 'g'
%                 thisColor = '488nm';
%         end
%         imDir = [fishStr filesep 'FluoroScan_', num2str(scanNum), '_', thisColor, '.tiff'];
%         im = imread(imDir);
%         
%         hF = imshow(im);
%         hTitle = title(['Fish: ', num2str(nF), '   color: ', thisColor]);
%         
%         %If contrast has been updated for previous fish in this stack use
%         %this contrast
%         if(nF>2)
%            intenLim(nF,nC,1) = intenLim(nF-1, nC,1);
%            intenLim(nF, nC,2) = intenLim(nF-1, nC,2);
%         end
%         
%         set(gca, 'CLim', [intenLim(nF, nC,1), intenLim(nF, nC,2)]);
% 
%         imcontrast
%        
%         
%         %Rotate the image so that they're lined up correctly
%         if(strcmp(rotateImage, 'yes'))
%            h = imline;
%            rotLine = wait(h);
%            thetaR = atan((rotLine(2)-rotLine(1))/(rotLine(4)-rotLine(3)));
%            theta = 90-rad2deg(thetaR);
%            im = imrotate(im, theta);
%       
%            hF = imshow(im);
%            hTitle = title(['Fish: ', num2str(nF), '   color: ', thisColor]);
%            set(gca, 'CLim', [intenLim(nF, nC,1), intenLim(nF, nC,2)]);
%         end
%         
%         
%         
%         if(strcmp(cropImage, 'yes'))
%             if(nC==1)
%                 %Only need to crop the first frame-assume there's good enough
%                 %overlap for the second one.
%                 [~,rect] = imcrop;
%             end
%             im = imcrop(im,rect);
%             
%         end
%         
%         %Based on crop rectangle, update size of image
%         hF = imshow(im);
%         hTitle = title(['Fish: ', num2str(nF), '   color: ', thisColor]);
%             set(gca, 'CLim', [intenLim(nF, nC,1), intenLim(nF, nC,2)]);
%             
%             
%         if(~isempty(scaleBarSize))
%             %Only need scale bar on one of the two images
%             if(nC==1)
%                     set(hTitle, 'String', 'Set the location for the scale bar! (Upper left corner of bar)');
%                     drawnow;
%                     h = impoint;
%                     scalePos(nF,:) = wait(h);
%                     scalePos(nF,:) = round(scalePos(nF,:));
%                     %Create a mask for the location of the scale bar
%                     scaleMask = zeros(size(im));
%                     
%                     scaleMask(scalePos(nF,2):scalePos(nF,2) + scaleBarWidth*finalSize,...
%                         scalePos(nF,1):scalePos(nF,1)+scaleBarSize/micronToPixel) = 1;
%                     
%                     im = uint16(im) + max(im(:))*uint16(scaleMask);
%                     
%                     hF = imshow(im);hF = imshow(im);
%                     title(['Fish: ', num2str(nF), '   color: ', thisColor]);
%                     set(gca, 'CLim', [intenLim(nF, nC,1), intenLim(nF, nC,2)]);
%                     
%                     hTitle = title(['Fish: ', num2str(nF), '   color: ', thisColor]);
%                     set(gca, 'CLim', [intenLim(nF, nC,1), intenLim(nF, nC,2)]);
%             end
%                     
%         end
%         
%         %Get intensity
%         intenLim(nF, nC,:) = get(gca,'CLim');
% 
%         %Turn image into 8bit
%         %close all
%         im(im>intenLim(nF,nC,2)) = intenLim(nF,nC,2);
%         im = im-intenLim(nF,nC,1); im(im<0) = 0;
%         im = 255*mat2gray(im); im = uint8(im);
%         
%         %Resize image
%         im = imresize(im,  [1000, NaN]);
%         
%         
%         %Saving image to larger stack of images
%         imAll{nF, nC} = im;
%         
%     end
%     
% end
% 
% cd(fileDir)
% save montage.mat;

load('montage.mat');
%% Make montages

allH = cellfun(@(x)size(x,1), imAll, 'UniformOutput', false);
allH = cell2mat(allH);
height = max(allH(:));
allW = cellfun(@(x)size(x,2), imAll, 'UniformOutput', false);
allW = cell2mat(allW);
width = max(allW(:));

imGap = montageSpaceWidth*finalSize;


imFinal = zeros(2*(height+imGap), length(colorList)*width + (length(colorList)-1)*imGap);

%Populating montage 

for nF=1:length(fishNumbers)
    for nC=1:length(colorList)
        
        locX = 1+ (nF-1)*(height+imGap);
        locY = 1+ (nC-1)*(width+imGap);
        imFinal(locX: locX + size(imAll{nF,nC},1)-1, locY:locY+size(imAll{nF,nC},2)-1)=...
            imAll{nF,nC};
    
    end
end
               


end