function [] = calculateGutFluorescence

        imVar.color = param.color{nC};
        imVar.zNum = '';%Won't need this for mip
        imVar.scanNum = 1;
        
        im = selectProjection(paramA5, 'total', 'false', imVar);