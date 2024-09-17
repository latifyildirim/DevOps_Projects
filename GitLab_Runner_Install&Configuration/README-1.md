# Umfassender GitLab Runner Installationsleitfaden

## Inhaltsverzeichnis
1. [Einführung](#einführung)
2. [Voraussetzungen](#voraussetzungen)
3. [Installation von Docker und Docker Compose](#installation-von-docker-und-docker-compose)
4. [GitLab Runner Installation](#gitlab-runner-installation)
5. [Runner-Konfiguration](#runner-konfiguration)
6. [Erstellung der Dockerfile](#erstellung-der-dockerfile)
7. [Hinzufügen des Runners in GitLab und Token-Erhalt](#hinzufügen-des-runners-in-gitlab-und-token-erhalt)
8. [CI/CD Pipeline-Konfiguration und Variablen](#cicd-pipeline-konfiguration-und-variablen)
9. [Testen der Pipeline](#testen-der-pipeline)
10. [Fehlerbehebung](#fehlerbehebung)
11. [Allgemeine Wartung und Best Practices](#allgemeine-wartung-und-best-practices)
12. [Fortgeschrittene Anpassungen](#fortgeschrittene-anpassungen)
13. [Fazit](#fazit)

## Einführung

Dieser Leitfaden erklärt Schritt für Schritt, wie man GitLab Runner mit Docker Compose auf einer Ubuntu-Maschine installiert. Er wurde für Benutzer ohne Vorkenntnisse erstellt und hilft Ihnen, eine CI/CD-Umgebung einzurichten, die automatische Builds, Tests und Deployments für Ihre GitLab-Projekte ermöglicht.

## Voraussetzungen

- Ubuntu 20.04 LTS oder eine neuere Version
- Ein Benutzer mit Sudo-Rechten
- Internetverbindung
- GitLab-Konto und ein GitLab-Projekt

## Installation von Docker und Docker Compose

### Docker Installation

1. Aktualisieren Sie die Systempakete:
   ```
   sudo apt update
   sudo apt upgrade -y
   ```

2. Fügen Sie den offiziellen GPG-Schlüssel von Docker hinzu:
   ```
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

3. Fügen Sie das offizielle Docker-Repository hinzu:
   ```
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

4. Aktualisieren Sie die Paketliste und installieren Sie Docker:
   ```
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io -y
   ```

5. Starten Sie den Docker-Dienst und aktivieren Sie den automatischen Start:
   ```
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

6. Fügen Sie Ihren Benutzer zur Docker-Gruppe hinzu:
   ```
   sudo usermod -aG docker $USER
   ```

7. Melden Sie sich ab und wieder an oder starten Sie das System neu, damit die Änderungen wirksam werden.

### Docker Compose Installation

1. Laden Sie die neueste Version von Docker Compose herunter:
   ```
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   ```

2. Machen Sie die heruntergeladene Datei ausführbar:
   ```
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. Überprüfen Sie die Installation:
   ```
   docker-compose --version
   ```

## GitLab Runner Installation

1. Erstellen Sie ein neues Verzeichnis für GitLab Runner:
   ```
   mkdir gitlab-runner-1 && cd gitlab-runner-1
   ```

2. Erstellen Sie in diesem Verzeichnis eine Datei namens `docker-compose.yml`:
   ```
   nano docker-compose.yml
   ```

3. Fügen Sie den folgenden Inhalt in den Editor ein:
   ```yaml
   version: '3'
   services:
     gitlab-runner:
       image: gitlab/gitlab-runner:latest
       container_name: gitlab-runner-1
       restart: always
       volumes:
         - ./config:/etc/gitlab-runner
         - /var/run/docker.sock:/var/run/docker.sock 
       security_opt:
         - no-new-privileges
       environment:
         HTTP_PROXY: http://proxy.devops.it:8080
         HTTPS_PROXY: http://proxy.devops.it:8080
         NO_PROXY: localhost,127.0.0.1,docker
   ```
   Hinweis: Passen Sie die Proxy-Einstellungen an Ihre Umgebung an oder entfernen Sie den environment-Abschnitt, falls nicht erforderlich.

4. Speichern Sie die Datei mit Strg+X, dann Y und Enter.

6. Starten Sie den GitLab Runner:
   ```
   docker-compose up -d
   ```
   ![image](https://github.com/user-attachments/assets/4d87e3a9-316e-4c6d-bfa9-937507c6b27e)

6. Überprüfen Sie, ob der Runner erfolgreich läuft:
   ```
   docker ps
   ```

## Hinzufügen des Runners in GitLab und Token-Erhalt

1. Gehen Sie zu Ihrem GitLab-Projekt und klicken Sie auf "Settings" > "CI/CD" im linken Menü.
2. Scrollen Sie nach unten zum Abschnitt "Runners".
3. Klicken Sie auf "New project runner".
4. Geben Sie eine Beschreibung für den Runner ein (z.B. "DevOps-3 Runner").
5. Fügen Sie im Tags-Feld "devops-3" ein (dies sollte mit dem Tag in Ihrer .gitlab-ci.yml-Datei übereinstimmen).
6. Klicken Sie auf "Create runner".
7. Kopieren Sie das angezeigte Registrierungs-Token. Sie werden dieses Token verwenden, um den Runner zu registrieren.

Screenshot des GitLab-Bildschirms zum Hinzufügen eines neuen Runners
![image](https://github.com/user-attachments/assets/9f2dcc23-2f8a-47c8-8b03-e98f9b2ed755)

## Erstellung der Dockerfile

1. Kehren Sie zur Hauptseite Ihres GitLab-Projekts zurück.
2. Klicken Sie erneut auf das "+"-Symbol und wählen Sie "New file".
3. Geben Sie im Feld "File name" `Dockerfile` ein (achten Sie auf das große 'D' am Anfang).
4. Fügen Sie den folgenden Code in den Inhaltsbereich ein:

```dockerfile
FROM registry.devops.it/devops/containers/tomcat:latest
RUN rm -rf /usr/local/tomcat/webapps/* 
COPY target/*.war /usr/local/tomcat/webapps/dx4api.war
EXPOSE 8080 
CMD ["catalina.sh", "run"]
```

5. Klicken Sie auf "Commit changes" am unteren Rand der Seite.

## Runner-Konfiguration

1. Führen Sie den folgenden Befehl aus, um den Runner zu registrieren:
   ```
   docker exec -it gitlab-runner-1 gitlab-runner register
   ```

2. Geben Sie die folgenden Informationen während des Registrierungsprozesses ein:
   - GitLab instance URL: https://gitlab.devops.it (oder Ihre GitLab-URL)
   - Registration token: (Sie erhalten dies von Ihrem GitLab-Projekt)
   - Description: DevOps Runner (oder eine Beschreibung Ihrer Wahl)
   - Executor: docker
   - Docker image: registry.devops.it/devops/containers/docker:latest (oder ein passendes Image für Ihr Projekt)

Screenshot des Runner-Registrierungsprozesses im Terminal
![image](https://github.com/user-attachments/assets/79ff0b1d-d23b-497d-8ba7-44c8faa312dc)

Fortsetzung des Runner-Registrierungsprozesses
![image](https://github.com/user-attachments/assets/2e5dc2d3-f2da-497a-9b3b-f6780eb8dbcc)

3. Bearbeiten Sie nach Abschluss der Registrierung die `config.toml`-Datei:
   ```
   nano config/config.toml
   ```

4. Aktualisieren Sie den Inhalt der Datei wie folgt:
   ```toml
   concurrent = 1
   check_interval = 0
   shutdown_timeout = 0
   
   [session_server]
     session_timeout = 1800
   
   [[runners]]
     name = "DevOps Runner"
     url = "https://gitlab.devops.it"
     id = 24
     token = "glrt--EsPzxxxxxxxxxxxxxx"
     token_obtained_at = 2024-09-17T12:52:43Z
     token_expires_at = 0001-01-01T00:00:00Z
     executor = "docker"
     environment = ["HTTP_PROXY=http://proxy.devops.it:8080", "HTTPS_PROXY=http://proxy.devops.it:8080", "NO_PROXY=localhost,127.0.0.1,docker"]
     [runners.docker]
       tls_verify = false
       image = "registry.devops.it/devops/containers/docker:latest"
       privileged = true
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false 
       volumes = ["/cache", "/root/.m2:/root/.m2:rw"]
       pull_policy = ["if-not-present"]
       shm_size = 0
       network_mtu = 0
   ```
   Hinweis: Passen Sie URL, Token und andere Werte an Ihre Umgebung an.

5. Starten Sie den Runner neu:
   ```
   docker-compose restart
   ```

## CI/CD Pipeline-Konfiguration und Variablen

1. Gehen Sie zu "Settings" > "CI/CD" in Ihrem GitLab-Projekt, um CI/CD-Variablen zu definieren.

2. Finden Sie den Abschnitt "Variables" und klicken Sie auf "Expand".

3. Klicken Sie auf "Add variable" und fügen Sie die folgenden Variablen hinzu:

   - INTERN_CI_REGISTRY:
     * Key: INTERN_CI_REGISTRY
     * Value: registry.devops.it (oder die Adresse Ihres internen Docker-Registrys)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Nicht ankreuzen

   - CI_REGISTRY_PASSWORD:
     * Key: CI_REGISTRY_PASSWORD
     * Value: (Passwort für Ihr Docker-Registry)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Ankreuzen

   - CI_REGISTRY_USER:
     * Key: CI_REGISTRY_USER
     * Value: (Benutzername für Ihr Docker-Registry)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Nicht ankreuzen

   - APPLICATION_PROPERTIES:
     * Key: APPLICATION_PROPERTIES
     * Value: (Inhalt Ihrer application.properties-Datei)
     * Type: File
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Nicht ankreuzen

   - SSH_PRIVATE_KEY:
     * Key: SSH_PRIVATE_KEY
     * Value: (Privater SSH-Schlüssel für das Deployment)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Ankreuzen

   - HOST:
     * Key: HOST
     * Value: (Adresse des Deployment-Servers)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Nicht ankreuzen

   - USER:
     * Key: USER
     * Value: (Benutzername für das Deployment)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: Ankreuzen
     * Mask variable: Nicht ankreuzen

4. Speichern Sie jede Variable, indem Sie auf "Add variable" klicken.

Hinweis: CI_REGISTRY, CI_PIPELINE_IID und CI_REGISTRY_IMAGE werden automatisch von GitLab bereitgestellt und müssen nicht manuell definiert werden.

5. Gehen Sie zur Hauptseite Ihres GitLab-Projekts.
6. Klicken Sie auf das "+"-Symbol in der oberen linken Ecke und wählen Sie "New file".
7. Geben Sie im Feld "File name" `.gitlab-ci.yml` ein.
8. Fügen Sie den folgenden YAML-Code in den Inhaltsbereich ein:

```yaml
default: 
  tags:
    - devops-3

variables: 
  DOCKER_TLS_CERTDIR: ""  

services:
  - name: $INTERN_CI_REGISTRY/docker:dind
    alias: docker 

stages:
  - build
  - package-und-push
  - deploy
  - rollback 

cache:
  paths:
    - target/*.war
    
.docker-login: &docker-login
  before_script: 
    - echo "$CI_REGISTRY_PASSWORD" | docker -v login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"

build:
  stage: build 
  image: $INTERN_CI_REGISTRY/maven:latest
  script:
    - echo "$APPLICATION_PROPERTIES" > src/main/resources/application.properties
    - mvn clean install -DskipTests

package-und-push:
  stage: package-und-push
  image: $INTERN_CI_REGISTRY/docker:latest
  <<: *docker-login
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_PIPELINE_IID -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_PIPELINE_IID 
    - docker push $CI_REGISTRY_IMAGE:latest

deploy:
  stage: deploy
  image: $INTERN_CI_REGISTRY/alpine:sshclient
  before_script: 
    - eval $(ssh-agent -s) 
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh && chmod 700 ~/.ssh
    - ssh-keyscan -H $HOST >> ~/.ssh/known_hosts  
  script:
  - |
    ssh $USER@$HOST << EOF
      echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
      cd $PIPE_DIR
      docker compose pull
      docker compose up -d --force-recreate
      docker image prune -f
      docker logout "$CI_REGISTRY" 
    EOF 

rollback:
  stage: rollback
  image: $INTERN_CI_REGISTRY/alpine:sshclient
  before_script: 
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh && chmod 700 ~/.ssh
    - ssh-keyscan -H $HOST >> ~/.ssh/known_hosts  
  script:
  - |
    ssh $USER@$HOST << EOF
      echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
      cd $PIPE_DIR
      docker pull $CI_REGISTRY_IMAGE:$((CI_PIPELINE_IID - 1))
      docker tag $CI_REGISTRY_IMAGE:$((CI_PIPELINE_IID - 1)) $CI_REGISTRY_IMAGE:latest
      docker compose up -d --force-recreate
      docker logout "$CI_REGISTRY"
    EOF
  when: manual
```

9. Klicken Sie auf "Commit changes" am unteren Rand der Seite.

Screenshot der .gitlab-ci.yml-Datei in GitLab
![image](https://github.com/user-attachments/assets/25654872-7d91-48bd-b994-762ae3852c6b)

## Testen der Pipeline

1. Gehen Sie zur Hauptseite Ihres GitLab-Projekts.
2. Öffnen Sie eine beliebige Datei (z.B. README.md) und nehmen Sie eine kleine Änderung vor.
3. Klicken Sie auf "Commit changes", um die Änderung zu speichern.
4. Gehen Sie im linken Menü zu "CI/CD" > "Pipelines".
5. Sie sollten sehen, dass eine neue Pipeline gestartet wurde. Beobachten Sie den Status der Pipeline.

Wenn die Pipeline erfolgreich abgeschlossen wird, herzlichen Glückwunsch! Ihr CI/CD-System funktioniert. Falls Fehler auftreten, erfahren Sie im nächsten Abschnitt, wie Sie diese beheben können.

## Fehlerbehebung

Wenn Fehler in Ihrer Pipeline auftreten, folgen Sie diesen Schritten:

1. Klicken Sie auf den fehlgeschlagenen Job, um die Details anzuzeigen.
2. Lesen Sie die Fehlermeldung sorgfältig. Sie enthält oft Hinweise darauf, was das Problem sein könnte.

Häufige Probleme und ihre Lösungen:

a) Docker Registry Verbindungsprobleme:
   - Stellen Sie sicher, dass CI_REGISTRY_USER und CI_REGISTRY_PASSWORD korrekt definiert sind.
   - Überprüfen Sie, ob INTERN_CI_REGISTRY die richtige URL enthält.

b) SSH-Verbindungsprobleme:
   - Überprüfen Sie, ob SSH_PRIVATE_KEY, HOST und USER korrekt definiert sind.
   - Stellen Sie sicher, dass der Zielserver erreichbar ist.

c) Build-Fehler:
   - Überprüfen Sie, ob APPLICATION_PROPERTIES den richtigen Inhalt hat.
   - Stellen Sie sicher, dass die Abhängigkeiten Ihres Projekts korrekt konfiguriert sind.

d) Runner-Verbindungsprobleme:
   - Überprüfen Sie, ob der Runner läuft: `docker ps | grep gitlab-runner`
   - Stellen Sie sicher, dass der Runner in GitLab registriert ist: GitLab > Settings > CI/CD > Runners

e) Docker Compose Fehler:
   - Überprüfen Sie die Syntax der docker-compose.yml Datei.
   - Stellen Sie sicher, dass Sie die neuesten Versionen von Docker und Docker Compose verwenden.

## Allgemeine Wartung und Best Practices

1. Regelmäßige Updates:
   - Aktualisieren Sie GitLab Runner regelmäßig:
     ```
     docker-compose pull
     docker-compose up -d
     ```
   - Halten Sie Docker und Docker Compose auf dem neuesten Stand:
     ```
     sudo apt update
     sudo apt upgrade docker-ce docker-ce-cli containerd.io
     ```

2. Sicherheit:
   - Speichern Sie sensible Informationen (Passwörter, API-Schlüssel) immer als CI/CD-Variablen und vergessen Sie nicht, sie zu maskieren.
   - Führen Sie regelmäßig Sicherheitsupdates auf der Maschine durch, auf der der Runner läuft.

3. Leistungsüberwachung:
   - Verwenden Sie die Monitoring-Funktionen von GitLab, um die Runner-Leistung zu überwachen.
   - Wechseln Sie bei Bedarf zu einer leistungsfähigeren Maschine oder verwenden Sie mehrere Runner.

4. Backup:
   - Sichern Sie die Runner-Konfigurationsdateien (`config.toml`) regelmäßig.
   - Bewahren Sie eine Kopie Ihrer CI/CD-Variablen an einem sicheren Ort auf.

5. Dokumentation:
   - Dokumentieren Sie Ihre Pipeline-Konfiguration und spezielle Anforderungen.
   - Notieren Sie Fehlerbehebungsschritte und Lösungen.

## Fortgeschrittene Anpassungen

1. Parallele Jobs:
   - Definieren Sie parallele Jobs in Ihrer .gitlab-ci.yml-Datei, um die Build-Zeit zu verkürzen.

2. Caching-Strategien:
   - Cachen Sie Abhängigkeiten und Build-Artefakte, um die Pipeline-Leistung zu verbessern.

3. Umgebungsspezifische Deployments:
   - Erstellen Sie separate Deployment-Jobs für verschiedene Umgebungen (dev, staging, production).

4. Benutzerdefinierte Docker Images:
   - Erstellen Sie projektspezifische Docker Images, um den Build-Prozess zu beschleunigen.

5. GitLab Auto DevOps:
   - Erkunden Sie die Auto DevOps-Funktionen von GitLab und integrieren Sie geeignete Funktionen.

## Fazit

Herzlichen Glückwunsch! Sie haben nun erfolgreich GitLab Runner installiert, konfiguriert und eine CI/CD-Pipeline erstellt. Dieses System wird Ihnen helfen, Ihren Softwareentwicklungsprozess zu automatisieren und zu beschleunigen.

Denken Sie daran, dass CI/CD eine Reise ist. Lernen Sie kontinuierlich dazu und verbessern Sie Ihr System weiter. Teilen Sie Herausforderungen und Lösungen mit Ihrem Team. Viel Erfolg und fröhliches Codieren!
