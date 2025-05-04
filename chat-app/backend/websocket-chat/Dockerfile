FROM maven:3.8-openjdk-11 AS builder

WORKDIR /app
COPY . /app/
RUN mvn clean package

FROM tomcat:9-jre11

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR file
COPY --from=builder /app/target/websocket-chat.war /usr/local/tomcat/webapps/ROOT.war

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Install Nginx
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Start both Tomcat and Nginx
CMD service nginx start && catalina.sh run
