# 개발자 작업실 구축

## 프로젝트 개요

터미널, 파일 권한, Docker, Git/GitHub의 기본 흐름을 직접 실행하고 결과를 기록하는 과제입니다. 이 문서는 현재 확인한 실제 결과와 아직 실행하지 못한 단계를 구분합니다.

## 실행 환경

- OS: Windows (PowerShell 환경)
- 작업공간: `D:\E1-1`
- 터미널/쉘: PowerShell
- Docker CLI: `Docker version 29.6.2, build dfc4efb`
- Docker 엔진: 사용자가 Docker Desktop에서 빌드 성공을 확인함. 현재 자동화 세션에서는 Docker API 파이프 접근 거부로 `docker info` 확인 불가
- Git: `git version 2.56.0.windows.4`
- 확인일: 2026-11-20

## 수행 체크리스트

- [x] PowerShell 터미널 기본 파일 조작
- [ ] Linux 파일/디렉토리 권한 전후 비교
- [x] Docker CLI 버전 및 엔진 연결 상태 확인
- [x] `hello-world` 컨테이너
- [x] Ubuntu 컨테이너
- [x] Dockerfile 커스텀 이미지 빌드
- [x] 커스텀 이미지 컨테이너 실행
- [ ] 포트 매핑 접속 확인
- [ ] 바인드 마운트 변경 반영
- [ ] named volume 영속성
- [ ] Git/GitHub/VS Code 연동 및 원격 저장소 제출

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

명령 의미와 결과: `Get-Location`은 현재 작업 경로를 보여줍니다. `New-Item`은 폴더/파일 생성, `Set-Content`와 `Get-Content`는 파일 쓰기/읽기, `Copy-Item`은 복사, `Rename-Item`은 이름 변경, `Get-ChildItem`은 항목 목록 확인, `Remove-Item`은 지정한 항목 삭제에 사용했습니다. 마지막 목록에 `notes.txt`와 `empty.txt`만 남아 이름을 바꿨던 복사본만 삭제된 것을 확인했습니다.

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

컨테이너 생성 및 백그라운드 실행이 성공했고, 호스트 `8080` 포트를 컨테이너 `80` 포트에 연결했습니다. 현재 자동화 세션에서는 `docker info`가 `npipe:////./pipe/docker_engine` 접근 거부로 실패하고 사용자 PowerShell 창도 열려 있지 않아, 실행 상태와 HTTP 응답은 이 기록 시점에 추가로 확인할 수 없었습니다. Docker Desktop이 연결된 PowerShell에서 다음 명령을 실행하고 결과를 추가합니다.

```powershell
docker ps
docker logs workstation-web
Invoke-WebRequest http://localhost:8080 | Select-Object -ExpandProperty Content
docker stats --no-stream
docker stop workstation-web
docker rm workstation-web
```

## 마운트/볼륨 검증
아직 실행하지 않았습니다. 포트 접속 단계를 마친 뒤 바인드 마운트의 변경 전후 응답과 named volume의 컨테이너 삭제 전후 데이터를 확인해 기록합니다.

## 증거

현재 별도 캡처는 없습니다. 빌드 출력은 사용자가 제공한 실제 로그의 핵심 결과를 기록했습니다. 브라우저 주소와 페이지가 함께 보이는 캡처는 포트 접속 실습 후 추가합니다.

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

## 배운 점

현재까지 PowerShell 파일 조작, 기본 이미지로 컨테이너 실행/종료, NGINX 커스텀 이미지 빌드를 실습했습니다. 파일/디렉터리 권한, 커스텀 웹 서버의 포트 응답, 바인드 마운트, 볼륨 영속성, GitHub 제출은 남아 있습니다.
