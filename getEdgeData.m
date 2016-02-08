function edata = getEdgeData(spdata, imdata)
    % extract the features of adjacent superpixels to predict their
    % similarity to constrcut the graph for multiple segmentations.

    nfeatures = 31;

    imsegs = imdata.imsegs;
    nseg = imsegs.nseg;
    
    boundmap = imdata.boundmap;
    perim = imdata.perim;
    adjlist = imdata.adjlist;

    imh = imdata.imh;
    imw = imdata.imw;
    nrgb = imdata.nrgb;
    nLab = imdata.nLab;
    nLabHist = imdata.nLabHist;
    nhhist = imdata.nhhist;
    nshist = imdata.nshist;
    ntext = imdata.ntext;
    ntexton = imdata.ntexton;
    
    hist_type = imdata.hist_type;
    
    % do normalization first
    for s = 1 : size(spdata, 1)
        f = 6;
        spdata(s, f+[1:nLabHist] ) = spdata(s, f+[1:nLabHist] ) / sum(spdata(s, f+[1:nLabHist]) );
        f = f + nLabHist;
        
        spdata(s, f+[1:nhhist]) = spdata(s, f+[1:nhhist]) / sum(spdata(s, f+[1:nhhist]));
        f = f + nhhist;
        
        spdata(s, f+[1:nshist]) = spdata(s, f+[1:nshist]) / sum(spdata(s, f+[1:nshist]));
        f = f + nshist;
        
        f = f + ntext;
        
        spdata(s, f+[1:ntext]) = spdata(s, f+[1:ntext]) / sum(spdata(s, f+[1:ntext]));
        f = f + ntext;
        
        spdata(s, f+[1:ntexton]) = spdata(s, f+[1:ntexton]) / sum(spdata(s,f+[1:ntexton]));
    end

    nadj = size(adjlist, 1);
    
    edata = zeros(nadj, nfeatures);
    
    for k = 1:nadj
        s1 = adjlist(k, 1);
        s2 = adjlist(k, 2);

        f = 0;
        % abs differences of mean r, g, b
        edata(k, 1:nrgb) = abs(spdata(s1, 1:nrgb) - spdata(s2, 1:nrgb));
        f = f + nrgb;

        % abs differences of mean L, a, b
        edata(k, 4:6) = abs(spdata(s1, f+[1:nLab]) - spdata(s2, f+[1:nLab]));
        f = f + nLab;

        % x2 distance of L*a*b histogram    
        edata(k, 7) = histdist(spdata(s1, f+[1:nLabHist]), spdata(s2, f+[1:nLabHist]), hist_type);
        f = f + nLabHist;

        % x2 distance of hue histogram
        edata(k, 8) = histdist(spdata(s1, f+[1:nhhist]), spdata(s2, f+[1:nhhist]), hist_type);
        f = f + nhhist;

        % x2 distance of saturation histogram
        edata(k, 9) = histdist(spdata(s1, f+[1:nshist]), spdata(s2, f+[1:nshist]), hist_type);
        f = f + nshist;
    
        % differences of texture means
        edata(k, 9+[1:ntext]) = abs( spdata(s1, f+[1:ntext]) - spdata(s2, f+[1:ntext]) );
        f = f+ ntext;
        
        % x2 distance of texture response histogram
        edata(k, 25) = histdist( spdata(s1, f+[1:ntext]), spdata(s2, f+[1:ntext]), hist_type );
        f = f + ntext;
        
        % x2 distance of texton histogram
        edata(k, 26) = histdist( spdata(s1, f+[1:ntexton]), spdata(s2, f+[1:ntexton]), hist_type );
        f = f + ntexton;

        % location
        edata(k, 27:28) = abs(spdata(s1, f+[1:2]) - spdata(s2, f+[1:2]));
        f = f + 2;
        edata(k, 29) = min(spdata([s1 s2], size(spdata,2))) / max(spdata([s1 s2], size(spdata,2)));

        % boundary information
        edata(k, 30) = perim(s1, s2) / ...
            min(sum(perim(s1, :))+sum(perim(:, s1)), sum(perim(s2, :))+sum(perim(:, s2)));    
        
        bpix = boundmap{s1, s2};
        bx = double(floor((bpix-1)/imh)+1);
        by = double(mod((bpix-1), imh)+1);    
        edata(k, 31) = sqrt((max(bx)-min(bx)).^2 + (max(by)-min(by)).^2) / perim(s1, s2);
    end
end



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
