function pbgfeat = getPbgFeat( imdata )
    % get pseudo-background feature
    % the pseudo-background is estimated as the border area of the image
    
    borderwidth = 15;
    
    % get pixels in the probable background 
    [h w c] = size( imdata.image_rgb );
    pixels = [1 : h * borderwidth]';
    pixels = [pixels; [h*w : -1 : (h*w - borderwidth*h +1)]'];
    n = 16 : w - 15;
    y1 = 1 : 15;
    y2 = h-14 : h;
    [nn1 yy1] = meshgrid( n, y1 );
    ny1 = (nn1 - 1) * h + yy1;
    pixels = [pixels; ny1(:)];
    [nn2 yy2] = meshgrid( n, y2 );
    ny2 = (nn2 - 1) * h + yy2;
    pixels = [pixels; ny2(:)];    
    
    nfeat = imdata.nrgb + imdata.nLab + imdata.nLabHist + imdata.nhhist + ...
        imdata.nshist + imdata.ntexthist + imdata.nloc + imdata.ntext + imdata.ntexton;
    pbgfeat = zeros( 1, nfeat );
    
    % get features
    % rgb means
    f = 0;
    for k = 1:3
        pbgfeat( f+k ) = mean( imdata.image_rgb(pixels + h*w*(k-1)) );
    end
    f = f + 3;

    % Lab means
    for k = 1:3
        pbgfeat( f+k ) = mean( imdata.image_lab(pixels + (k-1)*h*w) );
    end
    f = f + 3;

    % Lab histogram
    pbgfeat( f+[1:imdata.nLabHist] ) = hist( imdata.Q(pixels), [1:imdata.nLabHist] );
    pbgfeat( f+[1:imdata.nLabHist] ) = pbgfeat( f+[1:imdata.nLabHist] ) / sum( pbgfeat(f+[1:imdata.nLabHist]) );
    f = f + imdata.nLabHist;

    % h histogram
    pbgfeat( f + [1:imdata.nhhist] ) = hist( imdata.hh(pixels), [1:imdata.nhhist] );
    pbgfeat( f + [1:imdata.nhhist] ) = pbgfeat( f + [1:imdata.nhhist] ) / sum( pbgfeat(f+[1:imdata.nhhist]) );
    f = f + imdata.nhhist;

    % s histogram
    pbgfeat( f + [1:imdata.nshist] ) = hist( imdata.ss(pixels), [1:imdata.nshist] );
    pbgfeat( f + [1:imdata.nshist] ) = pbgfeat( f + [1:imdata.nshist] ) / sum( pbgfeat(f+[1:imdata.nshist]) );
    f = f + imdata.nshist;

    % texture histogram
    for k = 1 : imdata.ntext
        pbgfeat(f+k) = mean( imdata.imtext(pixels+(k-1)*w*h) );
    end
    f = f + imdata.ntext;

    % texture histogram
    pbgfeat( f + [1:imdata.ntext] ) = hist( imdata.texthist(pixels), [1:imdata.ntext] );
    pbgfeat( f + [1:imdata.ntext] ) = pbgfeat( f + [1:imdata.ntext] ) / sum( pbgfeat(f + [1:imdata.ntext]) );
    f = f + imdata.ntext;

    % texton histogram
    pbgfeat( f + [1:imdata.ntexton] ) = hist( imdata.texton(pixels), [0:imdata.ntexton-1] );
    pbgfeat( f + [1:imdata.ntexton] ) = pbgfeat( f + [1:imdata.ntexton] ) / sum( pbgfeat( f + [1:imdata.ntexton] ) );
    f = f + imdata.ntexton;

    % location
    xvals = imdata.xim( pixels );
    yvals = imdata.yim( pixels );
    pbgfeat( f+1 ) = mean(xvals);
    pbgfeat( f+2 ) = mean(yvals);
    sxvals = sort(xvals);
    syvals = sort(yvals);
    pbgfeat( f+3 ) = sxvals(ceil(numel(sxvals)/10));
    pbgfeat( f+4 ) = sxvals(ceil(9*numel(sxvals)/10));
    pbgfeat( f+5 ) = syvals(ceil(numel(syvals)/10));
    pbgfeat( f+6 ) = syvals(ceil(9*numel(syvals)/10));    
    pbgfeat( f+7 ) = (pbgfeat(f+4) - pbgfeat(f+3)) / ...
                   (pbgfeat(f+6) - pbgfeat(f+5) + eps);
    pbgfeat(f+8) = length(pixels)/h/w;     % useless