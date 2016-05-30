function [Accuracies, Thresholds] = JMPCalcThreshAccuracy(StartingThreshold,ColocFlagFish,MinDists)
%Determine the most accurate threshold between 100% - 0% of the max - JMP
%07-08-2015

Thresholds = 1 - (0:20) * .05; %percentages
Thresholds = Thresholds * StartingThreshold;
Accuracies = zeros(1, numel(Thresholds));
idx = 1;
for Thresh = Thresholds
    TestColocFlagFish = zeros(1,numel(MinDists));    
    for J = 1:numel(MinDists)
        if MinDists(J) <= Thresh
            TestColocFlagFish(J) = 1;
        else
            TestColocFlagFish(J) = 2;
        end    
    end
    Accuracy = TestColocFlagFish == ColocFlagFish;
    Accuracy = numel(Accuracy(Accuracy == 1));
    NumFalseOrSkip = sum(ColocFlagFish == 3) + sum(ColocFlagFish == 4);
    Accuracy = Accuracy / double(numel(MinDists) - NumFalseOrSkip);
    Accuracies(idx) = Accuracy;
    idx = idx + 1;
end