function DotsMask = dotMask(colocMask, Dots)
    % colocMask: 2D binary matrix indicating Coloc signal locations default 8
    % bit
    % Dots: Dots from previous processing
    
    % convert Dots.pos into a sparse matrix and then convert to full matrix
    [dim(1), dim(2)] = size(colocMask);
    colocMask_one = colocMask./max(max(colocMask));
    sparse_dots = sparse(Dots.Pos(:,1),Dots.Pos(:,2),Dots.Pos(:,3),dim(1),dim(2));
    full_dots = full(sparse_dots);
    masked_dots = double(colocMask_one).*full_dots;
    [DotsMask(:,1),DotsMask(:,2),DotsMask(:,3)] = find(masked_dots);
end