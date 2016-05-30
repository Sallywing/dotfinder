function ImStkCut = JMPDotImageStackCutter(ImStk, Dots, DotNum, NumMargins, NumVoxs)


ImSize = size(ImStk);

%you can cut image stack (ImStk) around the dot(s) using Margins around the
%dot contour (NumMargins must be 3-element vector with y, x and z margins. 
%If this way is not used, NumMargins must be []. Or, use simply the number 
%of voxels to be cut (NumVoxs must be 3-element vector with y, x and z vox
%num. If this way is not used, NumVoxs must be []).
if ~isempty(NumMargins);
    ImStkCuty1 = max(Dots.Pos(DotNum,1)-NumMargins(1), 1);
    ImStkCuty2 = min(Dots.Pos(DotNum,1)+NumMargins(1), ImSize(1));
    ImStkCutx1 = max(Dots.Pos(DotNum,2)-NumMargins(2), 1);
    ImStkCutx2 = min(Dots.Pos(DotNum,2)+NumMargins(2), ImSize(2));
    ImStkCutz1 = max(Dots.Pos(DotNum,3)-NumMargins(3), 1);
    ImStkCutz2 = min(Dots.Pos(DotNum,3)+NumMargins(3), ImSize(3));
elseif ~isempty(NumVoxs);
    ImStkCuty1 = max(Dots.Pos(DotNum,1)-round(NumVoxs(1)/2), 1);
    ImStkCuty2 = min(Dots.Pos(DotNum,1)+round(NumVoxs(1)/2), ImSize(1));
    ImStkCutx1 = max(Dots.Pos(DotNum,2)-round(NumVoxs(2)/2), 1);
    ImStkCutx2 = min(Dots.Pos(DotNum,2)+round(NumVoxs(2)/2), ImSize(2));
    ImStkCutz1 = max(Dots.Pos(DotNum,3)-round(NumVoxs(3)/2), 1);
    ImStkCutz2 = min(Dots.Pos(DotNum,3)+round(NumVoxs(3)/2), ImSize(3));
else
    'Provide NumMargins or NumVoxs'
end
ImStkCut = ImStk(ImStkCuty1:ImStkCuty2, ImStkCutx1:ImStkCutx2, ImStkCutz1:ImStkCutz2);
