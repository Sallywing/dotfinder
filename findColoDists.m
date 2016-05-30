function ColoMinDists = findColoDists(Thrsh, Colo, Dots, DotIdx, Settings)
    
    IntenThrsh = Thrsh(1);
    NoiseThrsh = Thrsh(2);
    InitColoMask = zeros(size(Colo),'uint8');
    InitColoMask(Colo >= IntenThrsh) = 1; % Apply user defined minimum intensity
    ColoMask = bwareaopen(InitColoMask,NoiseThrsh,6);
    
    ColoMinDists = zeros(1,length(Dots));
    CutNumVox = [20, 20, 20];
    idx = 1;
    for DotNum = DotIdx
       [ColoMaskCut, ColoCutDotPos] = JMPDotImageStackCutterWithLoc(ColoMask,Dots, DotNum, CutNumVox); % Focus on small section of mask
       ColoDistMask = JMPCalcDistDot2Mask(Settings,ColoMaskCut,ColoCutDotPos); % Replace 1's in mask with distance to dot
       if ~isempty(find(ColoMaskCut == 1))
           ColoMinDists(idx) = min(ColoDistMask(find(ColoMaskCut == 1))); % Find the point in mask that is closest to dot
       else
           ColoMinDists(idx) = NaN;
       end
       idx = idx + 1;
    end