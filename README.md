# 개발자 작업실 구축

## 프로젝트 개요

터미널, 파일 권한, Docker, Git/GitHub의 기본 흐름을 직접 실행하고 결과를 기록하는 과제입니다. 이 문서는 실제로 실행한 명령과 결과만 기록하며, 다른 사람이 같은 순서로 따라 하면 같은 환경을 재현할 수 있도록 정리했습니다.

### 저장소 구조

```text
E1-1/
├── README.md          # 중심 안내서(수행 로그, 검증, 트러블슈팅)
├── Dockerfile         # nginx:alpine 기반 커스텀 웹 이미지
├── site/
│   └── index.html     # 컨테이너가 제공하는 정적 페이지
├── practice/          # 터미널 조작 실습 결과 파일
└── evidence/          # 브라우저 캡처 등 증거 파일
```

## 실행 환경

- OS: Windows 11 Home (10.0.26200)
- 작업공간: 최초 `D:\E1-1`에서 실습, 이후 `E:\E1-1`로 이동해 마무리(드라이브 문자만 다르고 내용은 동일)
- 터미널/쉘: PowerShell 7 (Windows 터미널), Linux 명령은 Ubuntu 컨테이너의 bash
- Docker CLI: `Docker version 29.6.2, build dfc4efb`
- Docker 엔진: Docker Desktop (Linux 엔진). 엔진 실행 후 `docker info`에서 Client/Server 정보 확인
- Git: `git version 2.56.0.windows.4`
- 확인일: 2026-11-20 ~ 2026-11-25

## 수행 체크리스트

- [x] PowerShell 터미널 기본 파일 조작
- [x] Linux 파일/디렉토리 권한 전후 비교
- [x] Docker CLI 버전 및 엔진 연결 상태 확인
- [x] `hello-world` 컨테이너
- [x] Ubuntu 컨테이너
- [x] Dockerfile 커스텀 이미지 빌드
- [x] 커스텀 이미지 컨테이너 실행
- [x] 포트 매핑 접속 확인
- [x] 바인드 마운트 변경 반영
- [x] named volume 영속성
- [x] Git 사용자 설정, 로컬 저장소 커밋
- [x] GitHub 원격 저장소 연결 및 push (<https://github.com/solarjina-geena/E1-1>)
- [ ] VS Code GitHub 로그인 및 소스 제어 연동 확인

## 수행 로그 및 검증

### PowerShell 기본 조작

가이드의 홈 디렉터리 경로(`C:\Users\JINA KANG\developer-workstation-lab`) 생성은 `Access to the path ... is denied`로 실패했습니다. 과제 파일을 둔 작업공간 아래에서 `practice` 폴더를 만들어 같은 조작을 수행했습니다.

실행한 명령과 핵심 출력:

```powershell
Get-Location
# D:\ALL IN ONE\E1-1

New-Item -ItemType Directory -Name "practice"
Set-Content -Path ".\practice\notes.txt" -Value "첫 번째 터미널 실습"
Get-Content ".\practice\notes.txt"
# 첫 번째 터미널 실습

Copy-Item ".\practice\notes.txt" ".\practice\notes-copy.txt"
Rename-Item ".\practice\notes-copy.txt" "renamed.txt"
New-Item -ItemType File -Path ".\practice\empty.txt"
Get-ChildItem ".\practice"
Remove-Item ".\practice\renamed.txt"
Get-ChildItem ".\practice"
# 최종 목록: empty.txt, notes.txt
```

명령 의미와 결과: `Get-Location`은 현재 작업 경로를 보여줍니다. `New-Item`은 폴더/파일 생성, `Set-Content`와 `Get-Content`는 파일 쓰기/읽기, `Copy-Item`은 복사, `Rename-Item`은 이름 변경, `Get-ChildItem`은 항목 목록 확인, `Remove-Item`은 지정한 항목 삭제에 사용했습니다. 마지막 목록에 `notes.txt`와 `empty.txt`만 남아 이름을 바꿨던 복사본만 삭제된 것을 확인했습니다. 결과 파일은 저장소의 [practice/](practice/) 폴더에 그대로 남아 있습니다.

### 절대 경로와 상대 경로

- 절대 경로는 드라이브(또는 Linux의 루트 `/`)부터 시작하는 전체 위치입니다. 예: `E:\E1-1\practice\notes.txt`, 컨테이너 안의 `/usr/share/nginx/html`.
- 상대 경로는 현재 위치(`Get-Location`/`pwd`)를 기준으로 한 위치입니다. 위 실습의 `.\practice\notes.txt`는 현재 위치가 `E:\E1-1`일 때 `E:\E1-1\practice\notes.txt`를 가리킵니다. `.`은 현재 폴더, `..`은 상위 폴더입니다.
- 이번 과제에서 작업 폴더를 `D:`에서 `E:`로 옮겼지만 README와 명령이 상대 경로(`.\practice`, `site/`, `COPY site/ ...`)를 쓰기 때문에 그대로 재사용할 수 있었습니다. 반대로 바인드 마운트의 `source`는 Docker가 절대 경로를 요구하므로 `$((Get-Location).Path)\site`처럼 현재 위치로 절대 경로를 만들어 전달했습니다.

### Docker/Git 환경 확인

```text
docker --version
Docker version 29.6.2, build dfc4efb

docker info
Client 버전은 확인됨. Server 연결 실패:
failed to connect to the Docker API at npipe:////./pipe/docker_engine

git --version
git version 2.56.0.windows.4
```

`docker --version`은 CLI 버전을 확인하며 `29.6.2`가 출력됐습니다. `docker info`는 Docker 클라이언트와 엔진(Server) 상태를 확인합니다. 최초에는 엔진 파이프 연결 오류가 있었고, 이후 엔진 연결을 시작해 Client와 Server 정보가 모두 표시됨을 확인했습니다. `git --version`은 Git 설치 버전을 확인하며 `2.56.0.windows.4`가 출력됐습니다.

초기 확인 당시에는 엔진이 미연결 상태였으나, 이후 Docker Desktop 엔진이 연결된 것을 `docker info`에서 확인하고 아래 컨테이너 실습을 완료했습니다.

### `hello-world` 컨테이너

2026-11-20에 사용자가 PowerShell에서 직접 실행한 결과입니다.

```powershell
docker run --rm hello-world
```

처음 실행하여 `hello-world:latest` 이미지를 Docker Hub에서 내려받았고, 컨테이너 실행 후 다음 메시지를 확인했습니다.

```text
Hello from Docker!
The Docker client contacted the Docker daemon.
The Docker daemon pulled the "hello-world" image from the Docker Hub.
The Docker daemon created a new container from that image.
```

명령 의미와 결과:

- `docker run`은 이미지가 로컬에 없으면 내려받고 새 컨테이너를 만들어 실행합니다.
- `--rm`은 컨테이너가 종료되면 컨테이너를 자동 제거합니다.
- `hello-world`는 사용할 이미지 이름입니다. 로컬에 없어 Docker Hub에서 내려받았고 `Hello from Docker!`가 출력되어 데몬 연결, 이미지 다운로드, 컨테이너 실행이 성공한 것을 확인했습니다. 자동 제거 옵션으로 컨테이너는 남지 않지만 이미지는 로컬에 보관됩니다.

### Ubuntu 컨테이너 관찰

PowerShell에서 실행하여 `ubuntu:latest` 이미지를 내려받고 대화형 컨테이너에 진입했습니다.

```powershell
docker run -it --name ubuntu-practice ubuntu bash
```

컨테이너 안에서 실행한 명령과 실제 핵심 출력:

```bash
ls /
# bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var
echo "hello from container"
# hello from container
exit
# PowerShell 프롬프트로 복귀
```

컨테이너 내부 프롬프트가 `root@9e73323536c7:/#` 형태로 바뀌었고, `exit`로 주 프로세스를 끝내자 PowerShell로 돌아왔습니다.

명령 의미와 결과:

- `docker run`은 이미지로 컨테이너를 생성하고 실행합니다. Ubuntu 이미지가 로컬에 없어 `ubuntu:latest`를 내려받았습니다.
- `-it`는 대화형 터미널을 연결해 컨테이너 내부에서 명령을 직접 입력할 수 있게 합니다.
- `--name ubuntu-practice`는 컨테이너에 후속 명령에서 쓸 이름을 붙입니다.
- `ubuntu`는 실행할 이미지이고, `bash`는 컨테이너의 대화형 셸 프로세스입니다.
- `ls /`는 루트 디렉터리 내용을 나열합니다. `bin`, `etc`, `home`, `usr` 등 Ubuntu 파일 시스템의 최상위 항목이 보였습니다.
- `echo "hello from container"`는 문자열을 터미널에 출력하며, 입력한 문장이 그대로 표시됐습니다.
- `exit`는 Bash를 끝냅니다. Bash가 컨테이너의 주 프로세스였으므로 컨테이너는 종료 상태가 되고 PowerShell로 돌아왔습니다.

### 컨테이너 상태 확인

사용자가 직접 실행한 `docker ps` 결과에는 `n8n` 하나가 `Up 16 minutes`로 표시됐고, 호스트 포트 `5678`이 컨테이너 포트 `5678`로 연결되어 있었습니다. `docker ps`는 실행 중인 컨테이너만 보여주므로 종료된 `ubuntu-practice`가 나오지 않은 것이 정상입니다. `n8n`은 기존 컨테이너로 확인되어 과제 중 변경하지 않았습니다.

이후 `docker ps -a` 결과:

```text
9e73323536c7   ubuntu   "bash"   3 minutes ago   Exited (0) 2 minutes ago   ubuntu-practice
447c7c37cb05   docker.n8n.io/n8nio/n8n   ...   Up 16 minutes   ...   n8n
```

`docker ps -a`는 실행 중뿐 아니라 종료된 컨테이너도 표시합니다. `ubuntu-practice`가 `Exited (0)`으로 나타나 정상 종료 코드로 끝난 것을 확인했습니다. `n8n`은 계속 실행 중인 별도 컨테이너입니다.

로그 확인 결과:

```powershell
docker logs ubuntu-practice
```

`docker logs`는 컨테이너 주 프로세스가 표준 출력/오류로 남긴 로그를 표시합니다. 이번에는 대화형 Bash 세션에서 입력한 `ls/`의 오류 메시지, 올바른 `ls /`의 디렉터리 목록, `echo`의 출력, `exit`가 로그에 나타났습니다. 이는 컨테이너 파일 전체나 대화형 키 입력을 모두 기록하는 기능이 아니라, 컨테이너 프로세스가 출력한 내용을 확인하는 명령입니다.

컨테이너 정리:

```powershell
docker rm ubuntu-practice
# ubuntu-practice
```

`docker rm`은 종료된 컨테이너를 삭제합니다. 출력에 `ubuntu-practice`가 표시되어 제거가 완료됐습니다. 이미지와 실행 중인 `n8n` 컨테이너는 이 명령의 대상이 아니므로 그대로 유지됩니다.

## Dockerfile과 커스텀 내용

`Dockerfile`은 `nginx:alpine`을 베이스로 사용하고 이미지 메타데이터와 `APP_ENV=practice` 환경 변수를 설정한 뒤 `site/`의 정적 파일을 NGINX 웹 루트에 복사합니다. `site/index.html`에는 한국어 작업실 소개 페이지가 들어 있습니다.

사용자가 PowerShell에서 실행한 실제 빌드 결과(2026-11-20):

```powershell
docker build -t workstation-web:1.0 .
```

핵심 출력:

```text
[+] Building 7.9s (8/8) FINISHED
[1/2] FROM docker.io/library/nginx:alpine
[2/2] COPY site/ /usr/share/nginx/html/
naming to docker.io/library/workstation-web:1.0
unpacking to docker.io/library/workstation-web:1.0
```

베이스 이미지 내려받기와 페이지 복사, `workstation-web:1.0` 이미지 생성까지 성공했습니다. 이후 사용자가 PowerShell에서 포트 매핑 컨테이너를 실행한 결과:

```powershell
docker run -d --name workstation-web -p 8080:80 workstation-web:1.0
# e0c2f8dc6d6a982a91898c949562861d00f362957f98b968fec9236843db1516
```

컨테이너 생성 및 백그라운드 실행이 성공했고, 호스트 `8080` 포트를 컨테이너 `80` 포트에 연결했습니다. 이후 사용자가 실행한 `docker ps`에서 `workstation-web`이 `Up 7 minutes`, `0.0.0.0:8080->80/tcp`로 표시됐습니다. `docker logs workstation-web`에서는 NGINX `1.31.9`와 `Configuration complete; ready for start up`을 확인했습니다. `Invoke-WebRequest http://localhost:8080` 결과도 HTTP 200이었고 응답 본문에서 `내 Docker 작업실` 및 페이지 안내 문구를 확인했습니다.

```powershell
docker ps
docker logs workstation-web
Invoke-WebRequest http://localhost:8080 | Select-Object -ExpandProperty Content
docker stats --no-stream
docker stop workstation-web
docker rm workstation-web
```

## 마운트/볼륨 검증

2026-11-21, PowerShell에서 `workstation-bind` 컨테이너를 `8081:80` 포트로 실행하고 호스트의 `D:\E1-1\site` 폴더를 NGINX 웹 루트에 읽기 전용으로 연결했습니다.

```powershell
docker run -d --name workstation-bind -p 8081:80 --mount "type=bind,source=$((Get-Location).Path)\site,target=/usr/share/nginx/html,readonly" nginx:alpine
(Invoke-WebRequest -UseBasicParsing http://localhost:8081).Content
```

이미지가 로컬에 없어 `nginx:alpine`을 내려받은 뒤 컨테이너가 생성됐습니다. 브라우저에서 `http://localhost:8081`을 열어 `내 Docker 작업실` 제목과 페이지 안내 문구가 한글로 정상 표시되는 것을 확인했습니다. 초기 화면 캡처는 [evidence/docker화면.png](evidence/docker화면.png)입니다. 이후 호스트의 `site\index.html`에서 제목을 `<h1>바인드 마운트 변경 확인</h1>`으로 바꾸고 저장한 다음, 브라우저에서 새로고침해 변경된 제목이 표시되는 것을 확인했습니다. 변경 후 화면은 [evidence/바인드 마운트 변경확인.png](evidence/바인드%20마운트%20변경확인.png)입니다. 컨테이너는 `readonly`로 마운트했으므로 컨테이너가 호스트 파일을 수정할 수 없지만, 호스트에서 저장한 변경은 컨테이너 페이지에 반영됩니다. 이미지를 새로 빌드하지 않았는데도 페이지가 바뀐 것은, 컨테이너가 이미지 안의 복사본이 아니라 호스트 폴더 자체를 보고 있기 때문입니다.

검증이 끝난 뒤 `site/index.html`의 제목은 원래 문구(`내 Docker 작업실`)로 되돌려 커밋했습니다. 저장소를 받아 4단계 빌드를 재현하면 원래 페이지가 나오고, 5단계에서 직접 제목을 바꿔 보면 같은 반영을 확인할 수 있습니다. 정리 명령:

```powershell
docker rm -f workstation-bind
```

### named volume 영속성 확인

PowerShell에서 `workstation-data` named volume을 만든 뒤 첫 Ubuntu 컨테이너에 연결했습니다. `/data/check.txt`에 `persistent-data`를 저장하고 읽어 확인한 다음 첫 컨테이너를 삭제했습니다. 같은 볼륨을 두 번째 컨테이너에 연결해 파일을 읽었을 때도 `persistent-data`가 출력되어, 컨테이너를 삭제해도 볼륨 데이터가 유지됨을 확인했습니다.

```powershell
docker volume create workstation-data
docker run -d --name volume-test -v workstation-data:/data ubuntu sleep infinity
docker exec volume-test bash -lc "echo persistent-data > /data/check.txt; cat /data/check.txt"
# persistent-data
docker rm -f volume-test
docker run -d --name volume-test-2 -v workstation-data:/data ubuntu sleep infinity
docker exec volume-test-2 cat /data/check.txt
# persistent-data
```

실습 확인 후 남은 테스트 컨테이너와 볼륨을 정리하려면 아래 명령을 실행합니다. 볼륨 삭제는 그 안의 테스트 파일도 제거합니다.

```powershell
docker rm -f volume-test-2
docker volume rm workstation-data
```

## Linux 파일/디렉터리 권한 실습

2026-11-22, Ubuntu 컨테이너 안의 `/tmp/permission-practice`에서 파일 `sample.txt`와 디렉터리 `permission-dir`을 만들고 권한을 확인했습니다. 생성 직후 파일 권한은 `rw-r--r--`(644), 디렉터리는 `rwxr-xr-x`(755)였습니다. 이어서 `chmod 600` 및 `chmod 700`으로 제한한 결과 파일은 `rw-------`, 디렉터리는 `rwx------`이 됐습니다. 마지막으로 과제 예시 권한인 644와 755로 설정해 아래 최종 결과를 확인했습니다.

```bash
printf 'permission practice\n' > sample.txt
mkdir permission-dir
ls -l sample.txt
# -rw-r--r-- 1 root root 20 ... sample.txt
ls -ld permission-dir
# drwxr-xr-x 2 root root 4096 ... permission-dir

chmod 600 sample.txt
chmod 700 permission-dir
ls -l sample.txt
# -rw------- 1 root root 20 ... sample.txt
ls -ld permission-dir
# drwx------ 2 root root 4096 ... permission-dir

chmod 644 sample.txt
chmod 755 permission-dir
ls -l sample.txt
# -rw-r--r-- 1 root root 20 ... sample.txt
ls -ld permission-dir
# drwxr-xr-x 2 root root 4096 ... permission-dir
```

권한 표기는 소유자/그룹/그 외 사용자 순서로 세 글자씩 읽습니다. `r=4`(읽기), `w=2`(쓰기), `x=1`(파일 실행 또는 디렉터리 접근), `-=0`(권한 없음)이므로 `rwx=7`, `rw-=6`, `r-x=5`, `r--=4`입니다. 따라서 `rw-r--r--`는 `644`, `rwxr-xr-x`는 `755`입니다. 이 연습 파일은 임시 Ubuntu 컨테이너 안에서 만들어졌으며 `docker run --rm` 종료 시 컨테이너와 함께 정리됩니다.

## 증거

브라우저 캡처: [evidence/docker화면.png](evidence/docker화면.png)에는 초기 페이지가, [evidence/바인드 마운트 변경확인.png](evidence/바인드%20마운트%20변경확인.png)에는 호스트 파일 수정 후 반영된 제목이 `localhost:8081` 주소와 함께 보입니다. 빌드, 컨테이너 상태 및 HTTP 응답 결과도 수행 로그에 기록했습니다.

## 트러블슈팅

### 문제 1: 홈 경로에 과제 폴더 생성 실패

- 현상: `New-Item`으로 `$HOME\developer-workstation-lab` 생성 시 접근 거부.
- 확인: 오류에 `Access to the path ... is denied`가 표시됨.
- 해결/대안: 쓰기 권한이 있는 과제 작업공간에서 `practice` 폴더를 만들고 실습을 계속함.
- 재확인: `notes.txt` 내용 확인, 복사/이름 변경/삭제 후 마지막 목록에 `notes.txt`, `empty.txt`가 남음.

### 문제 2: Docker 엔진 연결 실패

- 현상: `docker info`의 Client 정보는 나오지만 Server에 연결할 수 없음.
- 원인 가설: Docker 엔진/데몬이 실행 중이지 않거나 현재 세션에서 사용할 수 없음.
- 확인: `//./pipe/docker_engine` 파이프를 찾을 수 없다는 오류를 확인함.
- 해결: Docker 엔진이 시작된 뒤 `docker info`를 다시 확인.
- 다시 확인한 결과: 사용자 작업 환경에서는 이후 `hello-world`, Ubuntu 컨테이너 및 커스텀 이미지 빌드가 성공. 현재 자동화 세션에서는 Docker API 파이프 접근이 거부되어 `docker info`를 재확인할 수 없었습니다.

### 문제 3: Ubuntu 컨테이너에서 `ls/` 명령 실패

- 현상: `ls/` 실행 시 `bash: ls/: No such file or directory` 출력.
- 원인: 명령어 `ls`와 경로 `/` 사이 공백이 빠짐.
- 해결: `ls /`로 다시 실행.
- 다시 확인한 결과: 루트 디렉터리 목록이 출력되고, `echo`와 `exit`도 정상 동작. 이후 `docker logs ubuntu-practice`에서 오류와 수정 후 출력 모두 확인.

### 문제 4: PowerShell에서 응답 속성 명령이 끊김

- 현상: `Select-Object -ExpandProperty` 뒤에 인수가 없다는 오류가 발생하고, 다음 줄의 `Content`가 별도 명령으로 처리됨.
- 원인: 파이프 명령이 줄바꿈되어 `Content`가 `-ExpandProperty`의 값으로 전달되지 않음.
- 해결: `Invoke-WebRequest http://localhost:8080 | Select-Object -ExpandProperty Content`를 한 줄로 실행.
- 다시 확인한 결과: HTTP 200과 커스텀 페이지 HTML을 확인.

### 문제 5: 드라이브 이동 후 Git 명령 거부(`dubious ownership`)

- 현상: 작업 폴더를 `D:\E1-1`에서 `E:\E1-1`로 옮긴 뒤 `git status` 실행 시 `fatal: detected dubious ownership in repository at 'E:/E1-1'` 출력.
- 원인: 폴더 소유자가 현재 로그인 사용자와 다른 Windows 계정으로 기록되어 있어, Git이 보안상(다른 사용자가 만든 저장소의 설정/훅 실행 방지) 저장소 사용을 막음.
- 확인: 오류 메시지에 폴더 소유자 SID와 현재 사용자 SID가 서로 다르게 표시됨.
- 해결: 내 저장소임을 확인한 뒤 이 경로만 신뢰 목록에 추가.

  ```powershell
  git config --global --add safe.directory E:/E1-1
  ```

- 다시 확인한 결과: `git status`, `git log`가 정상 동작하고 브랜치 `main`, 기존 커밋 `docs: record developer workstation assignment`를 확인.

## Git과 GitHub

### Git 설정

```powershell
git config --global user.name "geena"
git config --global user.email "<제출용 이메일>"
git config --global init.defaultBranch main
git config --list --global
```

`git config --list --global` 핵심 출력(이메일은 공개하지 않기 위해 가림):

```text
user.name=geena
user.email=***
init.defaultbranch=main
```

- `user.name`, `user.email`은 커밋 작성자 정보로 기록됩니다.
- `init.defaultBranch main`은 새 저장소의 기본 브랜치 이름을 `main`으로 맞춥니다. Git 설치본의 시스템 설정은 `master`였지만 전역 설정이 우선 적용됩니다.

### 로컬 저장소와 커밋

```powershell
git init
git status
git add README.md Dockerfile site/ practice/ evidence/
git commit -m "Complete developer workstation assignment"
git log --oneline
```

첫 커밋 `docs: record developer workstation assignment`(2026-11-20) 이후 Git/GitHub 정리와 증거 이동을 두 번째 커밋으로 추가했습니다. `git status`로 커밋 전 변경(`modified`)과 추적되지 않는 파일(`untracked`)을 구분해 확인한 뒤 필요한 파일만 `add`했습니다.

### GitHub 원격 저장소 연결

2026-11-25, GitHub에서 빈 저장소 `E1-1`을 만든 뒤 연결하고 push했습니다.

```powershell
git remote add origin https://github.com/solarjina-geena/E1-1.git
git remote -v
# origin  https://github.com/solarjina-geena/E1-1.git (fetch)
# origin  https://github.com/solarjina-geena/E1-1.git (push)
git push -u origin main
# To https://github.com/solarjina-geena/E1-1.git
#  * [new branch]      main -> main
# branch 'main' set up to track 'origin/main'.
```

- `git remote add origin`은 원격 저장소 주소에 `origin`이라는 이름을 붙입니다.
- `git push -u origin main`은 로컬 `main` 커밋을 GitHub로 올리고, 이후 `git push`/`git pull`의 기본 대상을 `origin/main`으로 지정합니다.
- 인증은 Git Credential Manager의 브라우저 로그인으로 진행하며, 토큰/비밀번호/인증 코드는 README와 캡처에 넣지 않습니다.
- VS Code에서 GitHub 계정으로 로그인하고 이 폴더를 열면 소스 제어 패널에 브랜치 `main`과 원격 `origin`이 표시됩니다.

## 최종 상태 점검

제출 전 아래 명령으로 남은 리소스와 저장소 상태를 확인합니다.

```powershell
docker ps -a        # 실습 컨테이너(workstation-web, workstation-bind, volume-test*)가 정리됐는지
docker images       # hello-world, ubuntu, nginx:alpine, workstation-web:1.0
docker volume ls    # workstation-data (확인 후 docker volume rm으로 정리 가능)
git status          # working tree clean
```

## 배운 점

- **경로**: 절대 경로는 위치가 고정되어 어디서 실행해도 같은 대상을 가리키고, 상대 경로는 현재 위치에 따라 달라집니다. 폴더를 다른 드라이브로 옮겨도 상대 경로로 쓴 명령과 Dockerfile은 그대로 동작했습니다.
- **권한**: 권한은 소유자/그룹/기타 사용자 × `r/w/x`로 구성됩니다. `644`는 소유자만 쓰기 가능한 일반 파일, `755`는 누구나 들어가서 읽을 수 있지만 소유자만 수정하는 디렉터리에 적합합니다. 디렉터리의 `x`는 실행이 아니라 진입/탐색 권한입니다. Windows NTFS는 다른 권한 모델(ACL)을 쓰므로 Linux 권한 실습은 Ubuntu 컨테이너에서 진행했습니다.
- **이미지와 컨테이너**: 이미지는 읽기 전용 설계도(파일 시스템 + 설정)이고, 컨테이너는 그 이미지로 만든 실행 중인 프로세스 인스턴스입니다. 같은 `ubuntu` 이미지로 여러 컨테이너를 만들 수 있고, 각 컨테이너는 서로·호스트와 격리된 파일 시스템과 프로세스 공간을 가집니다. 주 프로세스(`bash`)가 끝나면 컨테이너도 종료됩니다.
- **포트 매핑**: 컨테이너는 격리된 네트워크를 쓰므로 그대로는 호스트에서 접근할 수 없습니다. `-p 8080:80`으로 호스트 8080 요청을 컨테이너 80번(NGINX)으로 전달해 브라우저에서 접속했습니다.
- **바인드 마운트 vs 볼륨**: 바인드 마운트는 호스트의 특정 폴더를 그대로 연결해 소스 수정이 즉시 반영되므로 개발 중에 편리합니다. named volume은 Docker가 관리하는 저장 공간으로, 컨테이너를 삭제해도 데이터가 유지되어 DB 데이터 같은 영속 데이터에 적합합니다.
- **Git과 GitHub**: Git은 내 컴퓨터에서 변경 이력을 커밋 단위로 관리하는 버전 관리 도구이고, GitHub는 Git 저장소를 원격에 올려 공유·백업·협업(이슈, PR, 리뷰)하는 플랫폼입니다. 로컬에서 커밋한 뒤 push해야 다른 사람이 볼 수 있습니다.

## 2026-11-21 이어서 확인한 내용

이번 작업 세션의 작업 경로는 `D:\E1-1`입니다. 과거 실행 로그에 기록한 사용자 PowerShell의 경로와는 별도로, 현재 세션에서 확인한 경로입니다.

```text
docker --version
Docker version 29.6.2, build dfc4efb

docker info
Client 정보는 출력됐지만 Server 연결은 거부됨:
permission denied while trying to connect to the Docker API at npipe:////./pipe/docker_engine

wsl --list --quiet
배포판 목록 조회가 거부됨: Wsl/EnumerateDistros/Service/E_ACCESSDENIED

git branch --show-current
main

git remote -v
등록된 원격 저장소 없음
```

이 자동화 세션에서는 Docker 엔진 파이프와 WSL 배포판 조회가 거부됐지만, 사용자가 Docker Desktop에 연결된 PowerShell에서 바인드 마운트 컨테이너를 실행했습니다. 호스트 HTML 파일의 제목을 수정한 뒤 브라우저를 새로고침해 변경 반영도 확인했고, named volume 데이터를 두 번째 컨테이너에서 읽어 영속성을 확인했습니다. Ubuntu 컨테이너에서 파일과 디렉터리 권한 변경도 완료했습니다. Git 브랜치는 `main`이며 원격 저장소는 아직 등록되지 않았습니다. GitHub 저장소 URL이 준비되면 `origin`을 등록하고 push합니다.
