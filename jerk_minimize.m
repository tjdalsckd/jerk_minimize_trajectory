H = 2;
t_step = 0.1;
syms t_step
method = 5;


q_traj = sym('q',[H+1,J],'real');
v_traj = sym('v',[H+1,J],'real');
a_traj = sym('a',[H+1,J],'real');
j_traj = sym('j',[H+1,J],'real');


x_H = [reshape(q_traj',(H+1)*J,1);...
       reshape(v_traj',(H+1)*J,1);...
       reshape(a_traj',(H+1)*J,1);...
       reshape(j_traj',(H+1)*J,1)];
%% P

O = zeros((H+1)*J,(H+1)*J)   ;
P = [O,O,O,O;...
     O,O,O,O;
     O,O,O,O;
     O,O,O,eye((H+1)*J)];
%% A
% Dynamic Constraint - position
A_q = [];
O = zeros(J,J);
for i = 1:1:H
    A_q_ = [repmat(O,1,i-1),-eye(J),eye(J),repmat(O,1,(H+1)-i-1),...
            repmat(O,1,i-1),-t_step*eye(J),repmat(O,1,(H+1)-i),...
            repmat(O,1,i-1),-1/2*t_step^2*eye(J),repmat(O,1,(H+1)-i),...
            repmat(O,1,i-1),-1/6*t_step^3*eye(J),repmat(O,1,(H+1)-i)];
    A_q = [A_q ;A_q_];
end
% Dynamic Constraint - velocity

A_v = [];
O = zeros(J,J);
for i = 1:1:H
    A_v_ = [repmat(O,1,i),repmat(O,1,(H+1)-i),...
            repmat(O,1,i-1),-eye(J),eye(J),repmat(O,1,(H+1)-i-1),...
            repmat(O,1,i-1),-t_step*eye(J),repmat(O,1,(H+1)-i),...
            repmat(O,1,i-1),-1/2*t_step^2*eye(J),repmat(O,1,(H+1)-i)];
    A_v = [A_v ;A_v_];
end

% Dynamic Constraint - Acceleration

A_a = [];
O = zeros(J,J);
for i = 1:1:H
    A_a_ = [repmat(O,1,i),repmat(O,1,(H+1)-i),...
            repmat(O,1,i),repmat(O,1,(H+1)-i),...
            repmat(O,1,i-1),-eye(J),eye(J),repmat(O,1,(H+1)-i-1),...
            repmat(O,1,i-1),-t_step*eye(J),repmat(O,1,(H+1)-i)];
    A_a = [A_a ;A_a_];
end
A_dynamic = [A_q;A_v;A_a];

% Dynamic Constraint - min,max

O = zeros((H+1)*J,(H+1)*J)   ;
A_q_min_max = [eye(J*(H+1)),O,O,O];
A_v_min_max = [O,eye(J*(H+1)),O,O];
A_a_min_max = [O,O,eye(J*(H+1)),O];
A_j_min_max = [O,O,O,eye(J*(H+1))];
A_min_max = [A_q_min_max;A_v_min_max;A_a_min_max;A_j_min_max];

% Start & End Constraint
Jk = sym('Jk',[6,J],'real');
O = zeros(6,(H+1)*J)  
A_start_constraint = [Jk,zeros(6,H*J),O,O,O];
A_end_constraint = [zeros(6,H*J),Jk,O,O,O];

A_traj_constraint = [];
for j = 2:1:H
    qi = x_H(1+(j-1)*J:(j)*J);
    Ji = sym('Ji',[6,J],'real');
    A_traj_constraint_ = [zeros(6,(j-1)*J),Ji,zeros(6,(H+1-j)*J),O,O,O];
end



%% b


% Dynamic Constraint - position,velocity,acceleration
b_q = zeros((H)*J,1);
b_v = zeros((H)*J,1);
b_a = zeros((H)*J,1);
b_dynamic =[b_q;b_v;b_a];
% Dynamic Constraint - min,max
q_min =  sym('q_min',[J,1],'real'); %[-3.0543,-3.0543,-3.0543,-3.0543,-3.0543,-pi]'
q_max = sym('q_max',[J,1],'real');%[3.0543,3.0543,3.0543,3.0543,3.0543,pi]'
v_min = -sym('v_max',[J,1],'real');%[-2.6180,-2.6180,-2.6180,-2.6180,-2.6180,-2.6180]'
v_max = sym('v_max',[J,1],'real');%[2.6180,2.6180,2.6180,2.6180,2.6180,2.6180]'
a_min = -sym('a_max',[J,1],'real');%[40,40,40,40,40,40]'
a_max = sym('a_max',[J,1],'real');%[40,40,40,40,40,40]'
j_min = -sym('j_max',[J,1],'real');%[40,40,40,40,40,40]'
j_max = sym('j_max',[J,1],'real');%[40,40,40,40,40,40]'

b_q_min = repmat(q_min,H+1,1);
b_q_max = repmat(q_max,H+1,1);
b_v_min = repmat(v_min,H+1,1);
b_v_max = repmat(v_max,H+1,1);
b_a_min = repmat(a_min,H+1,1);
b_a_max = repmat(a_max,H+1,1);
b_j_min = repmat(j_min,H+1,1);
b_j_max = repmat(j_max,H+1,1);
b_min = [b_q_min;b_v_min;b_a_min;b_j_min];
b_max = [b_q_max;b_v_max;b_a_max;b_j_max];

% Start & End Constraint
Jk = sym('Jk',[6,J],'real');
Fk = sym('Fk',[6,1],'real');
O = zeros(6,(H+1)*J)  
b_start_constraint = (Fk+Jk);
b_end_constraint = (Fk+Jk);%x_H((H)*J+1:(H+1)*J);

A_start_constraint*x_H-b_start_constraint