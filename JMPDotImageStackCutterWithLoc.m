function [ImStkCut,DotCutPos] = JMPDotImageStackCutterWithLoc(ImStk, Dots, DotNum, NumMargins)
%Same as JMPImageStackCutter, but this function only works with margins and
%also returns the position of the Dot within the cut.

ImSize = size(ImStk);

ImStkCuty1 = max(Dots.Pos(DotNum,1)-NumMargins(1), 1);
ImStkCuty2 = min(Dots.Pos(DotNum,1)+NumMargins(1), ImSize(1));
ImStkCutx1 = max(Dots.Pos(DotNum,2)-NumMargins(2), 1);
ImStkCutx2 = min(Dots.Pos(DotNum,2)+NumMargins(2), ImSize(2));
ImStkCutz1 = max(Dots.Pos(DotNum,3)-NumMargins(3), 1);
ImStkCutz2 = min(Dots.Pos(DotNum,3)+NumMargins(3), ImSize(3));

DotCutPosY = (Dots.Pos(DotNum,1) - ImStkCuty1) + 1;
DotCutPosX = (Dots.Pos(DotNum,2) - ImStkCutx1) + 1;
DotCutPosZ = (Dots.Pos(DotNum,3) - ImStkCutz1) + 1;
DotCutPos = [DotCutPosY, DotCutPosX, DotCutPosZ];
ImStkCut = ImStk(ImStkCuty1:ImStkCuty2, ImStkCutx1:ImStkCutx2, ImStkCutz1:ImStkCutz2);
