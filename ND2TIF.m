function [] = ND2TIF(FileName, varargin)

    Montage = 'off';
    ChannelMontage = 'off';
    Tag = char(datetime('now', 'format', '-HH-mm-ss'));

    Resize = 'off';
    Compress = 'off';
    % Reload the parameters input by user
    if isempty(varargin)
    else

        for i = 1:(size(varargin, 2) / 2)
            AssignVar(varargin{i * 2 - 1}, varargin{i * 2})
        end

    end

    if strcmp(ChannelMontage, 'on')
        Montage = 'on';
    else
    end

    if strcmp(Resize, 'off')
    else
        Compress = 'on';
    end

    if strcmp(Resize, 'on')
        Resize = 1080;
    else
    end

    disp('--------------------------------------------------------------------------------')
    disp('Getting nd2 infomation...')

    [Path, Name, ~] = fileparts(FileName);

    if exist('ImageInfo', 'var')
        PrintInfo(ImageInfo)
    else
        [ImageInfo] = ND2Info(FileName);
    end

    [FilePointer, ImagePointer, ImageReadOut] = ND2Open(FileName);

    if exist('SavePath', 'var')
    else
        SavePath = [Path, filesep];
    end

    disp('--------------------------------------------------------------------------------')
    disp('Setting .tif stack(s) information...')

    ChannelNum = ImageInfo.Component;
    LayerNum = ImageInfo.CoordSize;
    
    LayerIndex = cell(0);

    if exist('Channel', 'var')
        ChannelIndex = Channel;
    else
        ChannelIndex = 1:ChannelNum;
    end

    if exist('Layer0', 'var')
        Layer0Index = Layer0;
    else
        Layer0Index = 1:ImageInfo.Experiment(1).count;
    end

    if exist('Layer1', 'var')
        Layer1Index = Layer1;
        LayerIndex{1} = Layer1Index;
    elseif LayerNum >= 2
        Layer1Index = 1:ImageInfo.Experiment(2).count;
        LayerIndex{1} = Layer1Index;
    end

    if exist('Layer2', 'var')
        Layer2Index = Layer2;
        LayerIndex{2} = Layer2Index;
    elseif LayerNum >= 3
        warning('off','backtrace')
        warning('Too many layers, compress high level layers into one stack.')
        warning('on','backtrace')
        
        ExperimentCount3 = 1;

        for ii = 3:LayerNum
            ExperimentCount3 = ExperimentCount3 * ImageInfo.Experiment(ii).count;
        end

        Layer2Index = 1:ExperimentCount3;
        LayerIndex{2} = Layer2Index;
    end

    disp('--------------------------------------------------------------------------------')
    disp('Saving as .tif stack(s)...')

    if strcmp(Montage, 'off')

        TifFileName = cell(0);

        if LayerNum == 1
            ImageIndex = 1:ImageInfo.numImages;

            for i = 1:ChannelNum
                TifFileName{i} = [SavePath, Name, Tag, '_', ImageInfo.metadata.channels(i).channel.name, '.tif'];
            end

            for i = 1:size(Layer0Index(:), 1)
                [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, uint32(ImageIndex(Layer0Index(i)) - 1), ImagePointer);
                Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);

                for j = 1:size(ChannelIndex(:), 1)

                    Original_Image = reshape(Image(ChannelIndex(j), :), [ImageReadOut.uiWidth, ImageReadOut.uiHeight])';

                    if strcmp(Compress, 'off')

                        imwrite(Original_Image, TifFileName{ChannelIndex(j)}, 'WriteMode', 'append', 'Compression', 'none')

                    else

                        if i == 1
                            Min_Intensity = double(min(Original_Image(:)));
                            Max_Intensity = double(max(Original_Image(:)));
                        else
                        end

                        Compressed_Image = ImageCompress(Original_Image, Min_Intensity, Max_Intensity, Resize);
                        imwrite(Compressed_Image, TifFileName{ChannelIndex(j)}, 'WriteMode', 'append', 'Compression', 'none')

                    end

                end

                DisplayBar(i, size(Layer0Index(:), 1));
            end

        elseif LayerNum == 2
            ImageIndex = reshape(1:ImageInfo.numImages, [ImageInfo.Experiment(2).count, ImageInfo.Experiment(1).count]);

            for i = 1:ChannelNum

                for j = 1:ImageInfo.Experiment(2).count
                    TifFileName{i}{j} = [SavePath, Name, Tag, '_', ImageInfo.metadata.channels(i).channel.name, '_' ImageInfo.Experiment(2).type, '_', num2str(j), '.tif'];
                end

            end

            for i = 1:size(Layer0Index(:), 1)

                for j = 1:size(Layer1Index(:), 1)

                    [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, uint32(ImageIndex(Layer1Index(j), Layer0Index(i)) - 1), ImagePointer);
                    Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);

                    for k = 1:size(ChannelIndex(:), 1)

                        Original_Image = reshape(Image(ChannelIndex(k), :), [ImageReadOut.uiWidth, ImageReadOut.uiHeight])';

                        if strcmp(Compress, 'off')

                            imwrite(Original_Image, TifFileName{ChannelIndex(k)}{Layer1Index(j)}, 'WriteMode', 'append', 'Compression', 'none')

                        else

                            if i == 1
                                Min_Intensity = double(min(Original_Image(:)));
                                Max_Intensity = double(max(Original_Image(:)));
                            else
                            end

                            Compressed_Image = ImageCompress(Original_Image, Min_Intensity, Max_Intensity, Resize);
                            imwrite(Compressed_Image, TifFileName{ChannelIndex(k)}{Layer1Index(j)}, 'WriteMode', 'append', 'Compression', 'none')

                        end

                    end

                end

                DisplayBar(i, size(Layer0Index(:), 1));
            end

        elseif LayerNum >= 3
            ImageIndex = reshape(1:ImageInfo.numImages, [ExperimentCount3, ImageInfo.Experiment(2).count, ImageInfo.Experiment(1).count]);

            for i = 1:ChannelNum

                for j = 1:ImageInfo.Experiment(2).count

                    for k = 1:ExperimentCount3
                        TifFileName{i}{j}{k} = [SavePath, Name, Tag, '_', ImageInfo.metadata.channels(i).channel.name, '_' ImageInfo.Experiment(2).type, '_', num2str(j), '_' ImageInfo.Experiment(3).type, '_', num2str(k) '.tif'];
                    end

                end

            end

            for i = 1:size(Layer0Index(:), 1)

                for j = 1:size(Layer1Index(:), 1)

                    for l = 1:size(Layer2Index(:), 1)
                        [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, uint32(ImageIndex(Layer2Index(l), Layer1Index(j), Layer0Index(i)) - 1), ImagePointer);
                        Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);

                        for k = 1:size(ChannelIndex(:), 1)

                            Original_Image = reshape(Image(ChannelIndex(k), :), [ImageReadOut.uiWidth, ImageReadOut.uiHeight])';

                            if strcmp(Compress, 'off')

                                imwrite(Original_Image, TifFileName{ChannelIndex(k)}{Layer1Index(j)}{Layer2Index(l)}, 'WriteMode', 'append', 'Compression', 'none')

                            else

                                if i == 1
                                    Min_Intensity = double(min(Original_Image(:)));
                                    Max_Intensity = double(max(Original_Image(:)));
                                else
                                end

                                Compressed_Image = ImageCompress(Original_Image, Min_Intensity, Max_Intensity, Resize);
                                imwrite(Compressed_Image, TifFileName{ChannelIndex(k)}{Layer1Index(j)}{Layer2Index(l)}, 'WriteMode', 'append', 'Compression', 'none')

                            end

                        end

                    end

                end

                DisplayBar(i, size(Layer0Index(:), 1));
            end

        end

    elseif strcmp(Montage, 'on')
        % do Motage
        ImageHeightNum = 1; ImageWidthNum = 1;

        if LayerNum >= 2

            for i = 1:LayerNum - 1
                ImageHeightNum = ImageHeightNum * size(LayerIndex{i}, 1);
                ImageWidthNum = ImageWidthNum * size(LayerIndex{i}, 2);
            end

        else
        end

        if strcmp(ChannelMontage, 'on')
            ChannelHeightNum = size(ChannelIndex, 1);
            ChannelWidthNum = size(ChannelIndex, 2);
        else
        end

        if strcmp(ChannelMontage, 'on')
            MontageTifFileName = [SavePath, Name, Tag, '_Montage', '.tif'];
        elseif strcmp(ChannelMontage, 'off')
            MontageTifFileName = cell(0);

            for i = 1:ChannelNum
                MontageTifFileName{i} = [SavePath, Name, Tag, '_Montage_', ImageInfo.metadata.channels(i).channel.name, '.tif'];
            end

        end

        if LayerNum == 1
            ImageIndex = reshape(1:ImageInfo.numImages, [1, ImageInfo.Experiment(1).count]);

            if strcmp(ChannelMontage, 'off')
                disp('Only one loop, try ChannelMotage On please!')
                return
            elseif strcmp(ChannelMontage, 'on')

                for i = 1:size(Layer0Index(:), 1)
                    [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, uint32(ImageIndex(Layer0Index(i)) - 1), ImagePointer);
                    Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);
                    Original_Image = cell(0);
                    Compressed_Image = cell(0);

                    for k = 1:size(ChannelIndex(:), 1)
                        Original_Image{k} = reshape(Image(ChannelIndex(k), :), [ImageReadOut.uiWidth, ImageReadOut.uiHeight])';

                        if i == 1
                            Min_Intensity(k) = double(min(Original_Image{k}(:)));
                            Max_Intensity(k) = double(max(Original_Image{k}(:)));
                        else
                        end

                        Compressed_Image{k} = ImageCompress(Original_Image{k}, Min_Intensity(k), Max_Intensity(k), Resize);
                    end

                    MotageImage = cell2mat(reshape(Compressed_Image, [ChannelHeightNum, ChannelWidthNum]));
                    imwrite(MotageImage, MontageTifFileName, 'WriteMode', 'append', 'Compression', 'none')

                    DisplayBar(i, size(Layer0Index(:), 1));
                end

            end

        elseif LayerNum == 2
            ImageIndex = reshape(1:ImageInfo.numImages, [ImageInfo.Experiment(2).count, ImageInfo.Experiment(1).count]);

            for i = 1:size(Layer0Index(:), 1)
                Original_Image = cell(0);

                for j = 1:size(Layer1Index(:), 1)
                    [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, uint32(ImageIndex(Layer1Index(j), Layer0Index(i)) - 1), ImagePointer);
                    Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);

                    for k = 1:size(ChannelIndex(:), 1)
                        Original_Image{k}{j} = reshape(Image(ChannelIndex(k), :), [ImageReadOut.uiWidth, ImageReadOut.uiHeight])';
                    end

                end

                MotageLayer1Image = cell(size(Original_Image));
                Compressed_Image = cell(size(Original_Image));

                for j = 1:size(Original_Image, 2)
                    MotageLayer1Image{j} = cell2mat(reshape(Original_Image{j}, [ImageHeightNum, ImageWidthNum]));

                    if i == 1
                        Min_Intensity(j) = double(min(MotageLayer1Image{j}(:)));
                        Max_Intensity(j) = double(max(MotageLayer1Image{j}(:)));
                    else
                    end

                    Compressed_Image{j} = ImageCompress(MotageLayer1Image{j}, Min_Intensity(j), Max_Intensity(j), Resize);

                end

                if strcmp(ChannelMontage, 'on')

                    MotageImage = cell2mat(reshape(Compressed_Image, [ChannelHeightNum, ChannelWidthNum]));
                    imwrite(MotageImage, MontageTifFileName, 'WriteMode', 'append', 'Compression', 'none')

                elseif strcmp(ChannelMontage, 'off')

                    for k = 1:size(ChannelIndex(:), 1)

                        if strcmp(Compress, 'off')
                            imwrite(MotageLayer1Image{k}, MontageTifFileName{ChannelIndex(k)}, 'WriteMode', 'append', 'Compression', 'none')
                        else
                            imwrite(Compressed_Image{k}, MontageTifFileName{ChannelIndex(k)}, 'WriteMode', 'append', 'Compression', 'none')
                        end

                    end

                end

                DisplayBar(i, size(Layer0Index(:), 1));
            end

        elseif LayerNum >= 3
            warning('off','backtrace')
            warning('Too many layers, do not support montage mode.')
            warning('on','backtrace')

            return
        end

    end
    disp('--------------------------------------------------------------------------------')
    ND2Close(FilePointer);
    clear('FilePointer')

end
