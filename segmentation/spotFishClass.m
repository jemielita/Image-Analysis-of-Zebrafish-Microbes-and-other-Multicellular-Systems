%spotFishClass: Functions for manipulating all spots found for a given
%fish.

classdef spotFishClass
   properties
       %boilerplate
       saveDir = '';
       numScan = '';
       numColor = '';
       colorStr = '';
       numReg = '';
       param = '';
       
       saveName = 'bacCount';
       %Parameters used to do our analysis of found spots in the gut
       classType = [];
       
       spotClassifier = [];
       
       keepBugInd =[];
       removeBugInd = [];
   end
   
   methods
       
       function obj = spotFishClass(param)
          obj.saveDir = [param.dataSaveDirectory filesep 'singleBacCount'];
          obj.numScan = param.expData.totalNumberScans;
          obj.numColor = length(param.color);
          obj.colorStr = param.color;
          obj.param = param;
          
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
       
       function findSpots(obj,param, varargin)
           %findSpots(obj,param, varargin): Find all putative spots in all
           %scans, by running our wavelet-based spot detector program.
           
           for ns = 1:obj.numScan
               
               for colorNum = 1:obj.numColor
                   
                   imVar.scanNum = ns;imVar.zNum =''; imVar.color = obj.colorStr{colorNum};
                   mask = maskClass.getGutFillMask(param, ns);
                   
                   for nr = 1:obj.numReg
                       
                       im = load3dVolume(param, imVar, 'single',nr);
                       
                       xOutI = param.regionExtent.XY{colorNum}(nr,1);
                       xOutF = param.regionExtent.XY{colorNum}(nr,3)+xOutI-1;
                       
                       yOutI = param.regionExtent.XY{colorNum}(nr,2);
                       yOutF = param.regionExtent.XY{colorNum}(nr,4)+yOutI -1;
                       
                       regMask = mask(xOutI:xOutF, yOutI:yOutF);
                       
                       im = double(repmat(regMask,1,1,size(im,3))).*double(im);
                       
                       im(im<250) = 250;
                       spotLoc = countSingleBacteria(im,'', colorNum, param,regMask);
                       
                       fileName = [param.dataSaveDirectory filesep 'foundSpots' filesep 'nS_' num2str(ns) '_' obj.colorStr{colorNum} '_nR' num2str(nr) '.mat'];
                       save(fileName,'spotLoc', '-v7.3');
                   end
               end
               
           end
           
       end
      
       function resortFoundSpot(obj, param, inputDir, varargin)
           switch nargin
               case 2
                   inputDir = 'foundSpots';
                   outputDir = 'singleBacCount';
                   if(~isdir([param.dataSaveDirectory filesep 'singleBacCount']))
                       mkdir([param.dataSaveDirectory filesep 'singleBacCount'])
                   end
                   
                   inputName = '';
                   outputName = 'bacCount';
               case 6
                   inputDir = varargin{1};
                   outputDir = varargin{2};
                   inputName = varargin{3};
                   outputName = varargin{4};
           end
           
           %% Load each region of the gut independently that have had the spot detector algorithm run on it.
           fprintf(1, 'Resorting out data');
           for ns=1:obj.numScan
               rProp = cell(obj.numColor,1);
               
               for colorNum = 1:obj.numColor
                   imVar.scanNum = ns;imVar.zNum =''; imVar.color = obj.colorStr{colorNum};                   
                   for nr = 1:obj.numReg
                       fileName = [param.dataSaveDirectory filesep inputDir inputName filesep 'nS_' num2str(ns) '_' obj.colorStr{colorNum} '_nR' num2str(nr) '.mat'];
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
                           rProp{colorNum} = [rProp{colorNum}; spotLoc];
                       end                       
                       fprintf(1, '.');
                   end
                   
               end
               fileName = [param.dataSaveDirectory filesep outputDir filesep outputName num2str(ns) '.mat'];
               save(fileName, 'rProp');
               
           end
           fprintf(1, '\n');
           
       end
       
       function update(obj, str)
          %Update specific entries for the found spots and save this
          %updated version.
          %Possible values:
          % 'gutSlice': Find which slice in the gut the found spot is in
          %
          
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
                          rProp{nc} = spotClass.findGutSliceParticle(rProp{nc}, obj.param,ns);
                      case 'ind'
                          rProp{nc} = spotClass.setSpotInd(rProp{nc});
                      case 'object feature'
                          %Get a host of object features for these spots,
                          %and remove spots which, for whatever reason,
                          %don't show up on this
                          rProp{nc} = spotClass.getObjectFeat(rProp{nc},obj.param,50, ns,nc);
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
          for ns=1:obj.numScan
              for nc = 1:obj.numColor
                  %Load in data
                  rProp{nc} = obj.loadSpot(ns, nc);
                  
                  switch lower(str)
                      case 'area'
                          rProp{nc} = spotClass.cullVal(rProp{nc}, 'Area', val(nc));
                      case 'mininten'
                          rProp{nc} = spotClass.cullVal(rProp{nc}, 'MinIntensity', val(nc));
                      case 'meaninten'
                          rProp{nc} = spotClass.cullVal(rProp{nc}, 'MeanIntensity', val(nc));
                      case 'maxinten'
                          rProp{nc} = spotClass.cullVal(rProp{nc}, 'MaxIntensity', val(nc));
                      case 'distance'
                          rProp{nc} = spotClass.distCutoff(rProp{nc}, val(nc));
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
           %rProp = loadSpot(ns,nc): load this particular set of spots.
           inputVar = load([obj.saveDir filesep obj.saveName num2str(ns) '.mat']);
           rProp = inputVar.rProp{nc};
       end
       
       function rProp = loadFinalSpot(obj, ns,nc)
          %rProp = loadFinalSpot(obj, ns,nc): Load in the final result of
          %our spot analysis (after the function classifySpots) has been
          %run.
          fSaveDir = [obj.saveDir filesep 'final'];
          
          if(~isdir(fSaveDir))
              fprintf(2, 'Need to run the function .classifySpots first!\n');
              return
          else
              %Save the result
              inputVar = load([fSaveDir filesep obj.saveName num2str(ns) '.mat']);
              rProp = inputVar.rProp{nc};
          end
          
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
       
       function obj = createClassificationPipeline(obj)
           obj.classType = cell(obj.numColor,1);
           for nc=1:obj.numColor
              obj.classType{nc} = cell(obj.numScan,1);
              for ns=1:obj.numScan
                 obj.classType{nc}{ns} = 'SVMclassify'; 
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
               %rProp{nc} = obj.spotClassifier{nc}.autoFluorCutoff(rProp{nc});
           
           
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