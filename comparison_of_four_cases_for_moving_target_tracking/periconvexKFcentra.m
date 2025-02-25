N=6; %the number of sensor agents
T=0.1; % sampling period
max_step=1300;
omega_max=1; %maximum angular velocity for each sensor agent

%cross point of the boundary
% P=[3;7];
% Q=[8;17];
% R=[5;26];
% S=[1;22];
 Tar=[4;20];% jointed positions and the target

px=zeros(N,max_step);
py=zeros(N,max_step);

% true postion of target
tarxtrue=zeros(1,max_step);
tarytrue=zeros(1,max_step);

%estimation of the target
tarx_hat=zeros(1,max_step);
tarx_hat(1,1)=4;
tary_hat=zeros(1,max_step);
tary_hat(1,1)=20;

Sigma_hat=zeros(2,2*max_step);
Sigma_hat(1:2,1:2)=[1 0; 0 1];
% it is updated as the time passing by
id=zeros(N,1);

itheta=zeros(N,max_step); %location
theta=zeros(N+2,max_step);
phi=zeros(N,max_step);%relative angular distance
Pcost=zeros(N,max_step); %communicaiton power
Con=zeros(N,max_step); % convergence speed
Vimid=zeros(N,max_step); %the midepoint of i's Voronoi set


%itheta(:,1)=[20;60;80;130;200;250;278;290;311;330];
itheta(:,1)=[69.8979;75.0730;83.1024;108.1016;170.1016;303.8982];% initial locations of six sensor agents, counterclosewise order
%itheta(:,1)=round(sort(360*rand(N,1)));
theta(:,1)=[(itheta(N,1)-360);itheta(:,1);(itheta(1,1)+360)];
% % set the initial point on the line y=2x+1
% px(:,1)=sort(P(1,1) + (Q(1,1)-P(1,1)).*rand(N,1));
% py(:,1)=2*px(:,1)+1; %y=2x+1

for i=1:N
           id(i)=i;
         %itheta(i,1)=positiontoangularfun(py(i,1)-Tar(2,1),px(i,1)-Tar(1,1));
         %[px(i,1),py(i,1)]=angulartopositionfun(itheta(i,1),Tar(1,1),Tar(2,1));
           [px(i,1),py(i,1)]=angulartopositionfun(itheta(i,1),tarx_hat(1,1),tary_hat(1,1));
end

%function [x_hat_tplus1, y_hat_tplus1, Sigma_hat_tplus1, x_true, y_true] = KF (...x_hat_t, y_hat_t, Sigma_hat_t, Xr, Yr, t)
% [tarx_hat(1,2), tary_hat(1,2), Sigma_hat(1:2, (2*2-1):2*2), tarxtrue(1,1), tarytrue(1,1)]=KF (...
%     4, 20, Sigma_hat(1:2,1:2), px(:,1), py(:,1), 1);
% theta(:,1)=[(itheta(N,1)-360);itheta(:,1);(itheta(1,1)+360)]; %virtual agent 0th:=agent N-2pi;virtual agent 7th:=agent 1st+ 2pi

%Set up the movie.
writerObj = VideoWriter('periKFcentra.avi'); % Name it.
writerObj.FrameRate = 60; % How many frames per second.
open(writerObj); 

for k=1:max_step
    
    % take new measurement and update the target estimate at k+1
    [tarx_hat(1,k+1), tary_hat(1,k+1), Sigma_hat(1:2, (2*(k+1)-1):(2*(k+1))), tarxtrue(1,k), tarytrue(1,k)] = KF (...
        tarx_hat(1,k), tary_hat(1,k), Sigma_hat(1:2,(2*k-1): 2*k), px(:,k), py(:,k),id, k);
    
    for i=1:N
        Vimid(i,k)=1/4*(theta(i+2,k)+2*theta(i+1,k)+theta(i,k));
        sigu=sign(theta(i+2,k)-2*theta(i+1,k)+theta(i,k));
        
        % apply control law based on estimate at timestep k
        u=min(omega_max,abs(1/4*(theta(i+2,k)-2*theta(i+1,k)+theta(i,k))));
        %the orientation based on target at last step
        itheta(i,k+1)=itheta(i,k)+T*sigu*u;
        %[px(i,k+1),py(i,k+1)]=angulartopositionfun(itheta(i,k+1),Tar(1,1),Tar(2,1));
        [px(i,k+1),py(i,k+1)]=angulartopositionfun(itheta(i,k+1),tarx_hat(1,k),tary_hat(1,k));
        %the orientation based on the target at current step
        %itheta(i,k+1)=positiontoangularfun((py(i,k+1)-tary_hat(1,k+1)),(px(i,k+1)-tarx_hat(1,k+1)),itheta(i,k),(py(i,k)-tary_hat(1,k)),(px(i,k)-tarx_hat(1,k)));
        itheta(i,k+1)=positiontoangularfun((py(i,k+1)-tary_hat(1,k+1)),(px(i,k+1)-tarx_hat(1,k+1)));
       
    end
    itheta(:,k+1)=orderlythetafun(itheta(:,k+1));
    theta(:,k+1)=[(itheta(N,k+1)-360);itheta(:,k+1);(itheta(1,k+1)+360)];
    
    

    % %/////////
    % %Plot the robots
    % subplot(1,2,1)
    % %     figure(1);
    %     cla; hold on; axis equal
    %     th = 0 : 0.1 : 2*pi;
    %     cx = cos(th); cy = sin(th);
    %     plot(cx,cy,'--');
    %
    %     for i = 1 : size(itheta,1)
    % %          figure(1);
    %         plot(0,0,'*');hold on
    % %          figure(1);
    %         plot(cos(deg2rad(itheta(i,k))), sin(deg2rad(itheta(i,k))),'ro','MarkerFaceColor','r');
    %     end
    %     pause(0.01);
    %//////////
    %subplot(1,2,2)
    %figure(2);
    title('Periodic tracking employing a centralized EKF','fontsize',14)
    xlabel({'$$x$$'},'Interpreter','latex','fontsize',14)
    ylabel({'$$y$$'},'Interpreter','latex','fontsize',14)
    cla; hold on;axis equal
    %plot the boundary
    x1=3:0.1:8;
    y1=2*x1+1; %line 1
    plot(x1,y1)
    hold on
    
    x2=5:0.1:8;
    y2=-3*x2+41; %line 2
    %  figure(2);
    plot(x2,y2)
    hold on
    
    x3=1:0.1:5;
    y3=x3+21; %line 3
    %  figure(2);
    plot(x3,y3)
    hold on
    
    x4=1:0.1:3;
    y4=-7.5*x4+29.5; %line 4
    %  figure(2);
    plot(x4,y4)
    hold on
    
    % figure(2);
    for i = 1 : size(itheta,1)
        %        figure(2);
        %h(1) = covarianceEllipse([x_hat;y_hat],Sigma_hat,[1 0 0],11.82);
        %h(2) = plot(x_hat,y_hat,'rs','MarkerSize',8);
        %h(3) = plot(x_true,y_true,'bp','MarkerSize',8);
        %plot (Tar(1,1), Tar(2,1),'*'), hold on 
        h(1)=plot(px(i,k), py(i,k),'ro','MarkerFaceColor','r');
        h(2) = covarianceEllipse([tarx_hat(1,k);tary_hat(1,k)],Sigma_hat(1:2,(2*k-1):2*k),[1 0 0],11.82);
        h(3)=plot(tarx_hat(1,k),tary_hat(1,k),'rs','MarkerSize',8);
        h(4)=plot(tarxtrue(1,k),tarytrue(1,k),'bp','MarkerSize',8);
        h(5)=plot ([px(i,k) tarx_hat(1,k)], [py(i,k) tary_hat(1,k)],':');
    end
    pause(0.01);
    %%--------------------------------------------------
    %if mod(i,4)==0, % Uncomment to take 1 out of every 4 frames.
        frame = getframe(gcf); % 'gcf' can handle if you zoom in to take a movie.
        writeVideo(writerObj, frame);
    %end
        
   
end
hold  off
close(writerObj); % Saves the movie.


for k=1:max_step
    for i=1:N
        phi(i,k)=theta(i+1,k)-theta(i,k);
        Pcost(i,k)=log10(10^(0.1+abs(theta(i+1,k)-theta(i,k)))+10^(0.1+abs(theta(i+2,k)-theta(i+1,k))));
        %Con(i,k)=abs(phi(i,k)-360/N);
        Con(i,k)=abs(itheta(i,k)-Vimid(i,k));
    end
end

% for i=1:N
%    %plot(itheta(i,:))
%     plot(phi(i,:))
%     hold on
% end

%plot(sum(P)), hold on
%plot(sum(Con)),hold on




