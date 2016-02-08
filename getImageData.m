function imdata = getImageData( image, textons, imsegs )
    if ~exist('imsegs', 'var')
        imsegs = im2superpixels( image, 'pedro' );
    end
    imdata.imsegs = imsegs;
    
    spstats = regionprops(imsegs.segimage, 'PixelIdxList');
    imdata.spstats = spstats;
    
    [boundmap, perim] = mcmcGetSuperpixelBoundaries_fast(imsegs);

    nadj = 0;
    for s1 = 1:imsegs.nseg
        nadj = nadj + numel(find(perim(s1, s1+1:end)>0));
    end

    % get superpixel adjacency matrix
    adjlist = zeros(nadj, 2);
    c = 0;
    for s1 = 1:imsegs.nseg
        ns1 = numel(find(perim(s1, s1+1:end)>0));
        adjlist(c+1:c+ns1, 1) = s1;
        adjlist(c+1:c+ns1, 2) = s1 + find(perim(s1, s1+1:end)>0);
        c = c + ns1;
    end
    
    imdata.boundmap = boundmap;
    imdata.perim = perim;
    imdata.adjlist = adjlist;
    
    g = fspecial('gaussian', 5);
    image = imfilter(image, g, 'same');
    image_rgb = double( image );
    image_lab = rgb2lab( image_rgb );
    image_hsv = rgb2hsv( image_rgb );
    imdata.image_rgb = image_rgb;
    imdata.image_lab = image_lab;
    imdata.image_hsv = image_hsv;
    
    [imh imw dummy] = size( image_rgb );    
    imdata.imh = imh;
    imdata.imw = imw;
    
    nrgb = 3;
    nLab = 3;
    Lab_bins = [8 16 16];
    nLabHist = prod(Lab_bins);
    nhhist = 8;
    nshist = 8;
    ntexthist = 15;
    nloc = 8; % mean x-y, 10th, 90th percentile x-y, w/h, area
    filtext = makeLMfilters;
    ntext = size(filtext, 3);
    
    imdata.nrgb = nrgb;
    imdata.nLab = nLab;
    imdata.nLabHist = nLabHist;
    imdata.nhhist = nhhist;
    imdata.nshist = nshist;
    imdata.ntexthist = ntexthist;
    imdata.nloc = nloc;
    imdata.ntext = ntext;    
    imdata.ntexton = 64;		% oops, error, should be 65
    
    L = image_lab(:,:,1);
    a = image_lab(:,:,2);
    b = image_lab(:,:,3);
    h = image_hsv(:,:,1);
    s = image_hsv(:,:,2);
    
    % color histogram
    ll = min(floor(L/(100/Lab_bins(1))) + 1, Lab_bins(1));
    aa = min(floor((a+120)/(240/Lab_bins(2))) + 1, Lab_bins(2));
    bb = min(floor((b+120)/(240/Lab_bins(3))) + 1, Lab_bins(3));
    Q = (ll-1) * Lab_bins(2) * Lab_bins(3) + ...
        (aa-1) * Lab_bins(3) + ...
        bb + 1;
    hh = min(floor(h*nhhist) + 1, nhhist);
    ss = min(floor(s*nshist) + 1, nshist);
    
    imdata.Q = Q;
    imdata.hh = hh;
    imdata.ss = ss;
    
    % texton 
    if ~isempty( textons )
       imdata.texton = textons; 
    else
        % extract textons if not provided, 
        im = im2double(image);
        t = tic;
        imdata.texton = mex_pb_parts_final_selected(im(:,:,1), im(:,:,2), im(:,:,3));
        fprintf( '\t*** time cost for textons computing: %.3f\n', toc(t) );
    end
    
    grayim = rgb2gray( image );
    imtext = zeros([imh imw ntext]);
    for f = 1:ntext
        imtext(:, :, f) = abs(imfilter(im2single(grayim), filtext(:, :, f), 'same'));    
    end
    [tmp, texthist] = max(imtext, [], 3);
    imdata.imtext = imtext;
    imdata.texthist = texthist;
    
    % location
    yim = 1-repmat(((0:imh-1)/(imh-1))', 1, imw);
    xim = repmat(((0:imw-1)/(imw-1)), imh, 1);
    
    imdata.xim = xim;
    imdata.yim = yim;
    
    imdata.hist_type = 'x2';
