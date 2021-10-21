function PlotMesh_Segment(Node_Coordinates,Element_Connectivity)

%% Description
% The size of variable "Node_Coordinates" is [Number of nodes, 3]
% The size of variable "Element_Connectivity" is [Number of elements, Number of nodes in each element]

%% Initialization
% Initialization of the required matrices for Element C3D8
X_1 = zeros(9,4);
Y_1 = zeros(9,4);
Z_1 = zeros(9,4);

%% 8-node brick element (C3D8)
nel_1 = 12; % number of elements
fm = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 1 2 3 4; 5 6 7 8; 5 6 9 9; 6 7 9 9; 7 8 9 9; 8 5 9 9];
XYZ = cell(1,nel_1);
for e=1:nel_1
    nd=Element_Connectivity(e,:);
    X_1(:,e) = Node_Coordinates(nd,1);
    Y_1(:,e) = Node_Coordinates(nd,2);
    Z_1(:,e) = Node_Coordinates(nd,3);
    XYZ{e} = [X_1(:,e) Y_1(:,e) Z_1(:,e)];
end
% Plot FEM mesh
figure
set(gcf,'color','w')
axis off
cellfun(@patch,repmat({'Vertices'},1,nel_1),XYZ,...
    repmat({'Faces'},1,nel_1),repmat({fm},1,nel_1),...
    repmat({'FaceColor'},1,nel_1),{'#00FFFF','#FF0000','#FF0000','#00FFFF','#008000','#008000','#00FFFF','#0000FF','#0000FF','#00FFFF','#FFFF00','#FFFF00'});
view(3)
set(gca,'XTick',[]); set(gca,'YTick',[]); set(gca,'ZTick',[]);
rotate3d on
hold on

% % Plot extra node from 9-node brick element
% v = [Node_Coordinates(Extra_Nodes(1,1:12),1),Node_Coordinates(Extra_Nodes(1,1:12),2),Node_Coordinates(Extra_Nodes(1,1:12),3)];
% for i = 1:12
%     plot3(v(i,1),v(i,2),v(i,3),'o');
% end

dim = [.05 .65 .2 .3];
str1 = 'Cyan--Segment 1';
str2 = 'Green--Segment 2';
str3 = 'Red--Segment 3';
str4 = 'Yellow--Segment 4';
str5 = 'Blue--Segment 5';
annotation('textbox',dim,'String',{str1,str2,str3,str4,str5},'FitBoxToText','on');

end

    