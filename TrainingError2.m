function err = TrainingError2(Thrsh, group, Colo, Dots, DotIdx, Settings)
    
    IntenThrsh = Thrsh(1);
    NoiseThrsh = Thrsh(2);
    InitColoMask = zeros(size(Colo),'uint8');
    InitColoMask(Colo >= IntenThrsh) = 1; % Apply user defined minimum intensity
    ColoMask = bwareaopen(InitColoMask,NoiseThrsh,6);
    
    ColoMinDists = zeros(1,length(group));
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
    
    if all(ColoMinDists == 0)
        err = 0.5;
    elseif sum(isnan(ColoMinDists)) > (length(ColoMinDists)/2)
        err = 1;
    else
        [C,err,P,logp,coeff] = classify([min(ColoMinDists)-1:0.002:max(ColoMinDists)+1]',ColoMinDists(~isnan(ColoMinDists))',group(~isnan(ColoMinDists)));
    end