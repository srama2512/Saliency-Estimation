function feat = getSuperpixelData( imdata )
    % extract the features of superpixels to accelrate the feature
    % extraction on multiple segmentations.
    % note: the histogram is not normalized, for the convinience of
    % computing segment (region) saliency feature
  
    spstats = imdata.spstats;
    imsegs = imdata.imsegs;
    
    image_rgb = imdata.image_rgb;
    image_lab = imdata.image_lab;
    
    Q = imdata.Q;
    hh = imdata.hh;
    ss = imdata.ss;
    xim = imdata.xim;
    yim = imdata.yim;
    imtext = imdata.imtext;
    texthist = imdata.texthist;
    texton = imdata.texton;
    imw = imdata.imw;
    imh = imdata.imh;
    
    nrgb = imdata.nrgb;
    nLab = imdata.nLab;
    nLabHist = imdata.nLabHist;
    nhhist = imdata.nhhist;
    nshist = imdata.nshist;
    ntexthist = imdata.ntexthist;
    nloc = imdata.nloc;
    ntext = imdata.ntext;
    ntexton = imdata.ntexton;
    
    nfeat = imdata.nrgb + imdata.nLab + imdata.nLabHist + imdata.nhhist + ...
        imdata.nshist + imdata.ntexthist + imdata.nloc + imdata.ntext + imdata.ntexton;
    nseg = imdata.imsegs.nseg;        
    feat = zeros( nseg, nfeat );
    
    for s = 1 : nseg
        % rgb means
        f = 0;
        for k = 1:3
            feat(s, f+k) = mean( image_rgb(spstats(s).PixelIdxList+(k-1)*imw*imh) );
        end
        f = f + 3;
        
        % Lab means
        for k = 1:3
            feat(s, f+k) = mean( image_lab(spstats(s).PixelIdxList+(k-1)*imw*imh) );
        end
        f = f + 3;
        
        % Lab histogram
        feat(s, f+[1:nLabHist]) = hist( Q(spstats(s).PixelIdxList), [1:nLabHist] );
        % feat(s, f+[1:nLabHist]) = feat(s, f+[1:nLabHist]) / sum(feat(s, f+[1:nLabHist]));
        f = f + nLabHist;
        
        % h histogram
        feat(s, f+[1:nhhist]) = hist( hh(spstats(s).PixelIdxList), [1:nhhist] );
        % feat(s, f+[1:nhhist]) = feat(s, f+[1:nhhist]) / sum(feat(s, f+[1:nhhist]));
        f = f + nhhist;
        
        % s histogram
        feat(s, f+[1:nshist]) = hist( ss(spstats(s).PixelIdxList), [1:nshist] );
        % feat(s, f+[1:nshist]) = feat(s, f+[1:nshist]) / sum(feat(s, f+[1:nshist]));
        f = f + nshist;
        
        % texture means
        for k = 1:ntext
            feat(s, f+k) = mean(imtext(spstats(s).PixelIdxList+(k-1)*imw*imh));
        end
        f = f + ntext;
        
        % texture histogram
        feat(s, f+(1:ntext)) = hist(texthist(spstats(s).PixelIdxList), [1:ntext]);
        % feat(s, f+(1:ntext)) = feat(s, f+(1:ntext)) / sum(feat(s, f+(1:ntext)));
        f = f + ntext;
        
        % texton histogram
        feat(s, f+(1:ntexton)) = hist(texton(spstats(s).PixelIdxList), [0:ntexton-1]);
        f = f + ntexton;
        
        % location
        xvals = xim( spstats(s).PixelIdxList );
        yvals = yim( spstats(s).PixelIdxList );
        feat(s, f+1) = mean(xvals);
        feat(s, f+2) = mean(yvals);
        sxvals = sort(xvals);
        syvals = sort(yvals);
        feat(s, f+3) = sxvals(ceil(numel(sxvals)/10));
        feat(s, f+4) = sxvals(ceil(9*numel(sxvals)/10));
        feat(s, f+5) = syvals(ceil(numel(syvals)/10));
        feat(s, f+6) = syvals(ceil(9*numel(syvals)/10));    
        feat(s, f+7) = (feat(s, f+4) - feat(s, f+3)) / ...
                       (feat(s, f+6) - feat(s, f+5) + eps);
        feat(s, f+8) = imsegs.npixels(s)/imh/imw;
    end
       