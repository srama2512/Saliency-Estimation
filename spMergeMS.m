%spMergeMS.m
%
%performs mean-shift clustering to find out the number and the centers for
%color clusters from superpixels.

function output = spMergeMS(img, alpha, labels, smooth, bandwidth, cSpace, toShow )

%make sure the label values start with 1
if min(min(labels)) == 0
    labels = labels+1;
end

maxSP = max(max(labels));

%smooth the image a bit if specified
if smooth > 0
    hsize = smooth;
    sigma = hsize/5;
    g = fspecial('Gaussian', [hsize hsize], sigma);
    img2 = imfilter(double(img), g, 'conv', 'same', 'replicate');
else
    img2 = double(img);
end


img0a = double(img(:,:,1));
img0b = double(img(:,:,2));
img0c = double(img(:,:,3));

if strcmp(cSpace, 'hsv') == 1
    img2 = rgb2hsv(img2);
%     temp2 = img2(:,:,3)./255;
    img2(:,:,3) = img2(:,:,3)./255;

    img2 = data2hue(img2);

elseif strcmp(cSpace, 'lab') == 1
    img2 = RGB2Lab(img2);
end
img2a = img2(:,:,1);
img2b = img2(:,:,2);
img2c = img2(:,:,3);

x = zeros(3,maxSP);
xMed = x;
%perform mean-shift clustering from mean colors of the superpixels
for i = 1:maxSP
    
    spList{i} = find(labels == i);
    
    x(:,i) = [mean(img2a(spList{i})); mean(img2b(spList{i})); mean(img2c(spList{i}))];
    xMed(:,i) = [median(img2a(spList{i})); median(img2b(spList{i})); median(img2c(spList{i}))];
    
end


[clustCent,point2cluster,clustMembsCell] = MeanShiftCluster(x,bandwidth);
[clustCent2,point2cluster2,clustMembsCell2] = MeanShiftCluster(xMed,bandwidth);
numClust = length(clustMembsCell);
numClust2 = length(clustMembsCell2);

%assign each superpixel to the closest color cluster
x2 = x';
cCenters = clustCent';
meanLabels = zeros(size(labels));
for i = 1:maxSP
    
    cDist = pdist2(x2(i,:), cCenters);
    [~, ind] = min(cDist);
    meanLabels(spList{i}) = ind;
    
end

%make sure each merged region doesn't have a repeating ID
tLabels = meanLabels;
meanLabels = zeros(size(labels));
count = 1;
meanLBsize = [];

for i = 0:max(max(tLabels))
    
    [bw, num] = bwlabel(tLabels == i);
    
    for j = 1:num
        
        meanLabels(bw == j) = count;
        
        %save the size of this proto-object, excluding background
        if ~isempty(alpha)
            isBG = mode(double(alpha(bw == j)));
            if isBG > 0
                meanLBsize(end+1,1) = count;
                meanLBsize(end,2) = length(find(meanLabels == count));
            end
        end
        count = count + 1;
    end
    
end

% paint part
%paint the mean and median colors back
meanImg = zeros(size(img));
medImg = zeros(size(img));
imgTotal = size(img,1)*size(img,2);

meanList = unique(meanLabels);
meanSegments = 0;

for i = 1:length(unique(meanLabels))
    
    spList2 = find(meanLabels == i);
    meanImg(spList2) = mean(img0a(spList2));
    meanImg(spList2+imgTotal) = mean(img0b(spList2));
    meanImg(spList2+imgTotal*2) = mean(img0c(spList2));
    
end

meanSegments = length(unique(meanLabels));


%assign each superpixel to the closest color cluster ------ for median
xMed2 = xMed';
cCenters2 = clustCent2';
medLabels = zeros(size(labels));
for i = 1:maxSP
    
    cDist = pdist2(xMed2(i,:), cCenters2);
    [~, ind] = min(cDist);
    medLabels(spList{i}) = ind;
    
end

%make sure each merged region doesn't have a repeating ID
tLabels = medLabels;
medLabels = zeros(size(labels));
medLBsize = [];
count = 1;
for i = 0:max(max(tLabels))
    
    [bw, num] = bwlabel(tLabels == i);
    
    for j = 1:num
        
        medLabels(bw == j) = count;
        
        %save the size of this proto-object
        if ~isempty(alpha)
            isBG = mode(double(alpha(bw == j)));
            if isBG > 0
                medLBsize(end+1,1) = count;
                medLBsize(end,2) = length(find(medLabels == count));
            end
        end
        
        count = count + 1;
    end
    
end

%% paint part
%paint the mean and median colors back ----- for median
medList = unique(medLabels);
medSegments = 0;

for i = 1:length(unique(medLabels))
    
    spList2 = find(medLabels == i);
    medImg(spList2) = median(img0a(spList2));
    medImg(spList2+imgTotal) = median(img0b(spList2));
    medImg(spList2+imgTotal*2) = median(img0c(spList2));
    
end

%figure, imshow(meanBW,[]);
%medBW = drawBoundary(medLabels, medBW, [255,0,0]);
medSegments = length(unique(medLabels));


%% outputs
meanSegs{1} = drawBoundary(meanLabels, img, [255,0,0]);
medSegs{1} = drawBoundary(medLabels, img, [255,0,0]);
meanSegs{2} = uint8(meanImg);
medSegs{2} = uint8(medImg);

%visualize
if toShow == 1
    
    %figure('Color',[1 1 1]), imshow(drawBoundary(labels, img, [255,0,0]));
    %title('Superpixel segmentation');
    
    %MarkerEdgeColors = lines(numClust);  % n is the number of different items you have
    %MarkerEdgeColors2 = lines(numClust2); 
    %Markers=['o','x','+','*','s','d','v','^','<','>','p','h','.',...
    %    '+','*','o','x','^','<','h','.','>','p','s','d','v',...
    %    'o','x','+','*','s','d','v','^','<','>','p','h','.'];
    
    %figure('Color',[1 1 1]), hold on
    %for k = 1:min(numClust,length(cVec))
    for k = 1:numClust
        myMembers = clustMembsCell{k};
        %myClustCen = clustCent(:,k);
        %scatter3(x(1,myMembers),x(2,myMembers),x(3,myMembers),50, MarkerEdgeColors(k,:), 'filled', 'MarkerEdgeColor', [0,0,0]);
        %scatter3(myClustCen(1),myClustCen(2),myClustCen(3),'o','MarkerEdgeColor','k','MarkerFaceColor',cVec(k), 'MarkerSize',10)
    end
    %view(-34, 14);
    %title(['Number of Clusters (mean): ' int2str(numClust)], 'FontSize', 16, 'FontWeight', 'bold');
    %colorbar('location', 'EastOutside', 'YTickLabel', {[1:numClust]});
%     xlabel('Hue');
%     ylabel('Saturation');
    %zlabel('Value', 'FontSize', 13, 'FontWeight', 'bold');
    %grid on;
    
    if strcmp(cSpace, 'hsv') == 1
        R= [38, 38];
        N = 100;
        [X,Y,Z] = cylinder(R,N);
        %testSurf = surf(X,Y,Z,'FaceAlpha',0.2);
        %set(testSurf, 'EdgeColor','blue','EdgeAlpha',0.9,...
        %    'DiffuseStrength',1,'AmbientStrength',1)
    end
    satLine = line([0, 38], [0,0], [0,0]);
    %set(satLine, 'lineWidth', 1.5, 'color', 'r');
    
    hueText = text(38, -7, 4, '\leftarrowHue=0','FontWeight', 'bold');
    %set(hueText, 'color', 'b', 'FontSize', 13);
    
    satText = text(0, -10, 0, '\uparrowSaturation', 'FontWeight', 'bold');
    %set(satText, 'color', 'r', 'FontSize', 13)
    
    %figure('Color',[1 1 1]), hold on
    %for k = 1:min(numClust,length(cVec))
    for k = 1:numClust2
        myMembers = clustMembsCell2{k};
        %myClustCen = clustCent(:,k);
        %scatter3(xMed(1,myMembers),xMed(2,myMembers),xMed(3,myMembers),50, MarkerEdgeColors2(k,:), 'filled', 'MarkerEdgeColor', [0,0,0]);
        %scatter3(myClustCen(1),myClustCen(2),myClustCen(3),'o','MarkerEdgeColor','k','MarkerFaceColor',cVec(k), 'MarkerSize',10)
    end
    %view(-34, 14);
    %title(['Number of Clusters (median): ' int2str(numClust2)], 'FontSize', 16, 'FontWeight', 'bold');
    %colorbar('location', 'EastOutside', 'YTickLabel', {[1:numClust]});
%     xlabel('Hue');
%     ylabel('Saturation');
    %zlabel('Value', 'FontSize', 13, 'FontWeight', 'bold');
    %grid on;
    if strcmp(cSpace, 'hsv') == 1
        R= [38, 38];
        N = 100;
        [X,Y,Z] = cylinder(R,N);
        %testSurf = surf(X,Y,Z,'FaceAlpha',0.2);
        %set(testSurf, 'EdgeColor','blue','EdgeAlpha',0.9,...
        %   'DiffuseStrength',1,'AmbientStrength',1)
    end
    %satLine = line([0, 38], [0,0], [0,0]);
    %set(satLine, 'lineWidth', 1.5, 'color', 'r');
    
    hueText = text(38, -7, 4, '\leftarrowHue=0','FontWeight', 'bold');
    %set(hueText, 'color', 'b', 'FontSize', 13);
    
    satText = text(0, -10, 0, '\uparrowSaturation', 'FontWeight', 'bold');
    %set(satText, 'color', 'r', 'FontSize', 13)
    
    %hold off;
    %{
    figure('Color',[1 1 1]), imshow(meanSegs{1}); title('Proto-object Segmentation (mean)');
    figure('Color',[1 1 1]), imshow(medSegs{1}); title('Proto-object Segmentation (median)');
    figure('Color',[1 1 1]), imshow(meanSegs{2}); title('Proto-object Visualization (mean)');
    figure('Color',[1 1 1]), imshow(medSegs{2}); title('Proto-object Visualization (median)');
    %}
end

output{1} = meanSegments;
output{2} = medSegments;
output{3} = meanLabels;
output{4} = medLabels;
output{5} = meanSegs;
output{6} = medSegs;


% output{7} = meanBW;
% output{8} = medBW;











