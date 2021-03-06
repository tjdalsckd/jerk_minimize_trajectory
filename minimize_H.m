addpath('mr')
addpath('function')
addpath('mesh')

clear
close all;
%% Parameter Setup
H=300
t_step = 0.01;
radius = 0.1
stepp=1;
method =5;

for t_step = 0.01
J = 6

ITER = 500;
q_min = [-3.0543,-3.0543,-3.0543,-3.0543,-3.0543,-pi]';
q_max = [3.0543,3.0543,3.0543,3.0543,3.0543,pi]';
v_min = [-2.6180,-2.6180,-2.6180,-2.6180,-2.6180,-2.6180]';
v_max = [2.6180,2.6180,2.6180,2.6180,2.6180,2.6180]';
a_max= [40,40,40,40,40,40]'*1000;
a_min= -[40,40,40,40,40,40]'*1000;
j_min= -[40,40,40,40,40,40]'*1000;
j_max= [40,40,40,40,40,40]'*1000;
l_eps = [0.00;0.00;0.00;-0.0001;-0.0001;-0.0001];
u_eps = [0.00;0.00;0.00;0.0001;0.0001;0.0001];
eomg = 0.01;
ev = 0.001;
%% ROBOT PARAMETER
H1 = 0.3;
H2 = 0.45;
H3 = 0.350;
H4 = 0.228;
W1 = 0.0035;
W2 = 0.183;
S1 = [0; 0;  1;  0; 0;  0];
S2 =        [0; -1;  0; H1;0 ;  0];
S3 =        [0; -1;  0; H1+H2; 0; 0];
S4 =        [0; 0;   1; -W1; 0; 0];
S5 =        [0; -1;  0; H1+H2+H3; 0; 0];
S6 =        [0; 0;  1; -W1-W2;0; 0];
Slist = [S1,S2,S3,S4,S5,S6];
M= [1 0 0 0;...
    0 1 0 -W1-W2 ;...
    0 0 1 H1+H2+H3+H4;...
    0 0 0 1 ];

M06 = [1 0 0 0;...
    0 0 -1 -W1-W2 ;...
    0 1 0 H1+H2+H3;...
    0 0 0 1 ];

M05= [1 0 0 0;...
    0 1 0 -W1 ;...
    0 0 1 H1+H2+H3;...
    0 0 0 1 ];
q0 = [    0.8071  -0.7162   -1.9524    0.0000   -0.4730    0.8071]';
Gpick = [-1   0    0    0.45;
          0   1    0   -radius*2;
          0   0    -1    0.2;
         0         0         0    1.0000];   
Gplace = [-1   0    0    0.45;
          0   1    0   radius*2;
          0   0    -1    0.2;
         0         0         0    1.0000]; 
 Gmid = [-1   0    0    0.45;
      0   1    0   0.0;
      0   0    -1    0.2;
     0         0         0    1.0000]; 
[q0, success0] = IKinSpace(Slist, M, Gpick, q0, eomg, ev);
[qT, successT] = IKinSpace(Slist, M, Gplace, q0, eomg, ev);

q_traj = JointTrajectory(q0,qT,H*t_step,H+1,5);
v_traj = JointVelTrajectory(q0,qT,H*t_step,H+1,5);
a_traj = JointAccTrajectory(q0,qT,H*t_step,H+1,5);
j_traj = JointJerkTrajectory(q0,qT,H*t_step,H+1,5);

G_traj = ScrewTrajectory(Gpick, Gplace, H*t_step, H+1, 5);
for jj = floor(H/2):1:length(G_traj)-1
    G = G_traj{jj};
    G(1,4) = G(1,4) +radius*cos(jj/floor(H/2)*pi+pi/2);
    G_traj{jj} = G;
end

q_traj=[]
for jj = 1:1:length(G_traj)
    G = G_traj{jj};
    [q0, success0] = IKinSpace(Slist, M, G, q0, eomg, ev);
    q_traj = [q_traj;q0'];
end


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
 
 R0 = eye(6);
 
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
q0 = x_H(1:J);
qend = x_H(1+(H)*J:J+(H)*J);
J0 = JacobianSpace(Slist,q0);
Jend = JacobianSpace(Slist,qend);
O = zeros(6,(H+1)*J)  ;
A_start_constraint = [J0,zeros(6,H*J),O,O,O];
A_end_constraint = [zeros(6,H*J),Jend,O,O,O];

A_traj_constraint = [];
for j = 1:stepp:length(G_traj)
    qi = x_H(1+(j-1)*J:(j)*J);
    Ji = JacobianSpace(Slist,qi);
    A_traj_constraint_ = R0*[zeros(6,(j-1)*J),Ji,zeros(6,(H+1-j)*J),O,O,O];
    A_traj_constraint=[A_traj_constraint;A_traj_constraint_];
end



%% b


% Dynamic Constraint - position,velocity,acceleration
b_q = zeros((H)*J,1);
b_v = zeros((H)*J,1);
b_a = zeros((H)*J,1);
b_dynamic =[b_q;b_v;b_a];
% Dynamic Constraint - min,max
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
F0 = -se3ToVec(MatrixLog6(TransInv(FKinSpace(M,Slist,q0))*Gpick));
Fend = -se3ToVec(MatrixLog6(TransInv(FKinSpace(M,Slist,qend))*Gplace));
b_start_constraint = (F0+J0*q0);
b_end_constraint = (Fend+Jend*qend);%x_H((H)*J+1:(H+1)*J);

lb_traj_constraint = [];
ub_traj_constraint = [];
for j = 1:stepp:length(G_traj)
    G = G_traj{j};
    qi = x_H(1+(j-1)*J:(j)*J);
    Ji = JacobianSpace(Slist,qi);
    Fi = -se3ToVec(MatrixLog6(TransInv(FKinSpace(M,Slist,qi))*G));
    b_traj_constraint_ = R0*(Fi+Ji*qi);
    lb_traj_constraint=[lb_traj_constraint;b_traj_constraint_];
    ub_traj_constraint=[ub_traj_constraint;b_traj_constraint_];
    
end


%% qp Solve
A = [A_dynamic;A_min_max;;;A_traj_constraint];
lb= [b_dynamic;b_min;;;lb_traj_constraint];
ub= [b_dynamic;b_max;;;ub_traj_constraint];

prob = osqp;
q = zeros((H+1)*4*J,1);
prob.setup(P, q, A, lb, ub, 'alpha', 1);
for k = 1:1:1000
    res = prob.solve();
    
    if(strcmp(res.info.status,'primal infeasible'))
        break;
    else
        x_H  = res.x;
    end
    x_H  = res.x

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
    q0 = x_H(1:J);
    qend = x_H(1+(H)*J:J+(H)*J);
    J0 = JacobianSpace(Slist,q0);
    Jend = JacobianSpace(Slist,qend);
    O = zeros(6,(H+1)*J)  ;
    A_start_constraint = [J0,zeros(6,H*J),O,O,O];
    A_end_constraint = [zeros(6,H*J),Jend,O,O,O];

    A_traj_constraint = [];
    for j = 1:stepp:length(G_traj)
        qi = x_H(1+(j-1)*J:(j)*J);
        Ji = JacobianSpace(Slist,qi);
        A_traj_constraint_ = R0*[zeros(6,(j-1)*J),Ji,zeros(6,(H+1-j)*J),O,O,O];
        A_traj_constraint=[A_traj_constraint;A_traj_constraint_];
    end



    %% b


    % Dynamic Constraint - position,velocity,acceleration
    b_q = zeros((H)*J,1);
    b_v = zeros((H)*J,1);
    b_a = zeros((H)*J,1);
    b_dynamic =[b_q;b_v;b_a];
    % Dynamic Constraint - min,max
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
    F0 = -se3ToVec(MatrixLog6(TransInv(FKinSpace(M,Slist,q0))*Gpick));
    Fend = -se3ToVec(MatrixLog6(TransInv(FKinSpace(M,Slist,qend))*Gplace));
    b_start_constraint = (F0+J0*q0);
    b_end_constraint = (Fend+Jend*qend);%x_H((H)*J+1:(H+1)*J);

    lb_traj_constraint = [];
    ub_traj_constraint = [];
    for j = 1:stepp:length(G_traj)
        G = G_traj{j};
        qi = x_H(1+(j-1)*J:(j)*J);
        Ji = JacobianSpace(Slist,qi);
        Fi = -se3ToVec(MatrixLog6(TransInv(FKinSpace(M,Slist,qi))*G));
        
        b_traj_constraint_ = R0*(Fi+Ji*qi);
        lb_traj_constraint=[lb_traj_constraint;b_traj_constraint_];
        ub_traj_constraint=[ub_traj_constraint;b_traj_constraint_];

    end



    A = [A_dynamic;A_min_max;;;A_traj_constraint];
    lb= [b_dynamic;b_min;;;lb_traj_constraint];
    ub= [b_dynamic;b_max;;;ub_traj_constraint];


    prob.update('Ax',A,'l', lb, 'u', ub);

end
x_H_result=x_H;
H
% PLOT
[q1_list,q2_list]=drawPlot(x_H,x_H_result,H,J);
FKlist = []
FKlist2 = []
  for i = 1:1:length(q2_list)

      thetalist = q2_list(i,:)';
      T = FKinSpace(M,Slist,thetalist);
      R1 = rotm2quat(T(1:3,1:3));
      G = G_traj{i};
      R2 = rotm2quat(G(1:3,1:3));
      FKlist = [FKlist;[R1(1),R1(2),R1(3),R1(4),T(1,4),T(2,4),T(3,4)]];
      FKlist2 = [FKlist2;[R2(1),R2(2),R2(3),R2(4),G(1,4),G(2,4),G(3,4)]];
      
      drawrobot_screw(thetalist,1,110,40,1000,0.05,0.0,false,t_step,{});
  end
figure(77)
subplot(7,1,1)
plot(FKlist(:,1));hold on;
plot(FKlist2(:,1))

subplot(7,1,2)
plot(FKlist(:,2));hold on;
plot(FKlist2(:,2));

subplot(7,1,3)
plot(FKlist(:,3));hold on;
plot(FKlist2(:,3))

subplot(7,1,4)
plot(FKlist(:,4));hold on;
plot(FKlist2(:,4))


subplot(7,1,5)
title("x")
plot(FKlist(:,5));hold on;
plot(FKlist2(:,5))

subplot(7,1,6)
title("y")
plot(FKlist(:,6));hold on;
plot(FKlist2(:,6))

subplot(7,1,7)
title("z")
plot(FKlist(:,7));hold on;
plot(FKlist2(:,7))
end
