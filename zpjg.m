%% z-project (max,mean,median)
function imgzp = zpjg(img, type)
    
%     img = HOtif2mat(varargin);
    [x,y,z] = size(img);
    
    if type == 'max'
        imgzp = max(img, [], 3);
    elseif type == 'median'
        imgzp = median(double(img), 3);
    elseif type == 'mean'
        imgzp = mean(img, 3);
    end
    
end
