% feat          [output] region's saliency features
% imdata        [input] processed image data for feature extraction
% spFeat        [input] superpixel features (color and texture)
% pbgFeat       [input] the pseudo-background features (color and texture)
% spLabel       [input] superpixel labels indicating the hierarchical grouping information
% sinds         [input] region label

% contact:      jianghuaizu@gmail.com
function feat = getSegmentSaliencyFeat( imdata, spFeat, pbgFeat, spLabel, sinds)
    imsegs = imdata.imsegs;
    stats = imdata.spstats;
    adjlist = imdata.adjlist;
    imsegs.adjlist = adjlist;
    
    r = double(imdata.image_rgb(:,:,1));
    g = double(imdata.image_rgb(:,:,2));
    b = double(imdata.image_rgb(:,:,3));
    L = imdata.image_lab(:,:,1);
    a = imdata.image_lab(:,:,2);
    bb = imdata.image_lab(:,:,3);
    h = imdata.image_hsv(:,:,1);
    s = imdata.image_hsv(:,:,2);
    imtext = imdata.imtext;
    
    imgray = rgb2gray(imdata.image_rgb);
    imgray = imresize(imgray, [200 200]);
    
   % featGabor = gaborFeatures(imgray, gaborArray, int16(size(imgray,1)/2), int16(size(imgray,2)/2));

    nsegments = length(sinds);
    nfeat = 87;%+size(featGabor,1);
    feat = zeros( nsegments, nfeat );
    
    hist_type = imdata.hist_type;
    
    for ix = 1 : nsegments
        % find superpixels which are grouped together to form a segment
        spind = find( spLabel == sinds(ix) );
        pixels = getPixels( stats, spind );         % get corresponding pixel indexes
        % get the color and texture features of the segment
        segdata = getColorTextFeat( imdata, spFeat, spind );
        
        % find adjacent regions
        adjspind = getAdjSegment( imsegs, spLabel, sinds(ix) );
        
        if isempty( adjspind )
            adjsegdata = segdata;
        else
            adjsegdata = getColorTextFeat( imdata, spFeat, adjspind );
        end
        
        % contrast descriptor
        f = imdata.nrgb + imdata.nLab;
        feat(ix, 1:f) = abs( segdata(1:f) - adjsegdata(1:f) );
        
        feat(ix, 7) = histdist( segdata(f+[1:imdata.nLabHist]), adjsegdata(f+[1:imdata.nLabHist]), hist_type );
        f = f + imdata.nLabHist;
        
        feat(ix, 8) = histdist( segdata(f+[1:imdata.nhhist]), adjsegdata(f+[1:imdata.nhhist]), hist_type );
        f = f + imdata.nhhist;
        
        feat(ix, 9) = histdist( segdata(f+[1:imdata.nshist]), adjsegdata(f+[1:imdata.nshist]), hist_type );
        f = f + imdata.nshist;
        
        feat(ix, 9+[1:imdata.ntext]) = abs( segdata(f+[1:imdata.ntext]) - adjsegdata(f+[1:imdata.ntext]) );
        f = f + imdata.ntext;
        
        feat(ix, 25) = histdist( segdata(f+[1:imdata.ntext]), adjsegdata(f+[1:imdata.ntext]), hist_type );
        f = f + imdata.ntext;
        
        feat(ix, 26) = histdist( segdata(f+[1:imdata.ntexton]), adjsegdata(f+[1:imdata.ntexton]), hist_type );
        
        % backgroundness descriptor
        f = imdata.nrgb + imdata.nLab;
        feat(ix, 26+[1:f]) = abs( segdata(1:f) - pbgFeat(1:f) );
        
        feat(ix, 33) = histdist( segdata(f+[1:imdata.nLabHist]), pbgFeat(f+[1:imdata.nLabHist]), hist_type );
        f = f + imdata.nLabHist;
        
        feat(ix, 34) = histdist( segdata(f+[1:imdata.nhhist]), pbgFeat(f+[1:imdata.nhhist]), hist_type );
        f = f + imdata.nhhist;
        
        feat(ix, 35) = histdist( segdata(f+[1:imdata.nshist]), pbgFeat(f+[1:imdata.nshist]), hist_type );
        f = f + imdata.nshist;
        
        feat(ix, 35+[1:imdata.ntext]) = abs( segdata(f+[1:imdata.ntext]) - pbgFeat(f+[1:imdata.ntext]) );
        f = f + imdata.ntext;
        
        feat(ix, 51) = histdist( segdata(f+[1:imdata.ntext]), pbgFeat(f+[1:imdata.ntext]), hist_type );
        f = f + imdata.ntext;
        
        feat(ix, 52) = histdist( segdata(f+[1:imdata.ntexton]), pbgFeat(f+[1:imdata.ntexton]), hist_type );
        
        % property descriptor
        feat(ix, 53) = length(pixels) / imdata.imh / imdata.imw;       % size
        feat(ix, 54) = length(spind) / imsegs.nseg;
        xvals = imdata.xim( pixels );
        yvals = imdata.yim( pixels );
        feat(ix, 55) = mean(xvals);
        feat(ix, 56) = mean(yvals);
        
        x = sort( xvals );
        y = sort( yvals );
        feat(ix, 57) = x( ceil(numel(x)/10) );
        feat(ix, 58) = x( ceil(9*numel(x)/10) );
        feat(ix, 59) = y( ceil(numel(y)/10) );
        feat(ix, 60) = y( ceil(9*numel(y)/10) );
        feat(ix, 61) = (feat(ix, 58) - feat(ix, 57)) / ...
                          (feat(ix, 60) - feat(ix, 59) + eps);
                      
        feat(ix, 62) = length(adjspind) / imsegs.nseg;
        feat(ix, 63) = sum(imsegs.npixels(adjspind)) / imdata.imw / imdata.imh;
    
        feat(ix, 64) = var( r(pixels) );
        feat(ix, 65) = var( g(pixels) );
        feat(ix, 66) = var( b(pixels) );
        feat(ix, 67) = var( L(pixels) );
        feat(ix, 68) = var( a(pixels) );
        feat(ix, 69) = var( bb(pixels) );
        feat(ix, 70) = var( h(pixels) );
        feat(ix, 71) = var( s(pixels) );

        for ii = 1 : imdata.ntext
            temp_text = imtext(:,:,ii);
            feat(ix, 71+ii) = var( temp_text(pixels) );
        end

        [imh imw] = size(r);
        feat(ix, 87) = length(pixels) / imh / imw;
        %feat(ix, 88:end) = featGabor;
    end
end % end of function getSegmentFeat
    
function output_adjspind = getAdjSegment( imsegs, spLabel, sind )
    for k = 1 : length(sind)
        adjsegind = [];
        tempspind = find( spLabel == sind(k) );
        % tempspind = find( spLabel == sind );
        for s = 1 : length(tempspind)            
            ind = find( imsegs.adjlist(:,1) == tempspind(s) );
            if ~isempty( ind )
                adjsegind = [adjsegind; spLabel(imsegs.adjlist(ind, 2))];
            end

            ind = find( imsegs.adjlist(:, 2) == tempspind(s) );
            if ~isempty( ind )
                adjsegind = [adjsegind; spLabel(imsegs.adjlist(ind, 1))];
            end
        end

        adjsegind = unique( adjsegind );
        segind = sind(k);
        % segind = sind;
        output_adjspind = [];
        for s = 1 : length(adjsegind)
            if adjsegind(s) ~= segind
                ind = find( spLabel == adjsegind(s) );
                output_adjspind = [output_adjspind; ind];
            end
        end
   end        
end % end of function getAdjSegment
    
function output_pixelind = getPixels( stats, spinds )
    output_pixelind = [];
    for k = 1 : length(spinds)
        sp = spinds(k);
        output_pixelind = [output_pixelind; stats(sp).PixelIdxList];
    end
end % end of function getPixels

function diff = histdist( hist1, hist2, method )
    switch method
        case 'x2'
            diff = 0.5 * sum( (hist1 - hist2).^2 ./ (hist1 + hist2 + eps) );
        case 'jsd'      % Jensen-Shannon Divergence
            diff = 0.5*(sum(hist1.*log((hist1+eps)./(hist2+eps))) + sum(hist2.*log((hist2+eps)./(hist1+eps))));
        otherwise
            error( 'unknown type for computing histogram distance' );
    end
end