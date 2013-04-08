%% [class,success] = classifyInstID(hyperplane, id)
%% if success is 1, then the id is correctly classified, if success is
%% 0 then the id is incorrectly classified

function [class, success] = classifyInstID(hyperplane, id)
  global population;
  global k;
  %% Test point, if value is greater than 0 then it is correctly
  %% classified and therefore of its defined class.  If it is less than
  %% 0 (or on the plane) it is misclassified and given the opposite
  %% class

  %% test value = sense of point (1 or -1) * (w0 + [w1, w2 ... wf-1]'
  %% point features)
  testValue = population.A(id,population.F)*(-1*hyperplane(rows(hyperplane))+\
					     dot(hyperplane(1:rows(hyperplane)-1),(-1*population.A(id,population.F))*population.A(id,1:population.F-1)));

  if (testValue>0)
    if (id <= population.numClass0)
      class = k.CLASS_0;
      success = 1;
    else
      class = k.CLASS_1;
      success = 1;
    endif
  else
    if (id <= population.numClass0)
      class = k.CLASS_1;
      success = 0;
    else
      class = k.CLASS_0;
      success = 0;
    endif
  endif
endfunction
