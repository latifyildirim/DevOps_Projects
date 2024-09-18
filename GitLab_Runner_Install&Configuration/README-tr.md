# Kapsamlı GitLab Runner Kurulum Kılavuzu

## İçindekiler
1. [Giriş](#giriş)
2. [Gereksinimler](#gereksinimler)
3. [Docker ve Docker Compose Kurulumu](#docker-ve-docker-compose-kurulumu)
4. [Runner Yapılandırması](#runner-yapılandırması)
5. [GitLab Runner Kurulumu](#gitlab-runner-kurulumu)
6. [GitLab'da Runner Ekleme ve Token Alma](#gitlabda-runner-ekleme-ve-token-alma)
7. [Dockerfile Oluşturma](#dockerfile-oluşturma)
8. [CI/CD Pipeline Konfigürasyonu ve Değişkenler](#cicd-pipeline-konfigürasyonu-ve-değişkenler)
9. [Pipeline'ı Test Etme](#pipelineı-test-etme)
10. [Sorun Giderme](#sorun-giderme)
11. [Genel Bakım ve İyi Uygulamalar](#genel-bakım-ve-iyi-uygulamalar)
12. [İleri Seviye Özelleştirmeler](#i̇leri-seviye-özelleştirmeler)
13. [Sonuç](#sonuç)

## Giriş

Bu kılavuz, GitLab Runner'ın Docker Compose kullanılarak Ubuntu makinede nasıl kurulacağını adım adım açıklamaktadır. Hiç deneyimi olmayan kullanıcılar için hazırlanmış olup, GitLab projeleriniz için otomatik build, test ve deployment imkanı sağlayan bir CI/CD ortamı oluşturmanıza yardımcı olacaktır.

## Gereksinimler

- Ubuntu 20.04 LTS veya daha yeni bir sürüm
- Sudo yetkilerine sahip bir kullanıcı
- İnternet bağlantısı
- GitLab hesabı ve bir GitLab projesi

## Docker ve Docker Compose Kurulumu

### Docker Kurulumu

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

### Docker Compose Kurulumu

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

## GitLab Runner Kurulumu

1. GitLab Runner için yeni bir dizin oluşturun:
   ```
   mkdir gitlab-runner-1 && cd gitlab-runner-1
   ```

2. Bu dizinde `docker-compose.yml` adlı bir dosya oluşturun:
   ```
   nano docker-compose.yml
   ```

3. Açılan editöre aşağıdaki içeriği yapıştırın:
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
   Not: Proxy ayarlarını kendi ortamınıza göre değiştirin veya gerekli değilse environment bölümünü tamamen kaldırın.

4. Dosyayı kaydetmek için Ctrl+X, ardından Y ve Enter tuşlarına basın.

5. GitLab Runner'ı başlatın:
   ```
   docker-compose up -d
   ```

6. Runner'ın başarıyla çalıştığını kontrol edin:
   ```
   docker ps
   ```

## GitLab'da Runner Ekleme ve Token Alma

1. GitLab projenize gidin ve sol menüden "Settings" > "CI/CD" seçeneğine tıklayın.
2. Sayfayı aşağı kaydırın ve "Runners" bölümünü bulun.
3. "New project runner" butonuna tıklayın.
4. Runner için bir açıklama girin (örneğin, "DevOps-3 Runner").
5. Tags kısmına "devops-3" yazın (bu, .gitlab-ci.yml dosyasında belirttiğimiz tag ile eşleşmelidir).
6. "Create runner" butonuna tıklayın.
7. Oluşturulan runner'ın detaylarında gösterilen registration token'ı kopyalayın. Bu token'ı runner'ı kaydederken kullanacaksınız.
![image](https://github.com/user-attachments/assets/9f2dcc23-2f8a-47c8-8b03-e98f9b2ed755)

## Runner Yapılandırması

1. Runner'ı kaydetmek için aşağıdaki komutu çalıştırın:
   ```
   docker exec -it gitlab-runner-1 gitlab-runner register
   ```

2. Kayıt işlemi sırasında aşağıdaki bilgileri girin:
   - GitLab instance URL: https://gitlab.devops.it (veya sizin GitLab URL'niz)
   - Registration token: (GitLab projenizden alacaksınız)
   - Description: DevOps Runner (veya istediğiniz bir açıklama)
   - Executor: docker
   - Docker image: registry.devops.it/devops/containers/docker:latest (veya projeniz için uygun bir etiket)
![image](https://github.com/user-attachments/assets/79ff0b1d-d23b-497d-8ba7-44c8faa312dc)
![image](https://github.com/user-attachments/assets/2e5dc2d3-f2da-497a-9b3b-f6780eb8dbcc)

3. Kaydı tamamladıktan sonra, `config.toml` dosyasını düzenleyin:
   ```
   nano config/config.toml
   ```

4. Dosyanın içeriğini aşağıdaki gibi güncelleyin:
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
   Not: URL, token ve diğer değerleri kendi ortamınıza göre ayarlayın.

5. Runner'ı yeniden başlatın:
   ```
   docker-compose restart
   ```

## Dockerfile Oluşturma

1. GitLab projenizin ana sayfasına dönün.
2. Yine "+" simgesine tıklayın ve "New file" seçeneğini seçin.
3. "File name" alanına `Dockerfile` yazın (büyük 'D' ile başladığından emin olun).
4. İçerik alanına aşağıdaki kodu yapıştırın:

```dockerfile
FROM registry.devops.it/devops/containers/tomcat:latest
RUN rm -rf /usr/local/tomcat/webapps/* 
COPY target/*.war /usr/local/tomcat/webapps/dx4api.war
EXPOSE 8080 
CMD ["catalina.sh", "run"]
```

5. Sayfanın altındaki "Commit changes" butonuna tıklayın.

## CI/CD Pipeline Konfigürasyonu ve Değişkenler

1. CI/CD değişkenlerini tanımlamak için, GitLab projenizde "Settings" > "CI/CD" bölümüne gidin.

2. "Variables" bölümünü bulun ve "Expand" butonuna tıklayın.

3. "Add variable" butonuna tıklayarak aşağıdaki değişkenleri ekleyin:

   - INTERN_CI_REGISTRY:
     * Key: INTERN_CI_REGISTRY
     * Value: registry.devops.it (veya kendi iç Docker registry'nizin adresi)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretlemeyin

   - CI_REGISTRY_PASSWORD:
     * Key: CI_REGISTRY_PASSWORD
     * Value: (Docker registry'niz için kullanıcı şifresi)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretleyin

   - CI_REGISTRY_USER:
     * Key: CI_REGISTRY_USER
     * Value: (Docker registry'niz için kullanıcı adı)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretlemeyin

   - APPLICATION_PROPERTIES:
     * Key: APPLICATION_PROPERTIES
     * Value: (Uygulamanızın properties dosyasının içeriği)
     * Type: File
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretlemeyin

   - SSH_PRIVATE_KEY:
     * Key: SSH_PRIVATE_KEY
     * Value: (Deployment için kullanılacak SSH özel anahtarı)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretleyin

   - HOST:
     * Key: HOST
     * Value: (Deployment yapılacak sunucunun adresi)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretlemeyin

   - USER:
     * Key: USER
     * Value: (Deployment için kullanılacak kullanıcı adı)
     * Type: Variable
     * Environment scope: All (default)
     * Protect variable: İşaretleyin
     * Mask variable: İşaretlemeyin

4. Her değişken için "Add variable" butonuna tıklayarak kaydedin.

Not: CI_REGISTRY, CI_PIPELINE_IID ve CI_REGISTRY_IMAGE değişkenleri GitLab tarafından otomatik olarak sağlanır, bunları manuel olarak tanımlamanıza gerek yoktur.

5. GitLab projenizin ana sayfasına gidin.
6. Sol üst köşedeki "+" simgesine tıklayın ve "New file" seçeneğini seçin.
7. "File name" alanına `.gitlab-ci.yml` yazın.
8. İçerik alanına aşağıdaki YAML kodunu yapıştırın:

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

9. Sayfanın altındaki "Commit changes" butonuna tıklayın.

![image](https://github.com/user-attachments/assets/25654872-7d91-48bd-b994-762ae3852c6b)

## Pipeline'ı Test Etme

1. GitLab projenizin ana sayfasına gidin.
2. Herhangi bir dosyayı açın (örneğin, README.md) ve küçük bir değişiklik yapın.
3. "Commit changes" butonuna tıklayarak değişikliği kaydedin.
4. Sol menüden "CI/CD" > "Pipelines" seçeneğine tıklayın.
5. En üstte yeni bir pipeline'ın başladığını göreceksiniz. Pipeline'ın durumunu gözlemleyin.

Pipeline başarıyla tamamlanırsa, tebrikler! CI/CD sisteminiz çalışıyor demektir. Eğer hatalar alırsanız, bir sonraki bölümde bu hataları nasıl gidereceğinizi öğreneceksiniz.

## Sorun Giderme

Pipeline'ınızda hatalar oluşursa, aşağıdaki adımları izleyin:

1. Hata alan job'a tıklayarak detayları görüntüleyin.
2. Hata mesajını dikkatlice okuyun. Genellikle sorunun ne olduğuna dair ipuçları içerir.

Sık karşılaşılan sorunlar ve çözümleri:

a) Docker Registry Bağlantı Sorunları:
   - CI_REGISTRY_USER ve CI_REGISTRY_PASSWORD değişkenlerinin doğru tanımlandığından emin olun.
   - INTERN_CI_REGISTRY değişkeninin doğru URL'yi içerdiğinden emin olun.

b) SSH Bağlantı Sorunları:
   - SSH_PRIVATE_KEY, HOST ve USER değişkenlerinin doğru tanımlandığından emin olun.
   - Hedef sunucunun erişilebilir olduğunu kontrol edin.

c) Build Hataları:
   - APPLICATION_PROPERTIES değişkeninin doğru içeriğe sahip olduğunu kontrol edin.
   - Projenizin bağımlılıklarının doğru yapılandırıldığından emin olun.

d) Runner Bağlantı Sorunları:
   - Runner'ın çalışır durumda olduğunu kontrol edin: `docker ps | grep gitlab-runner`
   - Runner'ın GitLab'a kayıtlı olduğunu doğrulayın: GitLab > Settings > CI/CD > Runners

e) Docker Compose Hataları:
   - docker-compose.yml dosyasının syntax'ını kontrol edin.
   - Docker ve Docker Compose'un en güncel sürümlerini kullandığınızdan emin olun.

## Genel Bakım ve İyi Uygulamalar

1. Düzenli Güncellemeler:
   - GitLab Runner'ı düzenli olarak güncelleyin:
     ```
     docker-compose pull
     docker-compose up -d
     ```
   - Docker ve Docker Compose'u güncel tutun:
     ```
     sudo apt update
     sudo apt upgrade docker-ce docker-ce-cli containerd.io
     ```

2. Güvenlik:
   - Hassas bilgileri (şifreler, API anahtarları) her zaman CI/CD değişkenleri olarak saklayın ve maskelemeyi unutmayın.
   - Runner'ın çalıştığı makinenin güvenlik güncellemelerini düzenli olarak yapın.

3. Performans İzleme:
   - GitLab'ın Monitoring özelliklerini kullanarak Runner performansını izleyin.
   - Gerekirse, daha güçlü bir makineye geçiş yapın veya birden fazla Runner kullanın.

4. Yedekleme:
   - Runner yapılandırma dosyalarını (`config.toml`) düzenli olarak yedekleyin.
   - CI/CD değişkenlerinin bir kopyasını güvenli bir yerde saklayın.

5. Dökümantasyon:
   - Pipeline yapılandırmanızı ve özel gereksinimleri belgelendirin.
   - Sorun giderme adımlarını ve çözümlerini kaydedin.

## İleri Seviye Özelleştirmeler

1. Paralel Job'lar:
   - `.gitlab-ci.yml` dosyanızda paralel job'lar tanımlayarak build süresini kısaltın.

2. Caching Stratejileri:
   - Bağımlılıkları ve build artifactlerini cache'leyerek pipeline performansını artırın.

3. Environment-Specific Deployments:
   - Farklı ortamlar (dev, staging, production) için ayrı deployment job'ları oluşturun.

4. Custom Docker Images:
   - Projenize özel Docker imajları oluşturarak build sürecini hızlandırın.

5. GitLab Auto DevOps:
   - GitLab'ın Auto DevOps özelliklerini keşfedin ve uygun olanları entegre edin.

## Sonuç

Tebrikler! Artık GitLab Runner'ı başarıyla kurmuş, yapılandırmış ve bir CI/CD pipeline'ı oluşturmuş bulunuyorsunuz. Bu sistem, yazılım geliştirme sürecinizi otomatikleştirmenize ve hızlandırmanıza yardımcı olacaktır.

Unutmayın, CI/CD bir yolculuktur. Sürekli öğrenmeye ve sisteminizi iyileştirmeye devam edin. Karşılaştığınız zorlukları ve çözümleri ekibinizle paylaşın. İyi şanlar ve mutlu kodlamalar!
