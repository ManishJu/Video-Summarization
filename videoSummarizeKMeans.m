function sV = videoSummarizeKMeans(name,setofFrames,select_k)


    % name: name of the video for which summary is to be extracted.
    % setofFrames: frames needed in each interval
    % select_k:  number of clusters to be formed
    % example-> name = 'Cat_Video1.mov', setofFrames = 24, select_k = 6
    %gives
    % function sV = summarize2('Cat_Video1.mov',24,6)
    
    v = VideoReader(name);
    size_newV = [v.Height ,v.Width,3,floor(v.framerate*v.duration)];
    
    firstFrame_s  =[];
    
    %num_sets = number of sets that can be formed by the provided "setofFrames"
    % from the given total number of frames in the video.
    if ~mod(size_newV(4),setofFrames)
        num_sets = size_newV(4)/setofFrames;
    else
         num_sets = floor(size_newV(4)/setofFrames) + 1;
    end
    
    %sets in which frames numbers are stored
    clips = cell(num_sets,1);

    counter = 1;
    
    % storing frame numbers in those clips and also taking out the first
    % frame of each set and storing it in an array 'firstFrame_s'
    for i =1:setofFrames:size_newV(4)

        dif = size_newV(4) - i;

        if (dif) > setofFrames
                clips{counter} = linspace(i,i+setofFrames-1,setofFrames);
        else
                clips{counter} = linspace(i,i+dif-1,dif);
        end
        counter = counter+1;
        firstFrame_s  = [firstFrame_s i];
    end


    %calculating the histogram of each image in the array 'firstFrame_s'
    firstFrame_hists = [];
    for i= 1:num_sets
        h = imhist(rgb2gray(read(v,firstFrame_s(i))));
        firstFrame_hists = [firstFrame_hists; h'];
    end
    % taking 2 random positions for k to start from
    rand_frames = datasample(linspace(1,num_sets,num_sets),select_k,'replace',false)
    iter = 0;
    while 1
        iter = iter+1
        %diff_hists_ is a cell matrix where cluster of images with similar
        %histogram are stored 
        diff_hists_ = cell(select_k,1);

        for i = 1:num_sets
            % diff_hists is the array storing the difference in 2
            % histograms by computing their SSD
            diff_hists = [];
            for j = 1:select_k
                d = sum((firstFrame_hists(i,:) - firstFrame_hists(rand_frames(j),:)).^2);
                diff_hists = [diff_hists d];
            end

            [value, index] = min(diff_hists);
            di = diff_hists_{index};
            di = [di; i];
            diff_hists_{index} = di;

        end
        s_frames = [];
        for i = 1:select_k
            %find the mean histogram from the give set 
                h_num = diff_hists_{i};
                h_sum = zeros(1,size(firstFrame_hists,2));
                for j  = 1:length(h_num)
                    h_sum = h_sum + firstFrame_hists(h_num(j),:);
                end
                h_sum = h_sum/length(h_num);
            %find the closest hisotgram from the mean histogram
                di2_ = [];
                for j  = 1:length(h_num)
                    di2 = sum((firstFrame_hists(h_num(j),:) -h_sum).^2);
                    di2_= [di2_ di2];
                end
                [value2, index2] = min(di2_);
                % the new frames closest to the mean calculated
                s_frames = [s_frames h_num(index2)];
        end
        
        %repeat until convergence
        if rand_frames == s_frames 
                     break;
        else rand_frames = s_frames;
        end

    end

    % get original frame numbers 
    diff_hists_2 = diff_hists_;
    for i = 1:select_k
        cc = diff_hists_2{i};
        for j = 1: length(cc)
            cc(j) = firstFrame_s(cc(j));
        end
        diff_hists_2{i} = cc;
    end

    % get the set number the original frames belong to
    final_clusters = diff_hists_2;
    for i = 1:select_k
        cc = final_clusters{i};
        for j = 1: length(cc)
            cc(j) = floor(cc(j)/setofFrames) + 1;
        end
        final_clusters{i} = cc;
    end

    %from each of these clusters pick up a clip and get all the frames in that
    % clip
    final_frames = [];
    for i = 1:select_k
        cc = final_clusters{i};
        clip = datasample(cc,1,'replace',false);
        frames = clips{clip};
        final_frames = [final_frames frames];
    end
    
    %play the frames of that clip and then save the video
    for i = 1:size(final_frames,2)
        fr =read(v,final_frames(i));
        imshow(fr),title(num2str(i));
        fV(:,:,:,i) = fr;
    end
    cat_summarization = VideoWriter('cat_summarization.avi');
     open(cat_summarization);
    for i = 1:size(final_frames,2)
         writeVideo(cat_summarization,fV(:,:,:,i)); 
    end
    close(cat_summarization);
    sV = 'Done! check your folder for video cat_summarization.avi';
     
end