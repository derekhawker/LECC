function showHyperplane(node)
    population = createPopulation(node.dsId);
    persistent plot_no = 0
    hold off
    % Plotting the results
    plotrange = [Inf, -Inf, Inf, -Inf];
    % min x
    plotrange(1) = min(abs(population.A(:,1)))-std(abs(population.A(:,1)));
    % max x
    plotrange(2) = max(abs(population.A(:,1)))+std(abs(population.A(:,1)));
    % min y
    plotrange(3) = min(abs(population.A(:,2)))-std(abs(population.A(:,2)));
    % max y
    plotrange(4) = max(abs(population.A(:,2)))+std(abs(population.A(:,2)));


    rm_datapoints = [[],[]];
    class0_datapoints = [[],[]];
    class1_datapoints = [[],[]];

    for i= 1:population.M
        if(i <= population.numClass0)
            if(node.datapoints(i) == 0)
                rm_datapoints = [rm_datapoints(:,:);abs(population.A(i,1)),abs(population.A(i,2))];
            else
                class0_datapoints = [class0_datapoints(:,:);abs(population.A(i,1)),abs(population.A(i,2))];
            endif
        else
            if(node.datapoints(i) == 0)
                rm_datapoints = [rm_datapoints(:,:);abs(population.A(i,1)),abs(population.A(i,2))];
            else
                class1_datapoints = [class1_datapoints(:,:);abs(population.A(i,1)),abs(population.A(i,2))];
            endif	    
        endif
    endfor

    if (size(class0_datapoints)(1) == 0)
        class0_datapoints = [[-0],[-0]]
    endif
    if (size(class1_datapoints)(1) == 0)
        class1_datapoints = [[-0],[-0]]
    endif

    if (size(node.hyperplane) > 0)
        label = sprintf('(%.2f)w1 +(%.2f)w2 = %.2f', node.hyperplane(1), node.hyperplane(2), node.hyperplane(3) )
    else
        node.hyperplane = [0,0,0];
    end
    class1_datapoints
    class0_datapoints
    rm_datapoints
% ,
    if(size(class0_datapoints)(1) > 1)
        plot (class0_datapoints(:,1), class0_datapoints(:,2), 'x4;CLASS 0;')
        hold on
    end
    if(size(class1_datapoints)(1) > 1)
        plot (class1_datapoints(:,1), class1_datapoints(:,2), 'o2;CLASS 1;')
        hold on
    end
    if(size(rm_datapoints)(1) > 1)
        plot (rm_datapoints(:,1),rm_datapoints(:,2), '+0;REMOVED DATA POINTS;')
        hold on
    end
    % %    plot (population.A(c1start:totalpoints,2) , population.A(c1start:totalpoints,3), 'o4;CLASS 1;',population.A(1:(c1start-1),2), population.A(1:(c1start-1),3), 'x2;CLASS 0;',[0],[0],label)


    axis(plotrange) % fixes the x and y axis range

    ezplot (sprintf('%f*x + %f*y - %f = 0',node.hyperplane(1),node.hyperplane(2),node.hyperplane(3)),[plotrange(1),plotrange(2),plotrange(3),plotrange(4)])

    saveas (1,'dtree.png')


end
