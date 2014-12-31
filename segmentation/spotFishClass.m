%spotFishClass: Functions for identifying, manipulating, updating, and
%manually pruning foung bacterial spots in the gut.

classdef spotFishClass
   properties
       %Location to save all found spots and the classifiers used. Should
       %be set to 'gutOutline/singleBacCount'
       saveDir = '';
       
       %Number of scans for this fish.
       numScan = '';
       %Number of colors
       numColor = '';
       %Cell array containing color names: {'488nm', '568nm'};
       colorStr = '';
       %Number of regions to tile the full gut
       numReg = '';

       %String to save the spots for each scan to. Ex:
       %obj.saveDir/saveName(scanNum).mat
       saveName = 'bacCount';
       
       %Cell array, format: {colorNum}{scanNum}, that containing a string
       %identifying the type of classifier that will be used for that
       %particular scan, e.g. 'SVMclassify'
       classType = [];
       
       %Cell array containing an instance of the spotClassifier class that
       %will be used to do the classifying (whatever it is) of the spots
       spotClassifier = [];
       
       %Cell array, format: {scanNum,colorNum}, containg indices f bugs
       %that we will keep, and getting rid of everything else. Current support for this variable isn't great.
       keepBugInd =[];
       
       %Cell array, format: {scanNum,colorNum}, containg indices f bugs
       %that we will manually remove.
       removeBugInd = [];
       
       intenThresh = 250; %All pixels below this intensity will be set to this intensity before using our spot detecting code. Helps get rid of some junk.
       boxSize = 50; %Size of box around each bacteria.
       
       objThresh = 50; %Threshold for keeping bacteria in the spot detector code.
   end
   
   methods
       
       function obj = spotFishClass(param)
           %obj = spotFishClass(param): Constructor for an instance of
           %spotFishClass.
           obj.saveDir = [param.dataSaveDirectory filesep 'singleBacCount'];
           obj.numScan = param.expData.totalNumberScans;
           obj.numColor = length(param.color);
           obj.colorStr = param.color;
       
           if(isfield(param.expData.Scan, 'isScan'))
               totalNumRegions = unique([param.expData.Scan.region].*[strcmp('true', {param.expData.Scan.isScan})]);
           else
               totalNumRegions = unique([param.expData.Scan.region]);
           end
           totalNumRegions(totalNumRegions==0) = [];
           
           obj.numReg = length(totalNumRegions);
           
           obj.keepBugInd = cell(obj.numScan, obj.numColor);
           obj.removeBugInd = cell(obj.numScan, obj.numColor);
       end
       
       function findSpots(obj,param)
           %findSpots(obj,param): Find all putative spots in all
           %scans, by running our wavelet-based spot detector program.
           %Results saved to: param.dataSaveDirectory/foundSpots.
           
           if(nargin~=2)
              fprintf(2, 'spotFishClass.findSpots must be called with only param as argument!\n');
              return
           end
           
           if(~isdir([param.dataSaveDirectory filesep 'foundSpots']))
               mkdir([param.dataSaveDirectory filesep 'foundSpots']);
               fprintf(1, 'Making directory to save data\n');
            end
           
           for ns = 1:obj.numScan
               
               for colorNum = 1:obj.numColor

                  obj.findThisSpot(param, ns, colorNum, 1:obj.numReg);
               end
               
           end
           
       end
      
       
       function findThisSpot(obj, param, ns, colorNum, regList)
            imVar.scanNum = ns;imVar.zNum =''; imVar.color = obj.colorStr{colorNum};
                   mask = maskFish.getGutFillMask(param, ns);
                   
                   for i = 1:length(regList)
                       nr = regList(i);
                       %% Load spots 
                       im = load3dVolume(param, imVar, 'single',nr);
                       
                       height = param.regionExtent.XY{colorNum}(nr,3);
                       width = param.regionExtent.XY{colorNum}(nr,4);
                       
                       %Get the range of pixels that we will read from and read out to.
                       xOutI = param.regionExtent.XY{colorNum}(nr,1);
                       xOutF = xOutI+height-1;
                       
                       yOutI = param.regionExtent.XY{colorNum}(nr,2);
                       yOutF = yOutI+width -1;
                       
                       xInI = param.regionExtent.XY{colorNum}(nr,5);
                       xInF = xInI +height-1;
                       
                       yInI = param.regionExtent.XY{colorNum}(nr,6);
                       yInF = yInI +width-1;
                       
                       regMask = mask(xOutI:xOutF, yOutI:yOutF);
                       im = im(xOutI:xOutF, yOutI:yOutF,:);
                       im = double(repmat(regMask,1,1,size(im,3))).*double(im);
                       
                       %% Get putative bacterial spots
                       im(im<obj.intenThresh) = obj.intenThresh;
                       spotLoc = countSingleBacteria(im,'', colorNum, param,regMask,obj.intenThresh, obj.objThresh);
                       if(isempty(spotLoc))
                           continue
                       end
                       %% Map spot location onto the coordinate system used
                       % for the gut
                      
                       %Get x y coordinates
                       pos = [spotLoc.Centroid];
                       pos = reshape(pos, 3, length(pos)/3);
                       pos(1,:) = pos(1,:) + yOutI -1;
                       pos(2,:) = pos(2,:) + xOutI -1;
                       
                       %Get new z coordinates
                       zList = param.regionExtent.Z(:,nr);
                       ind = find(zList~=-1, 1,'first');
                       pos(3,:) = pos(3,:) + ind-1;
                       for i=1:length(spotLoc)
                           spotLoc(i).CentroidOrig = pos(:,i)';
                       end
                       
                       %% Update spots index and gut slice number
                       spotLoc = spotClass.findGutSliceParticle(spotLoc, param, ns);
                       
                       %% Save results
                       fileName = [param.dataSaveDirectory filesep 'foundSpots' filesep 'nS_' num2str(ns) '_' obj.colorStr{colorNum} '_nR' num2str(nr) '.mat'];
                       save(fileName,'spotLoc', '-v7.3');
                   end
       end
       
       function resortFoundSpot(obj, param, inputDir, varargin)
           %resortFoundSpot(param). Move results of the spot detector
           %algorithm from foundSpots to the save directory for our
           %classifier (obj.saveDir)
           if(~ismember(nargin, [2,6]))
              fprintf(2, 'resortFoundSpot must be called with 1 or 5 arguments!\n');
              return
           end
           
           switch nargin
               case 2
                   inputDir = 'foundSpots';
                   outputDir = obj.saveDir;
                   if(~isdir([param.dataSaveDirectory filesep 'singleBacCount']))
                       mkdir([param.dataSaveDirectory filesep 'singleBacCount'])
                   end
                   
                   inputName = '';
                   outputName = obj.saveName;
               case 6
                   inputDir = varargin{1};
                   outputDir = varargin{2};
                   inputName = varargin{3};
                   outputName = varargin{4};
           end
           
           %% Load each region of the gut independently that have had the spot detector algorithm run on it.
           fprintf(1, 'Resorting out data');
           for ns = 1:obj.numScan
  
               rProp = cell(obj.numColor,1);
               
               for colorNum = 1:obj.numColor
                   imVar.scanNum = ns;imVar.zNum =''; imVar.color = obj.colorStr{colorNum};                   
                   for nr = 1:obj.numReg
                       fileName = [param.dataSaveDirectory filesep inputDir inputName filesep 'nS_' num2str(ns) '_' obj.colorStr{colorNum} '_nR' num2str(nr) '.mat'];
                       if(exist(fileName,'file')==0)
                          %This region wasn't made in our analysis because
                          %no spots were found.
                           continue;
                       end
                       inputVar = load(fileName);
                       spotLoc = inputVar.spotLoc;
                       
                       xOutI = param.regionExtent.XY{colorNum}(nr,1);
                       xOutF = param.regionExtent.XY{colorNum}(nr,3)+xOutI-1;
                       
                       yOutI = param.regionExtent.XY{colorNum}(nr,2);
                       yOutF = param.regionExtent.XY{colorNum}(nr,4)+yOutI -1;
                       
                       %Get x y coordinates
                       pos = [spotLoc.Centroid];
                       pos = reshape(pos, 3, length(pos)/3);
                       pos(1,:) = pos(1,:) + yOutI -1;
                       pos(2,:) = pos(2,:) + xOutI -1;
                       
                       %Get range that overlaps the different regions and
                       %remove points from the more posterior region (to
                       %avoid overcounting).
                       if(nr<obj.numReg)
                           %Pick out the region that overlaps for the x and
                           %y direction
                           yList = [param.regionExtent.XY{1}(nr,1),param.regionExtent.XY{1}(nr,1)+param.regionExtent.XY{1}(nr,3), ...
                               param.regionExtent.XY{1}(nr+1,1),param.regionExtent.XY{1}(nr+1,1)+param.regionExtent.XY{1}(nr+1,3)];
                           yList = sort(yList); yList = yList(2:3);
                          
                           
                           xList = [param.regionExtent.XY{1}(nr,2),param.regionExtent.XY{1}(nr,2)+param.regionExtent.XY{1}(nr,4), ...
                               param.regionExtent.XY{1}(nr+1,2),param.regionExtent.XY{1}(nr+1,2)+param.regionExtent.XY{1}(nr+1,4)];
                           xList = sort(xList); xList = xList(2:3);
                          
                           indX = pos(1,:)>xList(1) & pos(1,:)<xList(2);
                           indY = pos(2,:)>yList(1) & pos(2,:)<yList(2);
                           
                           ind = indX.*indY;
                          
                           pos = pos(:,~ind);
                           spotLoc = spotLoc(~ind);
                       end
                       %Get new z coordinates
                       zList = param.regionExtent.Z(:,nr);
                       ind = find(zList~=-1, 1,'first');
                       pos(3,:) = pos(3,:) + ind-1;
                       for i=1:length(spotLoc)
                           spotLoc(i).CentroidOrig = pos(:,i)';
                       end
                       
                       if(isempty(spotLoc))
                           continue;
                       end
                       
                       if(isempty(rProp{colorNum}))
                           rProp{colorNum} = spotLoc;
                       else
                           rProp{colorNum} = [rProp{colorNum}, spotLoc];
                       end                       
                       fprintf(1, '.');
                   end
                   rProp{colorNum} = spotClass.setSpotInd(rProp{colorNum});
                   %Give each element in rProp a unique index
               end
               fileName = [obj.saveDir filesep outputName num2str(ns) '.mat'];
                save(fileName, 'rProp');
               
           end
           fprintf(1, '\n');
           
       end
       
       function update(obj, str,param)
          % update(str, param)
          %Update specific entries for the found spots and save this
          %updated version.
          %Possible values for str:
          % 'gutSlice': Find which slice in the gut the found spot is in
          % 'ind': Find the index of the wedge down the length of the gut
          %        that this spot is in.
          % 'object feature': Find the smorgasbord of object features for
          %                   each of the putative bacteria. This is is a 
          %                   somewhat time intensive piece of code.
          
          fields = ['gutSlice', 'ind'];
          if(~ismember(str, fields))
             fprintf(2, [str ': is not a valid field to update!']); 
             return
          end
          
          fprintf(1, 'Updating');
          rProp = cell(obj.numColor,1);
          for ns=1:obj.numScan
              for nc = 1:obj.numColor
                  %Load in data
                  rProp{nc} = obj.loadSpot(ns, nc);
                  
                  switch str
                      case 'gutSlice'
                          rProp{nc} = spotClass.findGutSliceParticle(rProp{nc}, param, ns);
                      case 'ind'
                          rProp{nc} = spotClass.setSpotInd(rProp{nc});
                      case 'object feature'
                          %Get a host of object features for these spots,
                          %and remove spots which, for whatever reason,
                          %don't show up on this
                          rProp{nc} = spotClass.getObjectFeatAll(rProp{nc}, param, obj.boxSize, ns, nc);
                      otherwise
                          fprintf(2, 'Update string not recognized!\n');
                          return
                  end
                  
                  fprintf(1, '.');
              end
              obj.saveSpot(rProp,ns);
          end
          fprintf(1, '\n');
                  
           
       end
       
       function cull(obj, str,val)
           %Cull the list of found spots below a given cutoff for different
           %features of found objects. Recommend making a backup
           %(spotFishClass.backupList) before doing anything.
           % Only one color done at a time.
           %Possible values:
           % 'area': (val= minArea), remove all spots below a certain area
           % 'minInten': minimum intensity for a given spot
           % 'maxInten': maximum intensity for a given spot
           % 'meanInten': mean intensity for a given spot
           % 'distance': distance to nearest spot. If two spots are within
           % the distance given as input, only keep the brightest spot.
           % Distance is in microns. Suggested value: 3 microns.
           %Note: This function should only be used for culling scalar
           %values of each of the spots.
           %Note: Only error checking that is done is to check that input
           %'val' is scalar and >0.
           if(length(val)~=2 || val(1)<0 || val(2) <0)
               fprintf(2, 'Val must be scalar greater than zero!');
               return;
           end
           
           fprintf(1, 'Culling');
           rProp = cell(obj.numColor,1);
           %for ns=1:obj.numScan
           for ns=1:12
           for nc = 1:obj.numColor
                   %Load in data
                   rProp{nc} = obj.loadSpot(ns, nc);
                   
                   switch lower(str)
                       case 'area'
                           rProp{nc} = spotClass.cullVal(rProp{nc}, 'Area2d', val(nc));
                       case 'mininten'
                           rProp{nc} = spotClass.cullVal(rProp{nc}, 'MinIntensity', val(nc));
                       case 'meaninten'
                           rProp{nc} = spotClass.cullVal(rProp{nc}, 'MeanIntensity', val(nc));
                       case 'maxinten'
                           rProp{nc} = spotClass.cullVal(rProp{nc}, 'MaxIntensity', val(nc));
                       case 'totinten'
                           rProp{nc} = spotClass.cullVal(rProp{nc}, 'totInten', val(nc));
                       case 'totintenwv'
                           rProp{nc} = spotClass.cullVal(rProp{nc}, 'totIntenWv', val(nc));
                       case 'distance'
                           rProp{nc} = spotClass.distCutoff(rProp{nc}, val(nc));
                       case 'objmean'
                           rProp{nc} = spotClass.cullVal(rProp{nc},'objMean',val(nc));
                       case 'bkgmean'
                           rProp{nc} = spotClass.cullVal(rProp{nc},'bkgMean',val(nc));
                       case 'wvlmean'
                           rProp{nc} = spotClass.cullVal(rProp{nc},'wvlMean',val(nc));
                       otherwise
                           fprintf(2, 'String doesnt match any cull function!\n');
                           return
                   end
               end
               fprintf(1, '.');
               obj.saveSpot(rProp,ns);
           end
           fprintf(1, '\n');
           
       end
       
       function rProp = loadSpot(obj, ns, nc)
           %rProp = loadSpot(ns,nc): load this particular set of spots,
           %without any filtering.
           inputVar = load([obj.saveDir filesep obj.saveName num2str(ns) '.mat']);
           rProp = inputVar.rProp{nc};
       end
       
       function rProp = loadFinalSpot(obj, ns,nc)
          %rProp = loadFinalSpot(obj, ns,nc): Load in the final result of
          %our spot analysis (after the function classifySpots) has been
          %run.
          rProp = obj.loadSpot(ns, nc);
          rProp = obj.classifyThisSpot(rProp,ns,nc);   
       end
       
       function rPropAll = loadFinalSpotAll(obj)
           rPropAll = cell(obj.numScan, obj.numColor);
           
           for ns=1:obj.numScan
               for nc=1:obj.numColor
                   rProp = obj.loadFinalSpot(ns,nc);
                   %Save the result                   
                   fprintf(1, '.');
               end
           end
           fprintf(1, '\n');
           
       end

       function saveSpot(obj, rProp, ns,nc)
           %saveSpot(rProp, ns,nc): Save the list of spots, rProp, to it's appropriate location. 
           fileName = [obj.saveDir filesep obj.saveName num2str(ns) '.mat'];
           save(fileName, 'rProp');
       end
       
       function backup(obj, origLoc, saveLoc)
           %backup(origLoc, saveLoc): Backup the list of spots to somewhere else.
           fprintf(1, 'Backing up spot list...');
           copyfile([obj.saveDir ], [obj.saveDir filesep saveLoc]);
           fprintf(1, '.\n'); 
       end
       
       function saveInstance(obj)
          %saveInstance(): save this instance of spotFishClass to
          %(obj.saveDir/'spotClassifier.mat). This will almost always be in
          %the subfolder /gutOutline/singleBacCount
          spots = obj;
          save([obj.saveDir filesep 'spotClassifier.mat'], 'spots');     
       end
       
       function reloadBackup(obj, origLoc, backupLoc)
          %Reload the backup file and overwrite the current list of spots. 
       end
       
       function obj = createClassificationPipeline(obj,classType)
           if(nargin==1)
               classType = 'SVMclassify';
           end
           
           obj.classType = cell(obj.numColor,1);
           for nc=1:obj.numColor
              obj.classType{nc} = cell(obj.numScan,1);
              for ns=1:obj.numScan
                 obj.classType{nc}{ns} = classType; 
              end
           end
           
           %For now, let's classify everything with a basic pipeline, of
           %applying cutoffs 
       end
       
       function classifySpots(obj)
           %Run through a set of operations to filter down the spots.
           fSaveDir = [obj.saveDir filesep 'singleBacCount' filesep 'final'];
           if(~isdir(fSaveDir))
               mkdir(fSaveDir);
           end
           
           fprintf(1, 'Classifying');
           for ns=1:obj.numScan
              for nc=1:obj.numColor
                  rProp{nc} = obj.loadSpot(ns, nc);

                  rProp{nc} = obj.classifyThisSpot(rProp{nc},ns,nc);
                  %Save the result
                  %save([fSaveDir filesep obj.saveName num2str(ns) '.mat'], 'rProp');
                  
                  ind(ns,nc) = length(rProp{nc});
                  fprintf(1, '.');
              end
              
           end
           fprintf(1, '\n');
           
       end
       
       function rProp = classifyThisSpot(obj, rProp,ns,nc)
               %This syntax is somewhat confusing, but allows for
               %flexibility in constructing different classifiers for each
               %scan and color.
               %obj contains a cell array, 'spotClassifier', that holds an
               %instance of the classifier used for each of the different colors of scans.
               %Each of those classifiers has functions associated with it 
               %that we can further use to classify the data. The
               %particular classifiers for each scan is called by
               %.(obj.classType{i}{ns}) which using dynamics field names to
               %run a particular function filtering rProp.
               
               rProp = obj.spotClassifier{nc}.(obj.classType{nc}{ns})(rProp);
               
               %mlj: Don't do this for now until we clean up the
               %indexing in multipleRegionCrop for identifying particles
               %to remove.
%               rProp = obj.spotClassifier{nc}.manuallyRemovedBugs(rProp, obj.removeBugInd{ns,nc});
               rProp = spotClass.keptManualSpots(rProp, obj.removeBugInd{ns,nc});
               rProp = obj.spotClassifier{nc}.autoFluorCutoff(rProp);
           
           
       end
       
       function [loc, rProp] = getSpotLoc(obj,rProp, type, scanNum, colorNum)
           
           switch type
               case 'removed'
                   %Note: need to make sure this is done with the index of
                   %the particle, not the location
                   %Construct list of removed spots
                   
                   %rProp = rProp(obj.removeBugInd{scanNum,colorNum});
                   rProp = spotClass.removedManualSpots(rProp, obj.removeBugInd{scanNum, colorNum});
                   
                   xyzRem = [rProp.CentroidOrig];
                   xyzRem = reshape(xyzRem,3,length(xyzRem)/3);
                   %loc = xyzRem(:,obj.removeBugInd{scanNum,colorNum});
                    loc = xyzRem;
               case 'manually kept'
                   %Note: need to make sure this is done with the index of
                   %the particle, not the location 
                   xyzKeptInd = obj.keepBugInd{scanNum, colorNum};
                   xyzKept = [rProp.CentroidOrig];
                   xyzKept = reshape(xyzKept,3,length(xyzKept)/3);
                   loc = xyzKept(:, xyzKeptInd);
                   
                   rProp = rProp(xyzKeptInd);
                   
               case 'filtered'
                   rProp = obj.classifyThisSpot(rProp, scanNum,colorNum);
                   loc = [rProp.CentroidOrig];
                   loc = reshape(loc,3,length(loc)/3);

                   
               case 'all' 
                   rProp = spotClass.keptManualSpots(rProp, obj.removeBugInd{scanNum, colorNum});

                   %keptInd = setdiff(1:length(rProp), obj.removeBugInd{scanNum, colorNum});
                   
                   xyzKept = [rProp.CentroidOrig];
                   xyzKept = reshape(xyzKept,3,length(xyzKept)/3); 
                   %loc = xyzKept(:, keptInd);
                   %rProp = rProp(keptInd);
                   loc = xyzKept;
           end
              
       end
   end

end