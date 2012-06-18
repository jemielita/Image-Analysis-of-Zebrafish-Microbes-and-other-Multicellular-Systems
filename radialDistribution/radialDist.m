function radialDist(line, mask, param, averageBox, averageBoxType)
%Initialize arrays that we'll use for calculating the radial distribution.
fprintf(1, 'Initializing arrays for radial distribution calculation...')
[xArr, yArr, lineExt] = radialDistInit(line, mask, param, averageBox, averageBoxType);

%Create a directory to store the results, if necessary
dirName = [param.dataSaveDirectory filesep 'radialDist'];
if(~isdir(dirName))
    disp(strcat('Making the directory: ', dirName)); 
    mkdir(param.dataSaveDirectory, 'radialDist');
end
%Going through each of these arrays and averaging them across the boxes.
%Note: need to test this code on a good test image.

%Let's see if this works for the memory allocation-allocate memory for 3
%line distributions at once;
lineSpace = 1:3:length(xArr);
lineSpace(end+1) = length(xArr)-1;

%Allocate space for the image that we'll be working with
im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));

%Save the line that we're calculating this on
filename = [param.dataSaveDirectory filesep 'radialDist' filesep 'rd.mat'];
save(filename, 'xArr', 'yArr', 'lineExt');
for lineSet =1:length(lineSpace)-1
    clear radRegionc
   %For each set of lines, preallocate enough memory for the entire z
   %stack.
    theseLines = lineSpace(lineSet):lineSpace(lineSet+1)-1;
    disp(strcat('Calculating the radial distribution for the lines: ', num2Str(theseLines)));
    radRegion = cell(length(theseLines),1); 
    for i = 1:length(radRegion)
        lineNum = theseLines(i);
        %Allocate enough memory for the entire width of the line, plus the
        %depth in z we'll have to go.
        radRegion{i} = zeros(size(xArr{lineNum},2), lineExt(lineNum,2)-lineExt(lineNum)+1);        
    end
  
    %Now for all of these images go through the registered images and find
    %the z values. We won't have to go through all the z values, just the
    %ones that are in this set of points.
    lineRange = lineExt(theseLines,:);
    zMin = min(lineRange(:,1));
    zMax = max(lineRange(:,2));
    
     fprintf(2, 'Going through the z stack...');
     for z =zMin:zMax
        fprintf(2, '.');
        nScan = 1;
        im = registerSingleImage(nScan, '488nm', z, im,param);
        im = double(im);
        %Then for each line scan in this region, calculate the interpolated
        %pixel values for each of the lines in this loop
       
        %Get the lines in this loop for which z is still in the range of
        %that line.
        getZRange = lineExt(theseLines,:);
        index = find( (z>=getZRange(:,1)) &(z<=getZRange(:,2)));
        
        for nR=1:length(index)
            lineNum = theseLines(index(nR));
            %Find the interpolated z values at all these points on the line
            zVal = interp2(im,xArr{lineNum}(:), yArr{lineNum}(:));
            %Reshape the values
            zVal = reshape(zVal, size(xArr{lineNum},1), size(xArr{lineNum},2));
            zLevel = z-lineExt(lineNum,1)+1;
            radRegion{nR}(:,zLevel) = mean(zVal,1);            
        end        
        
    end
    
    fprintf(2,'\n');
    %Saving the results for these radial distributions
    fprintf(1, 'Saving the results for these scans...');
    for nR =1:length(theseLines)
        fprintf(1, '.');
        lineNum = theseLines(nR);
        filename = [param.dataSaveDirectory filesep 'radialDist' filesep 'rd.mat'];
        strEval = ['rd', num2str(lineNum), ' = radRegion{nR};'];
        eval(strEval);
        varName = ['rd', num2str(lineNum)];
        save(filename, varName, '-append', '-v7.3');
    end
    fprintf(1, 'done!\n');
    
end


end

%Initialize the array of points to calculate the radial distribution at,
%and the extent of each of these arrays in the z direction.
function [xArr, yArr, lineExt] = radialDistInit(line, mask, param, averageBox, averageBoxType)

minL = 2;
maxL = 75;

%Use cell arrays, because the size of the gut at any point may be different
xArr = cell(maxL-minL, 1);
yArr = cell(maxL-minL, 1);

aveVal = cell(maxL-minL,1);


for i=minL:maxL
    fprintf(1,'.');
    index = i-minL+1;
   [xArr{index}, yArr{index}] =radialDistSinglePoint(line, i, mask, param, averageBox, averageBoxType);
end
fprintf('\n')

fprintf(1, 'Calculating the z-extent of each of these regions...');
%Should at this point be able to pre-allocate memory for aveVal.
%Go through each line region found above and see which region in the
%registered image it corresponds.
numRegion = size(param.regionExtent.XY,1);
regExt = zeros(numRegion,4 );

for i=1:numRegion
    xMin =  param.regionExtent.XY(i,2);
    xMax = xMin-1 + param.regionExtent.XY(i,4);
    yMin = param.regionExtent.XY(i,1);
    yMax = yMin-1+param.regionExtent.XY(i,3);
    
    regExt(i,1) = xMin;
    regExt(i,2) = xMax;
    regExt(i,3) = yMin;
    regExt(i,4) = yMax;
end

testReg = zeros(length(xArr), numRegion);
for i=1:length(xArr)
   xMin = min(xArr{i}(:));xMax = max(xArr{i}(:));
   yMin = min(yArr{i}(:));yMax = max(yArr{i}(:));
   
   xMin = round(xMin);xMax = round(xMax);
   yMin = round(yMin); yMax = round(yMax);
   
   %Test to see if this set of lines is within a certain region
   %This code appears to work. Note that it'll get fubar'd if the gut outline
   %is larger than the cropped region, but this shouldn't happen.
   for j=1:numRegion
       xTest = (xMin>=regExt(j,1))*(xMax<=regExt(j,2));
       yTest = (yMin>=regExt(j,3))*(yMax<=regExt(j,4));
       testReg(i,j) = xTest*yTest;
   end
   
   
end


%Now construct an array that for each line that we'll calculate a radial
%distribution along contains the maximum and minimum z-depth that we'll go
%for that line.

%First get the maximum and minimum z depth for each region
%zDepth(:,1) contains the min, (:,2) the max.
zDepth = zeros(numRegion, 2);

for i=1:numRegion
    index = find(param.regionExtent.Z(:,i)~=-1);
    zDepth(i,1) = min(index);
    zDepth(i,2) = max(index);
end

lineExt = zeros(length(xArr), 2);

for i=1:length(xArr)
    thisLine = logical(testReg(i,:));
    temp = zDepth(thisLine,:);
    lineExt(i,1) = min(temp(:,1));
    lineExt(i,2) = max(temp(:,2));
end

fprintf(1,'done!\n');

end


%Returns the masks of points that will be used to calculate the radial
%distribution at a given point along the length of the gut.
    function [xArr, yArr] = radialDistSinglePoint(line, lineNum,mask, param, averageBox, averageBoxType)
        %% Reading in parameters
        xx = line(:,1);
        yy = line(:,2);
        
        switch averageBoxType
            case 'pixel'
                aveB = averageBox; %We'll average over pixels
            case 'micron'
                if(isfield(param, 'micronPerPixel'))
                    aveB = averageBox/param.micronPerPixel;
                else
                    aveB= averageBox/0.1625;
                end
        end
        %Round averaging box to nearest pixel
        aveB = round(aveB);
        
        %% Get array of points to calculate rad. dist. on
        %Find the index of points that lie within the gut-we'll use this as our
        %clumsy mask to only look at pixel intensities within the gut
 
        maskP = bwperim(mask);
        %dilate the boundary by a bit
        maskP = bwmorph(maskP, 'dilate');
        [indexGutY, indexGutX]  = find(maskP==1);
        indexGut = cat(2, indexGutX, indexGutY);
     
        %For a given point along the gut, get the orthogonal vector, for a series of
        %lines.
        x = xx(lineNum)-xx(lineNum-1);
        y = yy(lineNum)-yy(lineNum-1);
        xI = x+1;
        yI = y+2;
        
        %The length of these lines should be long enough to
        %intersect the gut...doesn't seem to be the case right now.
        Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
        
        xVal = xx(lineNum)+ Orth(1)*[-500:1:500];
        yVal = yy(lineNum)+ Orth(2)*[-500:1:500];
        
        indexLine = cat(2, round(xVal)', round(yVal)');
        xyInter = intersect(indexLine, indexGut, 'rows');
        
        xMax = max(xyInter(:,1)); xMin = min(xyInter(:,1));
        yMax = max(xyInter(:,2)); yMin = min(xyInter(:,2));
        
        %Get rid of elements of xVal and yVal outside the range of the mask
        index = find(round(xVal)>xMax |round(xVal)<xMin);
        xVal(index) = [];
        yVal(index) = [];
        
        index = find(round(yVal)>yMax |round(yVal)<yMin);
        xVal(index) = [];
        yVal(index) =[];
        
        %Replicate this array for points perpendicular to the line above. The line
        %will be replicated in step sizes of one pixel for a distance equal to
        %averageBox.
        
        
        orthVectX = xVal-xx(lineNum);
        orthVectY = yVal -yy(lineNum);
        
        xStep = x/sqrt(x^2 +y^2);
        yStep = y/sqrt(x^2 +y^2);
        xTemp = xx(lineNum)+ orthVectX +xStep;
        yTemp = yy(lineNum) + orthVectY + yStep;
        
        xArr(1,:) = xVal;
        yArr(1,:) = yVal;
        for i=1:aveB
            xArr(i+1,:) = xTemp;
            yArr(i+1,:) = yTemp;
            xTemp = xTemp+xStep;
            yTemp = yTemp + yStep;
        end
        
    end


