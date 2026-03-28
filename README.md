# Nginx

docker nginx proxy reverso

# La red por default debe configurarse en el docker mismo para que no haya superposiciones
#los nombres de los servicios pueden armarse con un prefijo de la aplicacion de 3 caracteres + "_web" o "_php" segun corresponda

#las BD, ya sea mysql o postgres o sqlserver debería estar fuera del docker de la aplicacion pero podrían estar:
1-En el mismo host server con contenerdores docker independientes para cada BD
2-En un host server exclusivo para BD con con contenedores docker independientes o centralizado

#Pero deberían estar fuera del stack de la aplicación
