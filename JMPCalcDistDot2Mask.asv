function DistDot2Mask = JMPCalcDistDot2Mask(Settings,ColoMask,DotPos)
%ColoMask must be a binary 3d matrix. This function replaces each 1 in
%ColoMask with its distance from DotPos.

xyum = Settings.ImInfo.xyum;
zum = Settings.ImInfo.zum;
szColoMask = size(ColoMask);
DistDot2Mask = zeros(szColoMask);
for y = 1:szColoMask(1)
    for x = 1:szColoMask(2)
        for z = 1:szColoMask(3)
            DistDot2Mask(y,x,z) = sqrt((xyum*(DotPos(1) - y))^2 + (xyum*(DotPos(2) - x))^2 + (zum*(DotPos(3) - z))^2);
        end
    end
end

for i = 1:numel(ColoMask)
    DistDot2Mask(i) = DistDot2Mask(i) * ColoMask(i);
end

