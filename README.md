# shop-crm-deployment



# shop-crm

SpringBoot application example with 3 pages : user login, user registration and welcome page.
![img](assets/img.png)
![img1](assets/img_1.png)

### Repositories

1. [Shop CRM Server](https://github.com/DaviJam/shop-crm.git) #this is the app repository with its dockerfile.
2. [Shop CRM Server Deployment to AWS]() #this is the aws deployment project for the shop crm server

### 1. Create the application with spring frameworks

```
src
 | 
 + main
    |
    + java
        |
        + eu.ensup.shopcrm
            |
            + controller
                |
                + UserController    #Used to define endpoints and handle resources request
            + domain
                |
                + User              #Entity which is our data model class annotated with @Entity
            + repository
                |
                + UserRepository    #Entity repository used to handle data persistence of User entity. 
                					#Its should extends the JpaRepository interface 
            + service
                |
                + UserService       #Not mandatory but in this example, we use a service to interact with the Entity Repository 
            + ShopCrmApplication    #Entry point of this app. It should be annotated with @SpringBootApplication. 
            						#In this example, we also annotated it with @Controller to handle request to '/' path. 
            						#It redirects to '/user/login'
    + resources
        |
        + static
            |
            + css
               |
               + styles.css         #apply some CSS to make the front end user friendly
            + js
               |
               + app.js             #apply somme behaviour when entering 2 different password (register page) and animations.
        + templates
            |
            + error.html            #This page is shown, if a unknown path is requested
            + login-page.html       #This page is shown on '/' path request. It allows a user to login.
            + register-page.html    #This page is shown on '/user/register' path request. It allows a user to register an account.
            + welcome.html          #This page is shown when the user has logged in successfully.
        + application.yml           #choose which profile to use
        + application-dev.yml       #Developer configuration
        + application-prod.yml      #production configuration
```

Any request for a unknown path is redirected to the default white page. This behaviour is defined in the .yml configuration file.

> server.error.whitelabel.enable=true <br>
> server.error.path: /error (default)

### 2. Containerizing the application with Docker

##### Creating the DockerFile

``` dockerfile
#file : Dockerfile

# From maven and java image
FROM maven:3.8.4-openjdk-11

# Update
RUN apt-get update

# Create data directory in container and copy content into it
COPY . ./data

# Choose data directory as working directory
WORKDIR ./data

# Clean and create package using maven project management tool. Skip running test
RUN mvn clean package -DskipTests=true

# Expose port 80 on this container
EXPOSE 80

# Go to target directory
WORKDIR ./target

# Run the springboot app
CMD ["java", "-jar -Dspring.profiles.active=prod", "shop-crm-0.0.1-SNAPSHOT.jar"]
```

##### Creating the docker image and hosting it on the docker hub

1. Login to docker hub from host

   > docker login

2. Build Docker image with tag name shop-crm-server

   > docker build . -t shop-crm-server

3. Tag the image in order to push on docker hub 

   > docker tag shop-crm-server:latest dada971/shop-crm-server

4. Push image to docker hub

   > docker push dada971/shop-crm-server



### 3. Create docker compose file to add a MySQL database container

```dockerfile
version: '3.4'
services:
  server:
    image: dada971/shop-crm-server # use image from docker hub
    restart: always     # restart if failure at runtime
    depends_on:
      - db              # indicate that the server depends on our database defined as db
    network_mode: host  # indicate that the server should be exposed to the host network 

  db:
    image: mysql        # this service uses the mysql docker image
    command: --default-authentication-plugin=mysql_native_password # use the native password generator to define a password
    restart: always     # restart if failure at runtime
    cap_add:
      - SYS_NICE        # CAP_SYS_NICE handle error silently
    environment:        # environment variable for the MySQL server
      - MYSQL_USER=${MYSQL_USER} 
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_ALLOW_EMPTY_PASSWORD=no
    ports:              # indicate that the port should be exposed to the host. This allows the server to acces the database.
      - 3306:3306
```



### 4. Automating creation of the runtime environment for our application with Ansible

```
+ ansible.cfg			#Configuration of ansible
+ secret.ini 			#aws credentials to work with aws services
+ docker_usr_config.sh 	#Add user to docker group on ubuntu 20.04LTS
+ playbook.yml 			#Ansible playbook to create the runtime environment of our app
+ docker-compose.yml 	#Docker compose file run by Ansible
+ private_settings.yml  #Environment variables used by the playbook
+ hosts.ini 			#Created on runtime by terraform EC2 Module to define the EC2
						#instance public ip and used by ansible to create the runtime 
						#environment.
```



### 5. Deployment on AWS cloud with terraform 

```
+ app
	|
 	+ main.tf 			#Main file that uses the EC2 (AWS instance), SG (Security 
 						#groups for networking) and EIP (public ip address) modules
 	+ provider.tf 		#define our cloud provider
 	+ variables.tf 		#defines variables used in our our main file
 	+ terraform.tvars 	#override variables defined in the variables.tf 
	+ private_data.txt	#file with ip adresses to ssh into EC2 instances
 	
+ Modules
 	|
 	+ EC2
 		|
 		+ main.tf 		#handle creation of our EC2 instance and run our ansible  
 		+ output.tf 	#define output variables to be used by main.tf in the app folder 
 		+ variables.tf
 	+ EIP
  		|
 		+ main.tf 		#Handle creation of our static public ip address
 		+ output.tf
 		+ variables.tf
 	+ SG
	  	|
 		+ main.tf		#Handle creation of our security group to manage ingoing and 
 						#outgoing ports and allowed ip address
 		+ output.tf
 		+ variables.tf
+ david-kp.pem 			#key to access our EC2 instance via SSH
```

We need to init a terraform project before being able to deploy to aws cloud.

> cd app/
>
> terraform init

To deploy to aws, we use this command:

> terraform validate	  #Validate configuration syntax
>
> terraform plan			#Create execution plan
>
> terraform apply		  #Execute plan 

### 6. Quick look up to our terraform EC2 configuration

````
# Create an EC2 instance
resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ami-ubuntu-bionic.id
  instance_type          = var.instance_type
  security_groups        = ["${var.sg_name}"]
  availability_zone      = var.availability_zone
  key_name               = "${var.author_name}-kp"

  tags = {
    Name : "ec2-${var.author_name}"
  }
  # Get some information about this container (static ip address, aws instance and availability zone )
  provisioner "local-exec" {
    command = "echo IP : ${var.public_ip}, ID: ${aws_instance.ec2.id}, Zone: ${aws_instance.ec2.availability_zone} >> private_data.txt"
  }
  
  # get instance ip in order to pass it to ansible playbook
  provisioner "local-exec" {
    command = "echo '[webserver]\n${self.public_ip}' > ${var.main_directory}/hosts.ini"
  }
  
  # configure ssh
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }

    inline = [
      "sudo apt update -y"
    ]
  }
  
  #Run ansible playbook
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -u ubuntu -b -i ${var.main_directory}/hosts.ini --private-key ${var.private_key_path} ${var.main_directory}/playbook.yml"
  }
}

data "aws_ami" "ami-ubuntu-bionic" {
  most_recent = true
  owners      = ["099720109477"]
  tags = {
    Name = "${var.author_name}-ec2-ami-t2-ubuntu-bionic"
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server*"]
  }
}
````

