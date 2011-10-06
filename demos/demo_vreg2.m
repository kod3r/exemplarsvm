function demo_vreg2(X)

if ~exist('X','var')

  N = 4;
  D = 2;

  noise = .03;
  
  x0 = zeros(D,1);
  v = randn(D,1);
  v = v / (v'*v);
  t = rand(N,1);

  X = zeros(D,N);
  for i = 1:N
    X(:,i) = x0 + t(i)*v + randn(D,1)*noise;
  end
  
  N2 = 100;
  X2 = randn(D,N2)*noise*10+randn;
  X = [X X2];
  
  Y = [ones(N,1); -1*ones(N2,1)];
  N = N+N2;
  
  %oks = find(rand(N,1)>.8);
  %X(:,oks) = .1*randn(size(X(:,oks)))+.2;
else
  D = size(X,1);
  N = size(X,2);
end

starter = tic;
[w2,b2] = svm(X,Y);
fprintf(1,'svm time %.5f sec\n',toc(starter));


xstart = randn(D*2+2,1);
xstart(1:D) = mean(X(:,Y==1),2);
  
for zzz = linspace(0,.99,100)
  
if D == 2
  figure(1)
  clf
  subplot(1,2,1)
  plot(X(1,Y==1),X(2,Y==1),'rs','MarkerSize',10);
  hold on;
  plot(X(1,Y==-1),X(2,Y==-1),'bp','MarkerSize',10);
end
%[x0,v] = get_pca_solution(X);


params = [zzz .00001 (1-zzz)];%.00001 1];
obj = fminunc(@(x)lossfun(x,X,Y,D,params),xstart);
obj = fminunc(@(x)lossfun(x,X,Y,D,params),obj);
x0 = obj(1:D);
w = obj(D+1:D*2);
b = obj(end);
v = w / norm(w);

if D ~=2
  keyboard
end

X2 = zeros(size(X));
for i = 1:N
  t = -(x0-X(:,i))'*v;
  X2(:,i) = x0 + t*v;
end
hold on;

[aa,bb] = min(X2(1,:));
[aa2,bb2] = max(X2(1,:));

if 1
  plot(X2(1,[bb bb2]),X2(2,[bb bb2]),'m','LineWidth',4)
  hold on;
  %for i = 1:N
  %  plot([X(1,i) X2(1,i)],[X(2,i) X2(2,i)],'g-')
  %end

end
hold on;


%w = alpha*v;
plot_them(X,Y,w,b)

axis([-2 2 -2 2])
axis square
grid on;
h=title(sprintf('Visual Similarity Regressor %.3f',zzz));

subplot(1,2,2)
plot_them(X,Y,w2,b2)
h2=title('SVM Solution');
axis([-2 2 -2 2])
axis square
grid on;

set(h,'FontSize',20)
set(h2,'FontSize',20)
drawnow
pause;
end


function plot_them(superx,supery,w,b)
plot(superx(1,supery==1),superx(2,supery==1),'rs','MarkerSize',10);
hold on;
plot(superx(1,supery==-1),superx(2,supery==-1),'bp','MarkerSize',10);

mins = min(superx,[],2);
maxes = max(superx,[],2);

%mins(1) = -10;
%maxes(1) = 10;

LW = 3;
t = 0;
ymin = ((t + b)- w(1)*mins(1))/w(2);
ymax = ((t + b)- w(1)*maxes(1))/w(2);
plot([mins(1) maxes(1)],[ymin ymax],'k--','LineWidth',LW);

t = 1;
ymin = ((t + b)- w(1)*mins(1))/w(2);
ymax = ((t + b)- w(1)*maxes(1))/w(2);
plot([mins(1) maxes(1)],[ymin ymax],'r--','LineWidth',LW);

t = -1;
ymin = ((t + b)- w(1)*mins(1))/w(2);
ymax = ((t + b)- w(1)*maxes(1))/w(2);
plot([mins(1) maxes(1)],[ymin ymax],'b--','LineWidth',LW);

axis([mins(1) maxes(1) mins(2) maxes(2)])

function [w,b,r] = svm(X,Y)

lambda = .001;
c = 1/lambda;
supery = Y;
superx = X;
svm_model = libsvmtrain(supery,superx',sprintf('-s 0 -t 0 -c %f -q',c));
svm_weights = full(sum(svm_model.SVs .* ...
                       repmat(svm_model.sv_coef,1,size(svm_model.SVs,2)),1));
wex = svm_weights';
w = wex;
b = svm_model.rho;
r = w'*X-b;
function [w,b,r] = reg(X,Y,K)

lambda = .000001;
a = Y;
%A = diag(a);
saveX = X;
X(end+1,:) = 1;
curI = lambda*eye(size(X,1));
for i = 1:K
  A2 = diag(a.^2);
  %w2 = inv(X*A'*A*X' + lambda*eye(size(X,1)))*(Y'*A'*A*X')';
  
  if exist('r','var')
    oks = logical(a>0);
    w = 1*(Y(oks)'*diag(a(oks).^2)*X(:,oks)')/(X(:,oks)*diag(a(oks).^2)*X(:,oks)' + curI);
  else
    w = (Y'*A2*X')/(X*A2*X' + curI);
  end
  w = w';

  b = -w(end);
  w = w(1:end-1);
  r = w'*saveX-b;
  
  a = Y;
  a(Y==1 & r'>=1) = 0;
  a(Y==-1 & r'<=-1) = 0;


  %a(Y==1) = max(1.0,a(Y==1));
  %a(Y==-1) = min(-1.0,a(Y==-1));
  %A = diag(a);
end


%[x02,v2] = get_pca_solution(X)
%keyboard
function [x0,v] = get_pca_solution(X);

[V,D] = eig(cov(X'));
[aa,bb] = max(diag(D));
v = V(:,bb);
x0 = mean(X,2);

function obj = lossfun(x,X,Y,D,params)

N = size(X,2);
x0 = x(1:D);
w = x(D+1:2*D);
b = x(end);

%v = v / norm(v);
if 0
  obj = 0;
  %obj1 = 0;
  %obj2 = 0;
  curI = eye(D)-w*w' / norm(w).^2;
  for i = find(Y==1)' %1:size(X,2)
    d = x0 - X(:,i);
    obj = obj + d'*curI*d;
    %obj1 = obj1 + norm(x0-X(:,i)).^2;
    %obj2 = obj2 + norm(v'*(X(:,i)-x0)).^2;
  end
end

Xpos = X(:,Y==1);
Npos = size(Xpos,2);
df = Xpos - x0*ones(1,Npos);
obj = norm(df,'fro').^2 - norm(w'/norm(w)*df,'fro').^2;

obj2 =.5*norm(w).^2;

r = w'*X-b;
obj3 = sum(hinge(Y'.*r));
%obj3 = sum(logloss(Y'.*r));

obj = params(1)*obj + params(2)*obj2 + params(3)*obj3;

function r = hinge(x)
r = max(1-x,0);

function r= logloss(x)
r = log(1+exp(-x));