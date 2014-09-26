classdef bacVideo
 %Analysis of a single video of bacterial motility in the gut.   
    properties
        frameRate = NaN;
      
        vidLoc = NaN;
        vidName = NaN;
        vidMinS = NaN;
        vidMaxS = NaN;
        vidSaveType = NaN;
        
        vid = NaN;
        
        gutMaskPoly = NaN; %This is the crude outline drawn by hand over all frames.
        numFrames = NaN;
                  
        foundSpots = NaN;
        minObjSize = 20;
        
        saveDir = '';
        saveName = '';
        
        spotList = NaN;
        imageSaveLoc = '';
        imageSaveType = '';
        
        %xyz location of the video taken, will be used to orient ourselves
        %when doing our analysis.
        location = [NaN, NaN, NaN]; 
    end
    
    methods
        function obj = bacVideo(loadType, varargin)
            
           switch loadType
               
               case 'dir'
                   fileDir = varargin{1};
                   fileName = varargin{2};
                   fileType = varargin{3};
                   minS = varargin{4};
                   maxS = varargin{5};
                   
                   obj.vidLoc = fileDir;
                   obj.vidName = fileName;
                   obj.vidMinS = minS;
                   obj.vidMaxS = maxS;
                   obj.vidSaveType = fileType;
                  
                    obj = loadVideo(obj);
               case 'video'
                   vid = inputVal;
                   %Need to incorporate auto-generation of this file within our
                   %current code framework.
                   obj.vid = vid;
                   
           end
           obj.numFrames = size(obj.vid,3);
           
           obj.foundSpots = cell(obj.numFrames,1);
        end
        
        function obj = saveImageStack(obj)
            n =1;
            fprintf(1, 'Saving image stack');
            for ns = obj.vidMinS:obj.vidMaxS
                fprintf(1, '.');
                fileName = [obj.vidLoc filesep obj.vidName num2str(ns) '.' obj.vidSaveType];
                
                imwrite(uint16(obj.vid(:,:,n)), fileName);
                
                n = n+1;
            end
            fprintf(1, '\n');
        end
        
        function obj = setSaveLocation(obj, saveDir, saveName)
           %Should default to saveName = 'bacVideo.mat';
           
           obj.saveDir = saveDir;
           fprintf(1, ['Save directory set to: ', obj.saveDir, '\n']);
           
           obj.saveName = saveName;
           fprintf(1, ['Save name set to: ', obj.saveName, '\n']);
                     
        end
            
        function displayVideo(obj, varargin)
            % displayVideo('show spots'):Show bacterial video. If string
            % 'show spots' is passed in the found spots will also be shown.
            if(isnan(obj.frameRate))
               pauseTime = 0.030; 
            else
                pauseTime = 1/frameRate;
            end
            
            if(nargin>1)
                argList = varargin{1};
                
            else
               argList = {}; 
            end
            
            figure;
            hIm = imshow(obj.vid(:,:,1),[0 30000]);
            hold on
            hP = displaySpots(argList,1,'' );

            for nS=2:obj.numFrames
                displaySpots(argList,nS,hP);
                set(hIm, 'CData', obj.vid(:,:,nS));
                
                pause(pauseTime);
            end
            
            
            function spotHandle = displaySpots(argList,nS, spotHandle)
               if(sum(ismember(argList,'show spots'))>1)
                   
                   if(nS==1)
                       spotHandle = plot(obj.foundSpots{nS}(1,:),...
                           obj.foundSpots{nS}(2,:), 'o', ...
                           'Color', [0.7, 0.2 0.2]);
                   else
                       set(spotHandle, 'XData', obj.foundSpots{nS}(1,:));
                       set(spotHandle, 'YData', obj.foundSpots{nS}(2,:));
                   end
                   
               end
            end
            
        end
        
        function obj = findSpots(obj)
            if(nargout==0)
               fprintf(2, 'Need to pass this to a instance of bacVideo!\n');
               return;
            end
            fprintf(1, 'Finding putative bacteria in video');
            for nS=1:obj.numFrames
               %[obj.vid(:,:,nS),im] = spotDetector(obj.vid(:,:,nS));
               
              
               %Cleaning up our spots some more
               im = obj.vid(:,:,nS);
               im = spotDetector(im);
               im = medfilt2(im, [10,10]);
               im = im>400;
               im = bwareaopen(im, obj.minObjSize);
               
               rp = regionprops(im);
               
               cen = [rp.Centroid];
               cen = reshape(cen, 2, length(cen)/2);
               
               obj.foundSpots{nS} = cen;
              % pos = [pos, cen];
               
               fprintf(1, '.');
            end
            fprintf(1, '\n');
            
            
        end
        
        function obj = getSpotStats(obj)
           %Get statistics of each of the spots found and construct array
           %that will be used for particle tracking. Format for particle
           %info will match the format used by Raghu's tracking code.
           
           %Get total number of particles
           numPart = 0;
           for nS=1:obj.numFrames
              numPart = numPart + length(obj.foundSpots{nS});             
           end
           
           %Populate array
           obj.spotList = zeros(6,numPart);
           n = 1;
           for nS=1:obj.numFrames
               
               numEl = size(obj.foundSpots{nS},2);
               %x-location
               obj.spotList(1,n:n+numEl-1) = obj.foundSpots{nS}(1,:)';
               %y-location
               obj.spotList(2,n:n+numEl-1) = obj.foundSpots{nS}(2,:)';
               
               %Making all brightness the same for now, just so we don't
               %have to think about this too much.
               obj.spotList(3,n:n+numEl-1) = ones(numEl,1);
               
               %Frame number
               obj.spotList(4,n:n+numEl-1) = nS*ones(numEl,1);
               
               %Track ID: Unique identifier
               obj.spotList(5,n:n+numEl-1) = n:n+numEl-1;
              
               %Sigma: make the same for everything for now
               obj.spotList(6,n:n+numEl-1) = zeros(numEl,1);
               obj.spotList(7,n:n+numEl-1) = zeros(numEl,1);

              n = n+numEl;
           end

            
        end
        
        function obj = removeSpotsOutsideGut(obj)
            mask = poly2mask(obj.gutMaskPoly(:,1),obj.gutMaskPoly(:,2), size(obj.vid,1), size(obj.vid,2));
            [x,y] = find(mask==1);
           for ns=1:length(obj.foundSpots)
              s = obj.foundSpots{ns};
              s = round(s);
              s(:,s(2,:)>size(obj.vid,1)) = [];
              s(:,s(1,:)>size(obj.vid,2)) = [];
              ind = sub2ind([size(obj.vid,1), size(obj.vid,2)], s(2,:), s(1,:));
              
              ind = mask(ind);
              
              s = s(:,ind);
              obj.foundSpots{ns} = s;
              
           end
        end
        
        function obj = cropImage(obj)
            %Show a MIP of image stack and prompt user for cropping region
            %Note: This should be called *very* early on in the image
            %processing, since we don't update the relative position of any
            %of the found bacteria etc.
            
            figure('Name', 'Select a cropping region for the video'); 
            
            imshow(max(obj.vid,[],3),[0 2000]);
            
            [~,rect] = imcrop;
            if(numel(rect) ==0)
                return
            end
            rect = round(rect);
            rect(1) = max([1, rect(1)]);
            rect(2) = max([1,rect(2)]);
    
            clo
            obj.vid = obj.vid(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3),:);
            
            close gcf
        end
        
        function obj = segmentGutOutline(obj)
            % obj = outlineGutHand(obj):Outline the gut by hand, using the
            % maximum intensity projection. Used to exclude found spots
            % outside the gut.
            figure('Name', 'Outline the gut by hand');
            imshow(max(obj.vid,[],3),[])
            imcontrast
            h = impoly('Closed', true); obj.gutMaskPoly = wait(h);       
        end
        
        function obj = getBacteriaHeatMap(obj)
            figure; hold on;
            cm = colormap(hsv(200));
            for i=1:200
                x = obj.foundSpots{i}(1,:);
                y = obj.foundSpots{i}(2,:);
                plot3(x, y, i*ones(length(y),1),'.', 'Color', cm(i,:));
                
            end
        end
        
        function obj = getVelocityDist(obj)
            %Building up trajectories of individual bacteria in the gut.
        end
        
        function obj = save(obj, varargin)
            %Save the results of our analysis.
            %Optional entry: saveVideoStack (default = true). If false,
            %save without saving the video stack with it, since it hogs
            %memory somewhat
            if(isempty(obj.saveDir))
                fprintf(2, 'Need to set save directory first!\n');
                return
            end
            fprintf(1, 'Saving bacVideo.');
            bacVideo = obj;
            save([obj.saveDir filesep obj.saveName], 'bacVideo', '-v7.3');
            fprintf(1, '..done!\n');

        end
       
        function obj = loadVideo(obj)
            info = imfinfo([obj.vidLoc filesep obj.vidName num2str(obj.vidMinS) '.' obj.vidSaveType]);
                   obj.vid = zeros(info.Height, info.Width, obj.vidMaxS-obj.vidMinS+1);
                   n = 1;
                   fprintf(1, 'Loading image stack');
                   for ns = obj.vidMinS:obj.vidMaxS
                       
                       im = imread([obj.vidLoc filesep obj.vidName num2str(ns) '.' obj.vidSaveType]);
                       obj.vid(:,:,n) = im;
                       n = n+1;
                       fprintf(1, '.');
                   end
                   fprintf(1, '\n');
        end
        
    end
    
    
    

end