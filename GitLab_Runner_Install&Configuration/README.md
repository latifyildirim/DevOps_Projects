# GitLab Runner'ın Docker Compose ile Ubuntu Makinede Kurulumu

## İçindekiler
1. Giriş
2. Gereksinimler
3. Docker ve Docker Compose Kurulumu
4. GitLab Runner Kurulumu
5. Runner Yapılandırması
6. CI/CD Pipeline Konfigürasyonu
7. Tomcat Dockerfile Açıklaması
8. Tüm Sistemi Çalıştırma
9. Sorun Giderme
10. Sonuç

## 1. Giriş

Bu dokümantasyon, GitLab Runner'ın Docker Compose kullanılarak Ubuntu makinede nasıl kurulacağını adım adım açıklamaktadır. Bu kılavuz, GitLab CI/CD pipeline'larınızı çalıştırmak için güvenli ve izole bir ortam oluşturmanıza yardımcı olacaktır.

## 2. Gereksinimler

- Ubuntu 20.04 LTS veya daha yeni bir sürüm
- Sudo yetkilerine sahip bir kullanıcı
- İnternet bağlantısı
- GitLab hesabı ve bir GitLab projesi

## 3. Docker ve Docker Compose Kurulumu

### 3.1 Docker Kurulumu

1. Sistem paketlerini güncelleyin:
   ```
   sudo apt update
   sudo apt upgrade -y
   ```

2. Docker'ın resmi GPG anahtarını ekleyin:
   ```
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

3. Docker'ın resmi apt repository'sini ekleyin:
   ```
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

4. Paket listesini güncelleyin ve Docker'ı kurun:
   ```
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io -y
   ```

5. Docker servisini başlatın ve sistem başlangıcında otomatik başlamasını sağlayın:
   ```
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

6. Mevcut kullanıcıyı docker grubuna ekleyin:
   ```
   sudo usermod -aG docker $USER
   ```

7. Değişikliklerin etkili olması için oturumu kapatıp açın veya sistemi yeniden başlatın.

### 3.2 Docker Compose Kurulumu

1. Docker Compose'un en son sürümünü indirin:
   ```
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   ```

2. İndirilen dosyaya çalıştırma izni verin:
   ```
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. Kurulumu doğrulayın:
   ```
   docker-compose --version
   ```

## 4. GitLab Runner Kurulumu

1. Proje dizininde bir `docker-compose.yml` dosyası oluşturun:
   ```
   mkdir gitlab-runner && cd gitlab-runner
   nano docker-compose.yml
   ```

2. Aşağıdaki içeriği `docker-compose.yml` dosyasına ekleyin:

```yaml
version: '3'
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
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

FOTO-1: docker-compose.yml dosyasının içeriğini gösteren ekran görüntüsü
![image](https://github.com/user-attachments/assets/57860763-1168-4caf-b72d-7bac9374eb97)

3. GitLab Runner'ı başlatın:
   ```
   docker-compose up -d
   ```

FOTO-2: GitLab Runner'ın başarıyla başlatıldığını gösteren terminal çıktısı
![image](https://github.com/user-attachments/assets/4d87e3a9-316e-4c6d-bfa9-937507c6b27e)

## 5. Runner Yapılandırması

1. Runner'ı kaydetmek için aşağıdaki komutu çalıştırın:
   ```
   docker exec -it gitlab-runner gitlab-runner register
   ```

2. Kayıt işlemi sırasında aşağıdaki bilgileri girin:
   - GitLab instance URL: https://gitlab.devops.it
   - Registration token: (GitLab projenizden alın)
   - Description: devops
   - Tags: devops
   - Executor: docker

3. Kaydı tamamladıktan sonra, `config.toml` dosyasını düzenleyin:
   ```
   nano config/config.toml
   ```

4. Dosyanın içeriğini aşağıdaki gibi güncelleyin:

```toml
[[runners]]
  name = "devops"
  url = "https://gitlab.devops.it"
  id = 13
  token = "gast-123afasd-Fs"
  token_obtained_at = 0001-01-01T00:00:00Z
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

FOTO-3: Düzenlenmiş config.toml dosyasının içeriğini gösteren ekran görüntüsü
![image](https://github.com/user-attachments/assets/5b5a224a-11ad-4b7b-aad3-e8ef0f4026fb)

5. Runner'ı yeniden başlatın:
   ```
   docker-compose restart
   ```

## 6. CI/CD Pipeline Konfigürasyonu

GitLab projenizde `.gitlab-ci.yml` dosyası oluşturun ve aşağıdaki içeriği ekleyin:

```yaml
default: 
  tags:
    - devops

variables: 
  DOCKER_TLS_CERTDIR: ""  

services:
  - name: $CI_REGISTRY/docker:dind
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
  image: $CI_REGISTRY/maven:latest
  script:
    - echo "$APPLICATION_PROPERTIES" > src/main/resources/application.properties
    - mvn clean install -DskipTests

package-und-push:
  stage: package-und-push
  image: $CI_REGISTRY/docker:latest
  <<: *docker-login
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_PIPELINE_IID -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_PIPELINE_IID 
    - docker push $CI_REGISTRY_IMAGE:latest

deploy:
  stage: deploy
  image: $CI_REGISTRY/alpine:sshclient
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
  image: $CI_REGISTRY/alpine:sshclient
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

## 7. Tomcat Dockerfile Açıklaması

Projenizin kök dizininde bir `Dockerfile` oluşturun ve aşağıdaki içeriği ekleyin:

```dockerfile
FROM registry.devops.it/devops/containers/tomcat:latest
RUN rm -rf /usr/local/tomcat/webapps/* 
COPY target/*.war /usr/local/tomcat/webapps/dx4api.war
EXPOSE 8080 
CMD ["catalina.sh", "run"]
```

Bu Dockerfile:
1. Özel Tomcat imajını temel alır.
2. Varsayılan webapps dizinini temizler.
3. Derlenen WAR dosyasını Tomcat'in webapps dizinine kopyalar.
4. 8080 portunu dışarıya açar.
5. Tomcat'i başlatır.

## 8. Tüm Sistemi Çalıştırma

1. GitLab projenize bir commit push'layın.
2. GitLab arayüzünden CI/CD pipeline'ının başladığını doğrulayın.
3. Pipeline aşamalarının başarıyla tamamlandığını gözlemleyin.

FOTO-4: Başarılı bir pipeline çalışmasını gösteren GitLab CI/CD paneli ekran görüntüsü
![image](https://github.com/user-attachments/assets/8fd98fdf-4a06-4234-af5b-95630739a1bc)

## 9. Sorun Giderme

- Runner bağlantı sorunları için:
  - Proxy ayarlarını kontrol edin.
  - GitLab URL'sinin doğru olduğundan emin olun.
- Docker hataları için:
  - Docker daemon'un çalıştığından emin olun: `sudo systemctl status docker`
  - Docker socket'inin doğru monte edildiğini kontrol edin.
- Pipeline hataları için:
  - `.gitlab-ci.yml` dosyasının syntax'ını kontrol edin.
  - Gerekli ortam değişkenlerinin tanımlandığından emin olun.

## 10. Sonuç

Bu dokümantasyon, GitLab Runner'ı Docker Compose kullanarak Ubuntu makinenizde nasıl kuracağınızı, yapılandıracağınızı ve CI/CD pipeline'ınızı nasıl oluşturacağınızı adım adım gösterdi. Bu kurulum, projeniz için güvenli ve ölçeklenebilir bir CI/CD ortamı sağlayacaktır.

Herhangi bir sorunla karşılaşırsanız, lütfen GitLab dokümantasyonuna başvurun veya IT destek ekibinizle iletişime geçin.
