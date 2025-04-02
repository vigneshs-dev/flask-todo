# Flask To-Do App
# Steps to View Table in MySQL Container
- Step:1
    - Change Database URI in app.py for Docker

    - docker exec -it mysql_container mysql -uflaskuser -p
    Password: flaskpassword
    - USE flask_todo_db;
    - SHOW TABLES;
- Step:2 ( Kubernetes Pod)
    - Change Database URI in app.py for Kubernetes

    - eval $(minikube docker-env)
    - docker build -t flask-todo-app:latest .

    - k apply -f mysql-configmap.yml 
    - k apply -f mysql-deployment.yml

    - kubectl exec -it $(kubectl get pod -l app=mysql -o jsonpath="{.items[0].metadata.name}") -- mysql -uflaskuser -p
    Password: flaskpassword
    - USE flask_todo_db;
    - SHOW TABLES;


    - k apply -f flask-deployment.yml
    - kubectl port-forward svc/flask-service 5000:5000



    - eval $(minikube docker-env --unset)

