function I = tif2mat(imgpath)
    ImInfo = imfinfo(imgpath);
    ImSize = [ImInfo(1).Height ImInfo(1).Width length(ImInfo)]; %[y x z]
    if ImSize(3) == 1;
        I=imread([PathName FileName]);
        I = I(:,:,1); %kill the second and the third z planes if created.
    else
        for j = 1:ImSize(3)
            I(:,:,j)=imread(imgpath, j);
        end
    end