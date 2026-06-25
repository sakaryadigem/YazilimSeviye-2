## Gerekli Kurulumlar ##
* Windows üzerine Windows için Git Desktop, WSL (Ubuntu for Windows),  Docker Desktop kurulumu yapılır
* Docker içerisinde örnek bir web uygulaması, database olarak mariadb ve mariadbye erişim sağlaması için web uygulaması olarak phpmyadmin kurulumu yapılır.

## Docker içerisinde örnek uygulamaları çalıştırma ##

Bir web uygulamasını dockerize edip çalıştırmak için docker_compose.yml dosyası ilgili path içerisinde olmalıdır. mat_geme dizinindeki örneğe bakınız.

Uygula, mariadb ve phpmyadmini çalıştırmak için örnek olarak aşağıdaki komutlar docker içerisindeki console ekranıda çalıştırılabilir.
* docker run -d --name mat_game -p 3000:3000 
* docker run -d --name mariadb --network app-network -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root54 mariadb
* docker run -d --name phpmyadmin --network app-network -p 8080:80 -e PMA_HOST=mariadb phpmyadmin/phpmyadmin

