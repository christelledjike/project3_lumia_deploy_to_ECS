FROM tomcat:10-jdk17
LABEL "Project"="lumiatech"
LABEL "Author"="Jones"

WORKDIR /usr/local/tomcat/

RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/lumiatech-v1.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]