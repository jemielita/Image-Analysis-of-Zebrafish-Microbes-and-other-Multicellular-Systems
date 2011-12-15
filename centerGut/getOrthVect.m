 function pos = getOrthVect(xx, yy, type,i)
        
        switch lower(type)
            
            case 'rectangle'
                x = xx(i)-xx(i-1);
                y = yy(i)-yy(i-1);
                xI = x+1;
                yI = y+2;
                
                %The length of these lines should be long enough to
                %intersect the gut...doesn't seem to be the case right now.
                Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
                
                xVal(1,:) = xx(i)+ Orth(1)*(500)*[-1, 1];
                yVal(1,:) = yy(i)+ Orth(2)*(500)*[-1,1];
                
                xVal(2,:) = xx(i+1)+ Orth(1)*(500)*[-1, 1];
                yVal(2,:) = yy(i+1)+ Orth(2)*(500)*[-1,1];
                
                
            case 'curved'
                x = xx(i)-xx(i-1);
                y = yy(i)-yy(i-1);
                xI = x+1;
                yI = y+2;
                
                Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
                
                xVal(1,:) = xx(i)+ Orth(1)*(500)*[-1, 1];
                yVal(1,:) = yy(i)+ Orth(2)*(500)*[-1,1];
                
                
                x = xx(i+1)-xx(i);
                y = yy(i+1)-yy(i);
                xI = x+1;
                yI = y+2;
                
                Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
                
                
                xVal(2,:) = xx(i+1)+ Orth(1)*(500)*[-1, 1];
                yVal(2,:) = yy(i+1)+ Orth(2)*(500)*[-1,1];
                
                
        end
        
        pos = [xVal(1,1), yVal(1,1); xVal(1,2), yVal(1,2); xVal(2,2), yVal(2,2);...
            xVal(2,1), yVal(2,1)];
                
                
    end
