# 개발자 작업실 구축

## 프로젝트 개요

터미널, 파일 권한, Docker, Git/GitHub를 직접 사용해 **다른 사람도 이 README를 따라 재현할 수 있는 개발 환경**을 만들고, 실행한 명령과 실제 결과를 기록한 보고서입니다.

- 목표: 경로/권한, 이미지와 컨테이너, 포트 매핑, 바인드 마운트와 볼륨, Git과 GitHub의 역할을 직접 실행해 보고 설명하기
- 선택한 환경: Windows 11 + PowerShell + Docker Desktop. Linux 권한 실습은 Ubuntu 컨테이너 안의 bash에서 진행
- 제출 저장소: <https://github.com/solarjina-geena/E1-1>

### 저장소 구조

```text
E1-1/
├── README.md          # 보고서(수행 로그, 검증, 트러블슈팅, 배운 점)
├── Dockerfile         # nginx:alpine 기반 커스텀 웹 이미지
├── site/
│   └── index.html     # 컨테이너가 제공하는 정적 페이지
├── practice/          # 터미널 조작 실습 결과 파일 (notes.txt, empty.txt)
└── evidence/          # 증거 캡처
    ├── docker화면.png
    ├── 바인드 마운트 변경확인.png
    └── vscode-github.png
```

## 실행 환경

| 항목 | 내용 |
| --- | --- |
| OS | Windows 11 Home (10.0.26200) |
| 터미널/쉘 | PowerShell 7, VS Code 통합 터미널 / Linux 명령은 Ubuntu 컨테이너의 bash |
| Docker 실행 환경 | Docker Desktop (Linux 엔진, `linux/x86_64`) |
| Docker | Client `29.6.2` / Server `29.6.2` |
| Git | `git version 2.56.0.windows.4` |
| 작업 폴더 | 처음 `D:\E1-1`에서 실습, 이후 `E:\E1-1`로 옮겨 마무리 (내용 동일) |
| 수행 기간 | 2026-11-20 ~ 2026-11-25 |

## 수행 체크리스트

- [x] 터미널 기본 조작(생성, 복사, 이름 변경, 삭제)과 절대/상대 경로
- [x] 파일 1개, 디렉터리 1개의 권한 변경 전/후 기록
- [x] Docker 설치 및 엔진 점검(`docker --version`, `docker info`)
- [x] `hello-world` 컨테이너 실행
- [x] Ubuntu 컨테이너 실행과 관찰(`ps`, `ps -a`, `logs`, `rm`)
- [x] 직접 작성한 Dockerfile로 커스텀 이미지 빌드·실행
- [x] 포트 매핑 후 브라우저/HTTP 접속 확인
- [x] 바인드 마운트 변경 반영
- [x] named volume 컨테이너 삭제 전/후 데이터 유지
- [x] Git 설정, 로컬 커밋, GitHub 원격 연결 및 push
- [x] VS Code GitHub 연동 확인
- [x] 트러블슈팅 2건 이상 (5건)
- [x] 민감정보 확인 (이메일 가림, 토큰/비밀번호 미포함)
- [x] 실습 리소스 정리

## 수행 로그 및 검증

### 1. 터미널 기본 조작

가이드의 홈 디렉터리 경로(`$HOME\developer-workstation-lab`) 생성은 접근 거부로 실패해서(트러블슈팅 1), 과제 작업 폴더 아래에 `practice` 폴더를 만들어 같은 조작을 수행했습니다.

```powershell
Get-Location
# D:\ALL IN ONE\E1-1        (실습 당시 위치)

New-Item -ItemType Directory -Name "practice"
Set-Content -Path ".\practice\notes.txt" -Value "첫 번째 터미널 실습"
Get-Content ".\practice\notes.txt"
# 첫 번째 터미널 실습

Copy-Item ".\practice\notes.txt" ".\practice\notes-copy.txt"
Rename-Item ".\practice\notes-copy.txt" "renamed.txt"
New-Item -ItemType File -Path ".\practice\empty.txt"
Get-ChildItem ".\practice"
# empty.txt, notes.txt, renamed.txt
Remove-Item ".\practice\renamed.txt"
Get-ChildItem ".\practice"
# empty.txt, notes.txt
```

| 명령 | 의미 |
| --- | --- |
| `Get-Location` | 현재 작업 경로 확인 (bash의 `pwd`) |
| `New-Item` | 폴더/빈 파일 생성 (`mkdir`, `touch`) |
| `Set-Content` / `Get-Content` | 파일 쓰기/읽기 (`printf > 파일`, `cat`) |
| `Copy-Item` / `Rename-Item` | 복사 / 이름 변경 (`cp`, `mv`) |
| `Get-ChildItem` | 목록 확인 (`ls -la`) |
| `Remove-Item` | 삭제 (`rm`) |

마지막 목록에 `notes.txt`와 `empty.txt`만 남아, 이름을 바꾼 복사본만 삭제된 것을 확인했습니다. 결과 파일은 [practice/](practice/) 폴더에 있습니다.

### 2. 절대 경로와 상대 경로

- **절대 경로**는 드라이브(Linux는 루트 `/`)부터 시작하는 전체 위치입니다. 예: `E:\E1-1\practice\notes.txt`, 컨테이너 안의 `/usr/share/nginx/html`.
- **상대 경로**는 현재 위치를 기준으로 한 위치입니다. 현재 위치가 `E:\E1-1`이면 `.\practice\notes.txt`는 `E:\E1-1\practice\notes.txt`를 가리킵니다. `.`은 현재 폴더, `..`은 상위 폴더입니다.
- 작업 폴더를 `D:`에서 `E:`로 옮겼지만, 명령과 Dockerfile이 상대 경로(`.\practice`, `COPY site/ ...`)를 써서 그대로 재사용할 수 있었습니다. 반면 바인드 마운트의 `source`는 Docker가 절대 경로를 요구하므로 `$((Get-Location).Path)\site`로 현재 위치에서 절대 경로를 만들어 전달했습니다.

### 3. 파일/디렉터리 권한 변경

Windows NTFS는 Linux식 `rwx` 권한이 아니라 ACL을 쓰므로, 2026-11-22 Ubuntu 컨테이너 안의 `/tmp/permission-practice`에서 실습했습니다. 파일 `sample.txt`와 디렉터리 `permission-dir`을 만든 뒤 권한을 바꿔 가며 확인했습니다.

```bash
printf 'permission practice\n' > sample.txt
mkdir permission-dir

# 생성 직후(변경 전)
ls -l sample.txt
# -rw-r--r-- 1 root root 20 ... sample.txt         → 644
ls -ld permission-dir
# drwxr-xr-x 2 root root 4096 ... permission-dir   → 755

# 변경 1: 소유자 전용으로 제한
chmod 600 sample.txt
chmod 700 permission-dir
ls -l sample.txt
# -rw------- 1 root root 20 ... sample.txt         → 600
ls -ld permission-dir
# drwx------ 2 root root 4096 ... permission-dir   → 700

# 변경 2: 과제 기준 권한으로 설정
chmod 644 sample.txt
chmod 755 permission-dir
ls -l sample.txt
# -rw-r--r-- 1 root root 20 ... sample.txt         → 644
ls -ld permission-dir
# drwxr-xr-x 2 root root 4096 ... permission-dir   → 755
```

권한은 **소유자 / 그룹 / 그 외 사용자** 순서로 세 글자씩 읽습니다. `r=4`(읽기), `w=2`(쓰기), `x=1`(실행, 디렉터리는 진입/탐색), `-=0`이므로 `rw-`=6, `r-x`=5, `r--`=4, `rwx`=7입니다.

- `644` = `rw-r--r--`: 소유자만 수정, 나머지는 읽기만 가능 (일반 파일)
- `755` = `rwxr-xr-x`: 소유자만 수정, 나머지는 들어가서 목록을 볼 수 있음 (공개 디렉터리)
- `600`/`700`: 소유자 외에는 아무 권한 없음 (비밀 파일, 개인 폴더)

### 4. Docker 설치 및 엔진 점검

```powershell
docker --version
# Docker version 29.6.2, build dfc4efb

docker info
# Client: Version 29.6.2
# Server Version: 29.6.2
# Operating System: Docker Desktop
# OSType/Architecture: linux/x86_64

git --version
# git version 2.56.0.windows.4
```

`docker --version`은 CLI(클라이언트) 버전만 확인합니다. `docker info`는 클라이언트가 엔진(Server)에 실제로 연결되는지까지 확인하므로, 설치 완료 여부는 `docker info`에 Server 정보가 나오는지로 판단했습니다. 처음에는 엔진이 꺼져 있어 Server 연결에 실패했고, Docker Desktop을 실행한 뒤 정상 연결됐습니다(트러블슈팅 2).

### 5. `hello-world` 컨테이너

```powershell
docker run --rm hello-world
```

```text
Unable to find image 'hello-world:latest' locally
...
Hello from Docker!
The Docker client contacted the Docker daemon.
The Docker daemon pulled the "hello-world" image from the Docker Hub.
The Docker daemon created a new container from that image.
```

- `docker run`은 이미지가 로컬에 없으면 Docker Hub에서 내려받고, 새 컨테이너를 만들어 실행합니다.
- `--rm`은 컨테이너가 끝나면 자동으로 삭제합니다. 컨테이너는 남지 않지만 이미지는 로컬에 남습니다.
- `Hello from Docker!` 출력으로 데몬 연결, 이미지 다운로드, 컨테이너 실행이 모두 성공한 것을 확인했습니다.

### 6. Ubuntu 컨테이너 실행과 관찰

```powershell
docker run -it --name ubuntu-practice ubuntu bash
```

컨테이너 안(프롬프트가 `root@9e73323536c7:/#`로 바뀜):

```bash
ls /
# bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var
echo "hello from container"
# hello from container
exit
```

- `-it`: 대화형 터미널을 연결해 컨테이너 안에서 직접 명령을 입력합니다.
- `--name ubuntu-practice`: 이후 명령에서 쓸 이름을 붙입니다.
- `bash`: 컨테이너의 주 프로세스입니다. `exit`로 bash를 끝내면 주 프로세스가 끝나므로 컨테이너도 종료됩니다.
- `ls /`에 Windows와 다른 Ubuntu 파일 시스템이 보여, 컨테이너가 호스트와 격리된 자체 파일 시스템을 가진다는 것을 확인했습니다.

종료 후 호스트에서:

```powershell
docker ps
# n8n 만 Up 상태로 표시 (ubuntu-practice는 종료되어 보이지 않음)

docker ps -a
# 9e73323536c7   ubuntu   "bash"   3 minutes ago   Exited (0) 2 minutes ago   ubuntu-practice
# 447c7c37cb05   docker.n8n.io/n8nio/n8n   ...   Up 16 minutes   ...   n8n

docker logs ubuntu-practice
# bash: ls/: No such file or directory
# bin boot dev etc ...
# hello from container
# exit

docker rm ubuntu-practice
# ubuntu-practice
```

- `docker ps`는 실행 중인 컨테이너만, `docker ps -a`는 종료된 컨테이너까지 보여줍니다. `ubuntu-practice`는 `Exited (0)`으로 정상 종료됐습니다.
- `docker logs`는 컨테이너 주 프로세스가 출력한 내용을 보여줍니다. 오타(`ls/`)로 난 오류와 고친 뒤의 출력이 모두 남아 있었습니다(트러블슈팅 3).
- `docker rm`은 종료된 컨테이너를 삭제합니다. 이미지는 그대로 남습니다.
- `n8n`은 과제와 무관하게 원래 쓰던 컨테이너라 건드리지 않았습니다.
- `docker exec`는 이미 **실행 중인** 컨테이너 안에서 추가 명령을 실행할 때 씁니다(아래 볼륨 실습에서 사용). 컨테이너를 계속 실행 상태로 두려면 `sleep infinity`나 웹 서버처럼 끝나지 않는 주 프로세스가 필요합니다.

## Dockerfile과 커스텀 내용

### Dockerfile

```dockerfile
FROM nginx:alpine
LABEL org.opencontainers.image.title="developer-workstation-web"
ENV APP_ENV=practice
COPY site/ /usr/share/nginx/html/
```

| 지시어 | 내용과 목적 |
| --- | --- |
| `FROM nginx:alpine` | 가벼운 Alpine Linux 기반 NGINX 웹 서버를 베이스 이미지로 사용 |
| `LABEL` | 이미지 이름 메타데이터 추가 (`docker inspect`로 확인 가능) |
| `ENV APP_ENV=practice` | 컨테이너 안에서 쓸 환경 변수 설정 |
| `COPY site/ ...` | 직접 만든 페이지 [site/index.html](site/index.html)을 NGINX 웹 루트에 복사 |

### 빌드

```powershell
docker build -t workstation-web:1.0 .
```

```text
[+] Building 7.9s (8/8) FINISHED
[1/2] FROM docker.io/library/nginx:alpine
[2/2] COPY site/ /usr/share/nginx/html/
naming to docker.io/library/workstation-web:1.0
```

마지막 `.`은 빌드 컨텍스트(현재 폴더)입니다. Docker는 이 폴더 기준으로 `site/`를 찾아 이미지에 넣습니다.

### 실행과 포트 매핑

```powershell
docker run -d --name workstation-web -p 8080:80 workstation-web:1.0
# e0c2f8dc6d6a982a91898c949562861d00f362957f98b968fec9236843db1516

docker ps
# workstation-web   Up 7 minutes   0.0.0.0:8080->80/tcp

docker logs workstation-web
# ... nginx/1.31.9
# ... Configuration complete; ready for start up

Invoke-WebRequest http://localhost:8080 | Select-Object -ExpandProperty Content
# StatusCode 200, 본문에 "<h1>내 Docker 작업실</h1>" 확인

docker stats --no-stream
docker stop workstation-web
docker rm workstation-web
```

- `-d`: 백그라운드로 실행하고 컨테이너 ID를 출력합니다.
- `-p 8080:80`: **호스트 8080 → 컨테이너 80**. 컨테이너는 격리된 네트워크를 쓰므로, 포트를 연결해야 내 컴퓨터의 브라우저에서 컨테이너 안 NGINX(80번)에 접속할 수 있습니다.
- `docker ps`의 `0.0.0.0:8080->80/tcp`와 HTTP 200 응답으로 포트 매핑을 확인했습니다.

## 마운트/볼륨 검증

### 바인드 마운트: 호스트 파일 수정이 바로 반영되는지

2026-11-21, 호스트의 `site` 폴더를 NGINX 웹 루트에 **읽기 전용**으로 연결해 `8081` 포트로 실행했습니다.

```powershell
docker run -d --name workstation-bind -p 8081:80 --mount "type=bind,source=$((Get-Location).Path)\site,target=/usr/share/nginx/html,readonly" nginx:alpine
(Invoke-WebRequest -UseBasicParsing http://localhost:8081).Content
```

| 시점 | `site/index.html`의 제목 | 브라우저 `localhost:8081` 결과 | 증거 |
| --- | --- | --- | --- |
| 변경 전 | `<h1>내 Docker 작업실</h1>` | "내 Docker 작업실" 표시 | [evidence/docker화면.png](evidence/docker화면.png) |
| 변경 후 | `<h1>바인드 마운트 변경 확인</h1>` | 새로고침만으로 "바인드 마운트 변경 확인" 표시 | [evidence/바인드 마운트 변경확인.png](evidence/바인드%20마운트%20변경확인.png) |

이미지를 다시 빌드하거나 컨테이너를 재시작하지 않았는데 페이지가 바뀌었습니다. 컨테이너가 이미지 안의 복사본이 아니라 **호스트 폴더 자체**를 보고 있기 때문입니다. `readonly`로 연결했으므로 컨테이너는 호스트 파일을 수정할 수 없습니다.

검증 후 `site/index.html`의 제목은 원래 문구로 되돌려 커밋했습니다. 저장소를 받아 그대로 빌드하면 원래 페이지가 나오고, 제목을 직접 바꿔 보면 같은 반영을 확인할 수 있습니다.

```powershell
docker rm -f workstation-bind
```

### named volume: 컨테이너를 지워도 데이터가 남는지

```powershell
docker volume create workstation-data
docker run -d --name volume-test -v workstation-data:/data ubuntu sleep infinity
docker exec volume-test bash -lc "echo persistent-data > /data/check.txt; cat /data/check.txt"
# persistent-data                  ← 첫 번째 컨테이너에서 저장

docker rm -f volume-test           ← 첫 번째 컨테이너 삭제

docker run -d --name volume-test-2 -v workstation-data:/data ubuntu sleep infinity
docker exec volume-test-2 cat /data/check.txt
# persistent-data                  ← 새 컨테이너에서도 그대로 읽힘

docker rm -f volume-test-2
docker volume rm workstation-data
```

첫 번째 컨테이너를 삭제한 뒤 새 컨테이너에 같은 볼륨을 연결했을 때도 `persistent-data`가 출력됐습니다. 데이터가 컨테이너가 아니라 Docker가 관리하는 볼륨에 저장되어, 컨테이너 생명주기와 분리된다는 것을 확인했습니다.

### 바인드 마운트와 볼륨 비교

| 구분 | 바인드 마운트 | named volume |
| --- | --- | --- |
| 저장 위치 | 내가 지정한 호스트 폴더 (`E:\E1-1\site`) | Docker가 관리하는 저장 공간 |
| 지정 방법 | 호스트 절대 경로 | 볼륨 이름 (`workstation-data`) |
| 장점 | 호스트에서 수정하면 즉시 반영 | 컨테이너를 지워도 유지, 경로/OS에 덜 의존 |
| 쓰임새 | 개발 중 소스 코드, 설정 파일 | DB 데이터 등 보존해야 할 데이터 |

## Git과 GitHub

### Git 설정

```powershell
git config --global user.name "geena"
git config --global user.email "<제출용 이메일>"
git config --global init.defaultBranch main
git config --list --global
```

```text
user.name=geena
user.email=***            (공개하지 않기 위해 가림)
init.defaultbranch=main
safe.directory=E:/E1-1    (트러블슈팅 5)
```

- `user.name`, `user.email`은 커밋 작성자로 기록됩니다.
- `init.defaultBranch main`은 새 저장소의 기본 브랜치 이름을 `main`으로 정합니다. Git 설치본의 시스템 설정은 `master`였지만 전역(`--global`) 설정이 우선합니다.

### 로컬 저장소와 커밋

```powershell
git init
git status
git add README.md Dockerfile site/ practice/ evidence/
git commit -m "Complete developer workstation assignment"
git log --oneline
```

`git status`로 수정된 파일(`modified`)과 추적되지 않는 파일(`untracked`)을 구분해 확인한 뒤, 제출에 필요한 파일만 `add`했습니다. 과제 안내 자료(`과제1_..._가이드.md`)는 제출물이 아니라서 커밋하지 않았습니다.

### GitHub 원격 저장소 연결과 push

2026-11-25, GitHub에 빈 저장소 `E1-1`을 만들고 연결했습니다.

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

- `git remote add origin`: 원격 저장소 주소에 `origin`이라는 이름을 붙입니다.
- `git push -u origin main`: 로컬 `main`의 커밋을 GitHub로 올리고, 이후 `git push`/`git pull`의 기본 대상을 `origin/main`으로 정합니다.
- 인증은 Git Credential Manager의 브라우저 로그인으로 했으며, 토큰/비밀번호/인증 코드는 README와 캡처에 넣지 않았습니다.

### VS Code 연동 확인

GitHub 계정으로 로그인한 VS Code에서 `E:\E1-1` 폴더를 열고, 통합 터미널에서 확인했습니다.

```powershell
git config --global --add safe.directory E:/E1-1
git remote -v
# origin  https://github.com/solarjina-geena/E1-1.git (fetch)
# origin  https://github.com/solarjina-geena/E1-1.git (push)
git status
# On branch main
# Your branch is up to date with 'origin/main'.
```

`Your branch is up to date with 'origin/main'`은 로컬 `main`과 GitHub의 `origin/main`이 같은 커밋을 가리킨다는 뜻입니다. 캡처: [evidence/vscode-github.png](evidence/vscode-github.png)

## 증거

| 파일 | 내용 |
| --- | --- |
| [evidence/docker화면.png](evidence/docker화면.png) | `localhost:8081` 주소와 함께 보이는 바인드 마운트 초기 페이지 |
| [evidence/바인드 마운트 변경확인.png](evidence/바인드%20마운트%20변경확인.png) | 호스트에서 `index.html` 수정 후 새로고침만으로 바뀐 제목 |
| [evidence/vscode-github.png](evidence/vscode-github.png) | VS Code 터미널의 `git remote -v`, `git status` (GitHub 연결, 동기화 상태) |
| [practice/](practice/) | 터미널 조작 결과 파일 |

빌드 출력, 컨테이너 상태, HTTP 응답, 볼륨 확인 결과는 위 수행 로그의 코드 블록에 실제 출력으로 기록했습니다.

## 트러블슈팅

### 문제 1: 홈 경로에 과제 폴더 생성 실패

- 현상: `New-Item`으로 `$HOME\developer-workstation-lab`을 만들 때 `Access to the path ... is denied` 발생.
- 원인 가설: 당시 실행한 터미널 세션에 사용자 홈 폴더 쓰기 권한이 없음.
- 확인: 같은 명령을 과제 작업 폴더에서 실행하면 정상 동작함.
- 해결: 쓰기 권한이 있는 과제 작업 폴더 아래에 `practice`를 만들어 실습을 진행.
- 다시 확인한 결과: 복사/이름 변경/삭제 후 마지막 목록에 `notes.txt`, `empty.txt`가 남음.

### 문제 2: Docker 엔진 연결 실패

- 현상: `docker --version`은 나오지만 `docker info`에서 Server 연결 실패.
  `failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine ... The system cannot find the file specified.`
- 원인 가설: CLI는 설치됐지만 엔진(Docker Desktop)이 실행되지 않음.
- 확인: 오류 메시지가 엔진과 통신하는 파이프(`dockerDesktopLinuxEngine`)를 찾을 수 없다고 표시함. 즉 엔진 프로세스가 없음.
- 해결: Docker Desktop을 실행하고 엔진이 준비될 때까지 기다린 뒤 다시 확인.
- 다시 확인한 결과: `docker info`에 `Server Version: 29.6.2`, `Operating System: Docker Desktop`이 표시되고 컨테이너 실습이 정상 동작. **CLI 버전 확인만으로는 설치 완료로 볼 수 없다**는 것을 배웠습니다.

### 문제 3: Ubuntu 컨테이너에서 `ls/` 명령 실패

- 현상: `bash: ls/: No such file or directory`.
- 원인: 명령어 `ls`와 경로 `/` 사이에 공백이 빠져 `ls/`라는 하나의 명령으로 해석됨.
- 해결: `ls /`로 다시 실행.
- 다시 확인한 결과: 루트 디렉터리 목록이 출력됨. `docker logs ubuntu-practice`에도 오류와 수정 후 출력이 모두 남아 있음.

### 문제 4: PowerShell에서 응답 본문 출력 명령이 끊김

- 현상: `Select-Object -ExpandProperty` 뒤에 인수가 없다는 오류가 나고, 다음 줄의 `Content`가 별도 명령으로 실행됨.
- 원인: 파이프 명령을 줄바꿈해서 입력해 `Content`가 `-ExpandProperty`의 값으로 전달되지 않음.
- 해결: `Invoke-WebRequest http://localhost:8080 | Select-Object -ExpandProperty Content`를 한 줄로 실행.
- 다시 확인한 결과: HTTP 200과 커스텀 페이지 HTML이 출력됨.

### 문제 5: 폴더를 다른 드라이브로 옮긴 뒤 Git 명령 거부

- 현상: `E:\E1-1`에서 `git status` 실행 시 `fatal: detected dubious ownership in repository at 'E:/E1-1'`.
- 원인: 폴더 소유자가 현재 로그인 계정과 다른 Windows 계정으로 기록되어 있음. Git은 다른 사용자가 만든 저장소의 설정/훅이 실행되는 것을 막기 위해 사용을 거부함.
- 확인: 오류 메시지에 폴더 소유자와 현재 사용자가 서로 다르게 표시됨.
- 해결: 내 저장소임을 확인한 뒤 이 경로만 신뢰 목록에 추가.
  `git config --global --add safe.directory E:/E1-1`
- 다시 확인한 결과: VS Code 터미널에서 `git remote -v`, `git status`가 정상 동작 ([evidence/vscode-github.png](evidence/vscode-github.png)).

## 최종 상태 점검

2026-11-25, 제출 전에 남은 리소스를 확인하고 실습 컨테이너를 정리했습니다.

```powershell
docker rm workstation-bind workstation-web
# workstation-bind
# workstation-web

docker ps -a
# NAMES   IMAGE                     STATUS
# n8n     docker.n8n.io/n8nio/n8n   Up       (과제와 무관한 기존 컨테이너, 유지)

docker volume ls
# (비어 있음 - workstation-data 정리 완료)

docker images
# workstation-web:1.0   93.6MB
# nginx:alpine          94.5MB
# ubuntu:latest         163MB
# hello-world:latest    25.9kB
# (n8n 이미지 제외)

git status
# On branch main
# Your branch is up to date with 'origin/main'.
```

이미지는 README를 따라 다시 실행할 때 내려받는 시간을 줄이기 위해 남겨 두었습니다. 모두 지우려면 `docker rmi workstation-web:1.0 nginx:alpine hello-world ubuntu`를 실행합니다.

## 배운 점

- **경로**: 절대 경로는 어디서 실행해도 같은 대상을 가리키고, 상대 경로는 현재 위치에 따라 달라집니다. 폴더를 다른 드라이브로 옮겨도 상대 경로로 쓴 명령과 Dockerfile은 그대로 동작했고, 바인드 마운트처럼 절대 경로가 필요한 곳은 현재 위치로 만들어 넘겼습니다.
- **권한**: 권한은 소유자/그룹/기타 × `r/w/x` 조합이고 숫자로는 `r=4, w=2, x=1`의 합입니다. `644`는 일반 파일, `755`는 공개 디렉터리에 알맞습니다. 디렉터리의 `x`는 실행이 아니라 들어가서 탐색할 수 있는 권한입니다.
- **이미지와 컨테이너**: 이미지는 읽기 전용 설계도이고, 컨테이너는 그 이미지로 만든 실행 인스턴스입니다. 같은 `ubuntu` 이미지로 여러 컨테이너를 만들 수 있고, 각 컨테이너는 호스트와 격리된 파일 시스템과 프로세스를 가집니다. 주 프로세스가 끝나면 컨테이너도 종료됩니다.
- **포트 매핑**: 컨테이너는 격리된 네트워크에 있어 그대로는 접속할 수 없습니다. `-p 8080:80`으로 호스트 포트를 컨테이너 포트에 연결해야 브라우저에서 접근할 수 있습니다.
- **바인드 마운트와 볼륨**: 바인드 마운트는 호스트 폴더를 그대로 연결해 수정이 즉시 반영되므로 개발할 때 편리하고, named volume은 Docker가 관리해 컨테이너를 지워도 데이터가 남으므로 보존할 데이터에 알맞습니다.
- **Git과 GitHub**: Git은 내 컴퓨터에서 변경 이력을 커밋으로 관리하는 버전 관리 도구이고, GitHub는 그 저장소를 원격에 올려 공유·백업·협업하는 플랫폼입니다. 커밋은 로컬에만 남으므로 push해야 다른 사람이 볼 수 있습니다.
- **문제 해결 방식**: 오류 메시지를 그대로 읽고 원인 가설 → 확인 → 해결 → 재확인 순서로 접근하니, 엔진 미실행이나 폴더 소유권처럼 처음 보는 문제도 해결할 수 있었습니다.
