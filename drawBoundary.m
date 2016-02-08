function output = drawBoundary(newLBimg, I, drawColor)

if size(I,3) == 1
    I(:,:,2) = I(:,:,1);
    I(:,:,3) = I(:,:,1);
    I = uint8(I);
end


%draw the boundaries
imgTotal = size(I,1)*size(I,2);
uniqueLB = unique(newLBimg);
newImg = zeros(size(newLBimg));

for i = 1:length(uniqueLB)
    
    blankImg = newLBimg == uniqueLB(i);
    blankImg = bwmorph(blankImg, 'remove');
    newImg = newImg|blankImg;
    
end

%draw it back to the original image
bdInd = find(newImg == 1);

newImgC = I;
newImgC(bdInd) = drawColor(1);
newImgC(bdInd+imgTotal) = drawColor(2);
newImgC(bdInd+imgTotal*2) = drawColor(3);

output = newImgC;