%data2hue.m
%
%convert raw HSV values into cylindrical feature space

function hsvOut = data2hue( hsvIn )

    %convert to degrees
    hsvIn(:,:,1) = round(hsvIn(:,:,1).*359);

    %what is the diameter of the circle that you want?
    %make it a multiple of 2. 130 diameter makes it possible for 360 colors,
    %which is a full circle of Hue, while 8 bit (256 colors) takes d = 76.
    d = 76;
    
%     %saturation should be adjusted according to value (intensity), as to
%     %form a bi-cone structure.
%     hsvIn(:,:,3) = hsvIn(:,:,3).*2;
%     tempI = hsvIn(:,:,3);
%     tempI(tempI > 1) = 2-tempI(tempI > 1);
%     hsvIn(:,:,2) = hsvIn(:,:,2).*(tempI./1);
%     
    hsvOut = zeros(size(hsvIn));
%     hsvOut(:,:,1) = cosd(hsvIn(:,:,1)).*(d/2).*hsvIn(:,:,2)+(d/2)+1;
%     hsvOut(:,:,2) = sind(hsvIn(:,:,1)).*(d/2).*hsvIn(:,:,2)+(d/2)+1;
    hsvOut(:,:,1) = cosd(hsvIn(:,:,1)).*(d/2).*hsvIn(:,:,2);
    hsvOut(:,:,2) = sind(hsvIn(:,:,1)).*(d/2).*hsvIn(:,:,2);

    hsvOut(:,:,3) = hsvIn(:,:,3).*d;
