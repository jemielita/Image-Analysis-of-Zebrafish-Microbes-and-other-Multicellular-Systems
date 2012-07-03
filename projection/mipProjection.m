%Calculate the maximum intensity projection for a given scan

function imTot = mipProjection( param, autoLoad, imVar)

colorNum =  find(strcmp(param.color, imVar.color));
totNumRegions = size(param.regionExtent.XY{colorNum},1);

imTot = zeros(param.regionExtent.regImSize{colorNum});

if(strcmp(autoLoad, 'true'))
    if(isfield(param, 'dataSaveDirectory'))
        mip = load([param.dataSaveDirectory filesep 'FluoroScan_', num2str(imVar.scanNum), '.mat']);
        mip = mip.mip;
       imTot = mip{colorNum};
    end
else
    
    for nR=1:totNumRegions
        
        %Get the range of pixels that we will read from and read out to.
        xOutI = param.regionExtent.XY{colorNum}(nR,1);
        xOutF = param.regionExtent.XY{colorNum}(nR,3)+xOutI-1;
        
        yOutI = param.regionExtent.XY{colorNum}(nR,2);
        yOutF = param.regionExtent.XY{colorNum}(nR,4)+yOutI -1;
        
        xInI = param.regionExtent.XY{colorNum}(nR,5);
        xInF = xOutF - xOutI +xInI;
        
        yInI = param.regionExtent.XY{colorNum}(nR,6);
        yInF = yOutF - yOutI +yInI;
        
        im = load3dVolume(param,imVar,nR);
        fprintf(2, '.');
        mipR = max(im,[],3); %Get the maximum intensity projection for this region
        imTot(xOutI:xOutF, yOutI:yOutF) = mipR + imTot(xOutI:xOutF, yOutI:yOutF);
    end
    
    for regNum = 2:totNumRegions
        %Overlapping regions
        %This is potentially slow (however we need to be as quick as possible with this type of thing).
        %After we know this code works, we'll come back and write quicker code.
        imTot(param.regionExtent.overlapIndex{colorNum,regNum-1} )= ...
            0.5*imTot(param.regionExtent.overlapIndex{colorNum,regNum-1});
        %    im(:) =1;
        %   im(param.regionExtent.overlapIndex{regNum-1} ) = 0;
        
    end
    
end

end