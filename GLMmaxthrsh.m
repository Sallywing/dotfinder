function [accu,thrsh] = GLMmaxthrsh(x,y,dis,link,cutoff)
% fit GLM model to classify data and use cutoff to find the accuracy of
% classification and the corresponding thrshold
% x: one variable
% y: group
% Created by Wan-Qing Yu 2015.10.13

if nargin < 5
    cutoff = 0.5;
end

g = GeneralizedLinearModel.fit(x,y,...
    'linear','distr',dis,'link',link);
yfit = predict(g, x);
yy(yfit>cutoff)=1;
yy(yfit<=cutoff)=0;
accu = sum((y==yy))/length(y);
thrsh = (g.Link.Link(cutoff)-g.Coefficients.Estimate(1))/g.Coefficients.Estimate(2);