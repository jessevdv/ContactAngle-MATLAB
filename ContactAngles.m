myFolder = "Specify frames directory";
filePattern = fullfile(myFolder,'*.bmp');
images = dir(filePattern);
img_num = length(images);

X = ['Number of images:', num2str(img_num)];
disp(X)

prompt = 'Do you want to save the data? (Y/N)';
savedata = input(prompt, 's');

if savedata == 'Y'
    folder_name = fullfile('Specify save directory');
    mkdir(folder_name)

    outputFolder = folder_name; 
end

csvresults = {'ImageNumber','ContactAngle'};
dY = [];

%----------------------------------------------------------------------------------------%

if img_num > 0 
        for j = 1:img_num

            % Read Image
            baseFileName = images(j).name;
            fullFileName = fullfile(myFolder, baseFileName);
	        img_original = imread(fullFileName);
            
            % Crop Image
            start_row = 20;
            start_col = 384;

            crop_original = img_original(start_row:360, start_col:884, :);

            imshow(crop_original)
            
            %Binarize Image
            I = im2gray(crop_original);
            BW = imbinarize(I);
            BW = ~BW;
            imshow(BW)
            
            dim = size(BW);
            
            % Search X coordinate of start droplet - horizontal
            [B] = bwboundaries(BW,'noholes');
            for k = 1:length(B)
                boundary = B{k};
                for l = 30:length(boundary)
                    dY(l) = (boundary(l,1) - boundary((l-15),1));
                    startDropletX = find([dY(:)] < -2, 1, "first") -5;
                end
            end
            
            % Set ver and hor 
            vertical = any(BW, 2);
            horizontal = any(BW, 1);

            % Set max height wire
            ywire = 187;

            % Search X coordinate of start droplet - vertical
            max = find(vertical, 1, "first");
            heightdroplet = ywire-max;
            thirdDropletY = round(ywire-(heightdroplet/3));
            thirddroplet = find([B{1,1}(:)] == thirdDropletY, 1,"first")-12 ;
            
            % Calc number of pixels from 1/3 dropletheight to start
            if isempty(thirddropletx)
            numberOfPixels = 35;
            else
            numberOfPixels = round((sqrt((startDropletX-thirddropletx)^2+(ywire-thirdDropletY)^2))-7);
            end

            %Boundary conditions droplet
            ystart = thirdDropletY;
            xstart = startDropletX;

            %horizontal 
            col1 = xstart-40;
            row1 = find(BW(:,col1), 1);
            
            %droplet
            row2 = ystart;
            col2 = find(BW(row2,:), 1);
            

            boundary1 = bwtraceboundary(BW, [row1, col1], 'N', 8, 40);

            boundary2 = bwtraceboundary(BW, [row2, col2], 'E', 8, numberOfPixels, 'counter');

            figure = imshow(BW); hold on;

            plot(boundary1(:,2),boundary1(:,1),'g','LineWidth',2);
            plot(boundary2(:,2),boundary2(:,1),'b','LineWidth',2);         

            ab1 = polyfit(boundary1(:,2), boundary1(:,1), 1);
            ab2 = polyfit(boundary2(:,2), boundary2(:,1), 1);

            vect1 = [1 ab1(1)]; % create a vector based on the line equation
            vect2 = [1 ab2(1)];
            dp = dot(vect1, vect2);

            % Compute vector lengths
            length1 = sqrt(sum(vect1.^2));
            length2 = sqrt(sum(vect2.^2));

            % Obtain angle of intersection
            angle = 180-(180-acos(dp/(length1*length2))*180/pi);

            intersection = [1 ,-ab1(1); 1, -ab2(1)] \ [ab1(2); ab2(2)];

            inter_x = intersection(2);
            inter_y = intersection(1);

            % Plot X at intersection
            plot(inter_x,inter_y,'yx','LineWidth',2);

            text(inter_x-40, inter_y-40, [sprintf('%1.3f',angle),'{\circ}'],...
            'Color','y','FontSize',14,'FontWeight','bold');
            
            % Disp contact angles
            contactAngles = [num2str(j),'-', num2str(angle)];
            disp(contactAngles)
            
            %Save images and csv
            if savedata == 'Y'
            fullFileName = fullfile(outputFolder, ['Analyzed' images(j).name]);
            saveas(figure,fullFileName) ;   
            end

            csvresults = [csvresults;{j, angle}];
        
        end
        % Name CSV
        if savedata == 'Y'
        writecell(csvresults, fullfile(outputFolder, 'Data1.xls'));

        end
end

