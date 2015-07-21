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
        
        %For classification
         feat = {'MeanIntensity', 'MinIntensity', 'MaxIntensity',...
             'wvArea',  'wvMeanIntensity', 'wvMinIntensity','wvMaxIntensity'};
        tList = [];
        featRng = NaN;
        boxVal = [0.01 0.01];
        svmStruct = [];
        
        %For displaying results
        intenRange = [0 10000]; %Range for displaying images.
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
            if(~isempty(obj.vid))
                hIm = imshow(obj.vid(:,:,1),obj.intenRange);
            else
                im = obj.loadFrame(1);
                hIm = imshow(im, obj.intenRange);
            end
            
            hold on
            hP = obj.displaySpots(argList,1, '');
            
            for nS=2:obj.numFrames
                obj.displaySpots(argList,nS,hP);
                
                if(~isempty(obj.vid))
                    set(hIm, 'CData', obj.vid(:,:,nS));
                else
                    set(hIm, 'CData', obj.loadFrame(nS));
                end
                pause(pauseTime);
            end
        end
        
        function [hIm, hP] = displayFrame(obj, scanNum)
            %Display image and spots for a given frame
            im = obj.loadFrame(scanNum);
            hIm = imshow(im, obj.intenRange);
            hold on;
            hP = obj.displaySpots('show spots',scanNum, '');
            hold off;
        end
        
        function removeBug(obj, scanNum)
            %For a given frame manually remove all the desired bugs.
            %Will automatically save this list to a subdirectory of
            %obj.saveLoc
            
            [hIm, hP] =  obj.displayFrame(scanNum);
            hAxis = gca;
            
            inputVar = load([obj.saveDir filesep 'foundSpots' filesep 'spot' num2str(scanNum) '.mat']);
            sp = inputVar.foundSpots;
            xyAll = [sp.Centroid];
            xyAll = reshape(xyAll, 2, length(xyAll)/2);
            
            indAll = [];
            
            %Loop forever. Ctr-c to stop.
            n =0;
            while(n==0)
                hRemBug = imrect(hAxis);
                set(hRemBug, 'Tag', 'removeBug');
                
                pause(0.5);
                hRemBugAPI = iptgetapi(hRemBug);
                
                position = hRemBugAPI.getPosition();
                
                delete(hRemBug)
                drawnow;
                ind = obj.findBugsBox(position,xyAll);
                indAll = [ind, indAll];
                
                %Only display saved spots now
                xy = xyAll;
                xy(:,indAll) = [];
                
                set(hP, 'XData', xy(1,:));
                set(hP, 'YData', xy(2,:));
                
                %Save the new indices
                save([obj.saveDir filesep 'foundSpots', filesep 'spot' num2str(scanNum) 'remInd.mat'], 'indAll'); 
                
            end
            
        end
        
        function rProp = classifySpot(obj,rProp)
           %Construct array of values for each of the found spots
           
           for i=1:length(obj.feat)
              allData(:,i) = [rProp.(obj.feat{i})]; 
              allData(:,i) = allData(:,i)./obj.featRng.maxR.(obj.feat{i});
           end
           
           svmClass = svmclassify(obj.svmStruct, allData);
           
           rProp = rProp(svmClass =='true');
           
           
        end
        
        function obj = createTrainingList(obj, sList)
           %Assemble a training list from this data
           
           %Clear previously made training list
           obj.tList = [];
           
           
           for i = 1:length(sList)
               ns = sList(i);
               inputVar = load([obj.saveDir filesep 'foundSpots' filesep 'spot' num2str(sList(i)) 'remInd.mat']);
               ind = inputVar.indAll;
              
               ind = unique(ind);
               
               inputVar = load([obj.saveDir filesep 'foundSpots' filesep 'spot' num2str(sList(i)) '.mat']);
               foundSpots = inputVar.foundSpots;
               
               keptSpots = setdiff(1:length(foundSpots), ind);
               remSpots = ind;
            
               numKeptSpots = length(keptSpots);
               numRemSpots = length(remSpots);
               
               %Should be written more generally to call any number of
               %classification features
               t = zeros(length(foundSpots), length(obj.feat));
               for j = 1:length(obj.feat)
                   t(:,j) = [[foundSpots(keptSpots).(obj.feat{j})], [foundSpots(remSpots).(obj.feat{j})]]';
               end
               if(numKeptSpots==0)
                   t(1:end,length(obj.feat)+1) = 0;                 
               else
                   t(1:numKeptSpots-1,length(obj.feat)+1) = 1;
                   t(numKeptSpots:end,length(obj.feat)+1) = 0;
               end
               obj.tList = [obj.tList; t];
               
        end
        
        end
        
        function obj = buildClassifier(obj)
            
            if(isempty(obj.tList))
                fprintf(2, 'Need to construct a training list first!\n');
                return
            end
            
            Y = obj.tList(:,end); Ynom = nominal(Y==1);
            
            for i=1:length(obj.feat)
                tList(:,i)  = obj.tList(:,i)./max(obj.tList(:,i));
            end
            
            for i=1:length(obj.feat)
                obj.featRng.maxR.(obj.feat{i}) = max(obj.tList(:,i));
            end
            
            figure;
            
            numKeptSpots = sum(Y==1);
            
            %obj.tList(:,[1,3]) = log(obj.tList(:,[1,3]));
            boxCon = [obj.boxVal(1)*ones(numKeptSpots,1); obj.boxVal(2)*ones(size(tList,1)-numKeptSpots,1)];
            displayData = true;
            
            if(displayData==true)
                svmStruct = svmtrain(tList(:,[4,5]), Ynom, 'showplot', true, 'Kernel_Function', 'polynomial', 'boxconstraint', boxCon, ...
                    'autoscale', true);
                
            end
            
            svmStruct = svmtrain(tList(:,1:7), Ynom, 'showplot', true, 'Kernel_Function', 'polynomial','boxconstraint', boxCon,'autoscale', true);
            
            % Calculate the confusion matrix
            
            group = svmclassify(svmStruct,tList(:,1:7));
            
            N = length(group);
            
            bad = ~strcmp(group, Ynom);
            ldaResubErr  = sum(bad)/N;
            
            [ldaResubCM,grpOrder] = confusionmat(Ynom,group)
            
            obj.svmStruct = svmStruct;
        end
        
        function ind = findBugsBox(obj, position, xy)
            
            xMin = position(1); xMax = position(1) + position(3);
            yMin = position(2); yMax = position(2) + position(4);
            
            indX = find((xy(1,:)>xMin) + (xy(1,:)<xMax) ==2);
            indY = find((xy(2,:)>yMin) + (xy(2,:)<yMax) ==2);
            
            ind = intersect(indX, indY);
        end
        
        function spotHandle = displaySpots(obj,argList,nS, spotHandle)
            if(sum(ismember(argList,'show spots'))>1)
                inputVar = load([obj.saveDir filesep 'foundSpots' filesep 'spot' num2str(nS) '.mat']);
                sp = inputVar.foundSpots;
                
               % sp = obj.classifySpot(sp);
                    sp([sp.wvMaxIntensity]<1500) = [];

                
                sp = [sp.Centroid];
                sp = reshape(sp, 2, length(sp)/2);
                
                if(nS==1 || isempty(spotHandle))
                    spotHandle = plot(sp(1,:),...
                        sp(2,:), 'o', ...
                        'Color', [0.7, 0.2 0.2]);
                    
                    
                else
                    set(spotHandle, 'XData', sp(1,:));
                    set(spotHandle, 'YData', sp(2,:));
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
        
        if(~isempty(obj.vid))
            [obj.vid(:,:,nS),~] = spotDetector(obj.vid(:,:,nS));
            im = obj.vid(:,:,nS);
        else
            %Load in this frame
            imIn = obj.loadFrame(nS);
            im = cv.spotDetectorFast_v2(double(imIn),4);
        end
        
        im = medfilt2(im, [10,10]);
        bw = im>400;
        bw = bwareaopen(bw, obj.minObjSize);
        
        
        rp = regionprops(bw, imIn, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox', 'MaxIntensity', 'MinIntensity', 'WeightedCentroid','PixelIdxList');
        
        %Calculate properties of the wavelet transformed image
        propWv = regionprops(bw, im, 'Centroid', 'Area', 'MeanIntensity', 'MaxIntensity', 'MinIntensity');
        for i=1:length(rp)
            
            fn = fieldnames(rp);
            fnWv = fieldnames(propWv);
            
            for j=1:length(fn)
                foundSpots(i).(fn{j}) = rp(i).(fn{j});
            end
            
            %Update wavelet features also
            for j = 1:length(fnWv)
                wvOut = ['wv' fnWv{j}];
                foundSpots(i).(wvOut) = propWv(i).(fnWv{j});
            end
            
        end
        %Save the result
        save([obj.saveDir filesep 'foundSpots' filesep 'spot' num2str(nS) '.mat'], 'foundSpots');
        
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
        %Use active contours to segment the intestine
        bw = obj.gutMaskPoly;
        for ns=obj.vidMinS:obj.vidMaxS
            im = obj.loadFrame(ns);
            
            bw = activecontour(mat2gray(im), bw, 200,'Chan-Vese', 'SmoothFactor', 1, 'ContractionBias', 0.1);
            
            imshow(double(im)+double(max(im(:)))*double(bwperim(bw)),[])
            save([obj.saveDir filesep 'segMasks' filesep 'mask' num2str(ns), '.mat'], 'bw');
        end
     
     
    end
    
    function obj = manuallyOutlineGut(obj)
        %Manually outline the gut. Use as a seed for segmentGutOutline
        obj.displayFrame(1);
        
        obj.gutMaskPoly = roipoly;   
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
        info = imfinfo([obj.vidLoc filesep obj.vidName sprintf('%04d', obj.vidMinS) '.' obj.vidSaveType]);
        obj.vid = zeros(info.Height, info.Width, obj.vidMaxS-obj.vidMinS+1);
        n = 1;
        fprintf(1, 'Loading image stack');
        for ns = obj.vidMinS:obj.vidMaxS
            
            im = obj.loadFrame(ns);
            obj.vid(:,:,n) = im;
            n = n+1;
            fprintf(1, '.');
        end
        fprintf(1, '\n');
    end
    
    function im = loadFrame(obj, ns)
    im = imread([obj.vidLoc filesep obj.vidName sprintf('%04d', ns) '.' obj.vidSaveType]);
  
       m = load([obj.saveDir filesep 'segMasks' filesep 'mask' num2str(ns) '.mat']);
    m = m.bw;
    
    m = bwperim(m);
    
    im = double(im) + double(max(im(:)))*double(m);
    end
    
    
    function [dall, dallRand] = getWallDist(obj)
       %Calculate the distance to the wall for all scans.
       %Also calculate distances for a random model of points scattered
       %throughout the segmented region
       
       dall = cell(obj.numFrames);
       for ns=1:obj.numFrames
           
           inputVar = load([obj.saveDir filesep 'foundSpots' filesep 'spot' num2str(ns) '.mat']);
           sp = inputVar.foundSpots;
           
           sp([sp.wvMaxIntensity]<1500) = [];
           
           xy = [sp.Centroid];
           xy = reshape(xy, 2, length(xy)/2);
           xy = round(xy);
           
           im = obj.loadFrame(ns);
           im = zeros(size(im));
           ind = sub2ind(size(im), xy(2,:), xy(1,:));
           im(ind) = 1;
           
           
           m = load([obj.saveDir filesep 'segMasks' filesep 'mask' num2str(ns) '.mat']);
           m = m.bw;
           
           %Remove spots outside of the mask
           im = im+m;
           im = im>1;
           
           [x y] = find(im==1);
           xy = [x y];
           
           
           %Calculate a random sample from the region that we've segmented
           ind = find(m==1);
           indSample = randsample(ind, 1000);
           [x, y] = ind2sub(size(m), indSample);
           xyRand = [ x y];
           
           m = bwperim(m);
           %Remove spots in mask from far left and right row-these aren't real
           %edges in some of the scan (b/c of a cropping rectangle
           
           xmin = find(sum(m,1)>1, 1, 'first');
           xmax = find(sum(m,1)>1, 1, 'last');
           
           [r c] = find(m==1);
           bound = [r c];
           remind = [c==xmin]+ [c==xmax]; remind = logical(remind);
           bound(remind,:) = [];
           
           %Now find the distance of all points to the closest point on the wall
           d = dist(xy, bound');
           
           d = min(d, [],2);
           
           dall{ns} = d;
           
           %Find the distance of simulated points to the wall
           dRand = dist(xyRand, bound');
           dRand = min(dRand, [],2);
           dallRand{ns} = dRand;
           ns
       end

    end
end




end