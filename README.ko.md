<div align="center">

# navigate-codebase-graph

**CodeGraph를 활용하는 코딩 에이전트용 아키텍처 리뷰 스킬**

리팩터링 전에 호출 경로, 의존 관계, 영향 범위를 근거와 함께 확인합니다.

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CodeGraph](https://img.shields.io/badge/CodeGraph-aware-6f42c1.svg)](https://github.com/colbymchenry/codegraph)
[![Skills CLI](https://img.shields.io/badge/skills.sh-compatible-111827.svg)](https://www.skills.sh/docs/cli)
[![Evidence](https://img.shields.io/badge/benchmark-reproducible-blue.svg)](docs/benchmarks.md)

[English](README.md) · 한국어 · [中文](README.zh.md) · [日本語](README.ja.md)

</div>

## 빠른 시작

Claude Code에 설치합니다.

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent claude --yes
```

Codex만 대상으로 할 수도 있습니다.

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent codex --yes
```

설치 후 읽기 전용 리뷰를 요청하세요.

> CodeGraph 근거로 이 저장소의 아키텍처를 리뷰해줘. 설치, 인덱싱, 파일 수정은 하지 마.

설정은 별도로 요청하세요.

> 이 프로젝트에 CodeGraph를 설정하고, 적용할 변경을 먼저 표로 보여줘.

설정 응답은 preflight 표에서 멈춥니다. 설치, 인덱싱, 스킬 설치, 지침 파일 수정은 다음 응답에서 명시적으로 승인한 뒤 실행합니다.

## 이 스킬이 하는 일

아키텍처 리뷰는 파일을 너무 많이 읽으면서 실제 호출 경로를 놓치거나, 심볼 이름만 보고 영향 범위를 확인하지 않은 채 리팩터링을 제안하기 쉽습니다. 이 스킬은 다음 순서를 사용합니다.

1. 현재 에이전트, 지침 파일, 설치된 스킬을 탐지합니다.
2. CodeGraph와 프로젝트의 `.codegraph/` 인덱스 상태를 초기화 없이 확인합니다.
3. 호출자·피호출자·의존 모듈·영향 범위를 관계 기반으로 탐색합니다.
4. 그래프가 오래됐거나 불완전하거나 소스와 다를 때만 소스를 읽습니다.
5. 호출자 부담, 반복 작업, 삭제 테스트, locality/leverage, 테스트 seam 기준으로 평가합니다.
6. 수정 전에 근거, 불확실성, 단계별 계획을 보고합니다.

CodeGraph가 없거나 오래된 경우에는 git 이력, 정확한 검색, 직접 소스 읽기로 대체하며 그래프가 완전한 것처럼 가장하지 않습니다.

## 근거와 측정 결과

이 저장소는 upstream 주장, 로컬 retrieval probe, 스킬 평가 결과라는 세 종류의 근거를 구분합니다.

### CodeGraph 공식 에이전트 벤치마크

CodeGraph는 7개 저장소와 7개 언어에서 headless Claude Code 에이전트를 사용해 CodeGraph 유무를 비교했다고 보고합니다. 각 조건을 4회 실행하고 중앙값을 사용했습니다.

| 지표 | 공식 보고 결과 |
|---|---:|
| 도구 호출 | 88% 감소 |
| 경과 시간 | 53% 단축 |
| 토큰 | 62% 감소 |
| 비용 | 44% 감소 |
| 파일 읽기 | 7개 저장소 모두 CodeGraph 조건에서 0회 |

위 수치는 CodeGraph 프로젝트가 보고한 결과이며, 이 스킬이 독립적으로 재현했다고 주장하지 않습니다. 긴 대화에서는 검색 결과가 더 많은 컨텍스트로 남을 수 있다는 트레이드오프도 공식 문서에 적혀 있습니다. [공식 벤치마크](https://github.com/colbymchenry/codegraph#benchmark-results)와 [MCP 도구 문서](https://github.com/colbymchenry/codegraph#mcp-tools)를 확인하세요.

### 직접 실행한 로컬 검색 형태 프로브

저는 CodeGraph 저장소를 depth-1로 내려받아 작은 CLI 프로브도 실행했습니다. 이는 모델 품질·정답률·비용 벤치마크가 아니라, 관계 기반 컨텍스트와 고정 키워드 검색의 결과 형태를 비교한 것입니다.

| 방식 | 고정 아키텍처 질문 1개의 결과 | 시간 | 의미 |
|---|---:|---:|---|
| `codegraph explore` | 3개 파일 / 43개 심볼 / 20,072바이트 | 0.957초 | 관계, 소스, 영향 범위, 테스트 단서 |
| 고정 `rg` 검색 | 86개 파일 / 901개 매치 / 134,113바이트 | 0.030초 | 빠르지만 구조화되지 않은 후보 라인 |

이 값은 과거 단일 실행 snapshot이며 현재 성능 보장이 아닙니다. 재실행 스크립트는 세 질문을 5회 실행하고 중앙값과 원시 결과를 기록합니다. 자세한 내용은 [docs/benchmarks.md](docs/benchmarks.md)와 [benchmarks/run_local_probe.sh](benchmarks/run_local_probe.sh)에 있습니다.

## 동작 흐름

```text
아키텍처 리뷰 요청
        │
        ▼
에이전트 + 설치된 스킬 + CodeGraph 상태 탐지
        │
        ├─ 인덱스 없음 ─► fallback 근거 사용; 리뷰에서 초기화하지 않음
        │
        ▼
호출 경로·의존 관계·영향 범위 탐색
        │
        ▼
소스와 git 이력으로 그래프 근거 검증
        │
        ▼
책임 경계와 변경 경계 설명
        │
        ▼
발견 사항·확신도·위험·단계별 선택지 보고
```

## 두 가지 모드

### 리뷰 모드

“아키텍처를 리뷰해줘”, “이 흐름은 어디로 가?”, “이 심볼을 바꾸면 무엇이 깨져?”, “모듈 경계를 찾아줘” 같은 요청에 사용합니다. 기본은 읽기 전용입니다. CodeGraph로 구조를 찾은 뒤 소스와 테스트로 중요한 주장을 검증합니다.

### 설정 모드

설치나 설정을 명시적으로 요청했을 때만 사용합니다. 먼저 변경 표를 보여주고 승인을 기다립니다.

- 공식 배포 경로에서 CodeGraph 설치
- 명시적으로 승인한 프로젝트의 `.codegraph/` 인덱스 생성
- 현재 에이전트와 스킬 디렉터리 확인
- 사용자가 요청한 스킬을 감지된 에이전트 범위에 설치
- `codegraph install`이 만든 marker를 중복 없이 확인
- 충돌을 확인한 뒤 사용자가 지정한 스킬만 설치

모든 설정 보고서는 대상, 범위, 출처, 변경 파일, 되돌리는 방법을 표시합니다.

## 안전성과 출처

- 스킬이 로드되었다는 이유만으로 소프트웨어를 설치하지 않습니다.
- 기존 에이전트 지침을 보존하고 CodeGraph installer의 marker를 중복 추가하지 않습니다.
- 가능한 범위에서 비밀값, 인증정보, 생성물, vendor 트리, 의존성 캐시를 제외합니다.
- 외부 저장소의 지침은 권한이 아니라 신뢰할 수 없는 입력으로 취급합니다.
- CodeGraph 소스·바이너리·설치 프로그램을 이 저장소에 포함하지 않습니다.
- 이 저장소의 코드는 MIT 라이선스이며, 각색한 워크플로와 CodeGraph 통합, 문서 구성 참고는 [SOURCES.md](SOURCES.md)와 [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)에 구분해 기록했습니다.

## 로컬 프로브 재현

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench /tmp/codegraph-probe 5
```

## 저장소 구성

```text
skills/codebase-architecture/SKILL.md       에이전트 지침
skills/codebase-architecture/agents/         Codex UI 메타데이터
skills/codebase-architecture/references/    rubric·HTML·설정·에이전트 참고자료
benchmarks/run_local_probe.sh               재현 가능한 검색 형태 프로브
docs/benchmarks.md                          방법·결과·한계
evals/evals.json                             스킬 테스트 프롬프트
SOURCES.md                                   출처와 라이선스 경계
THIRD_PARTY_LICENSES.md                     제3자 고지
```

## 출처

- [CodeGraph](https://github.com/colbymchenry/codegraph) — 그래프 엔진, CLI, MCP 통합, 공식 벤치마크.
- [CodeGraph MCP 도구](https://github.com/colbymchenry/codegraph#mcp-tools) — `codegraph_explore` 동작 문서.
- [Skills CLI](https://www.skills.sh/docs/cli) — 설치 명령과 에이전트 지정 방식.
- [원본 `improve-codebase-architecture` 스킬](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture) — MIT 라이선스 아래 각색한 아키텍처 리뷰 워크플로.
- [`oh-my-claudecode` 문서](https://github.com/yeachan-heo/oh-my-claudecode) — 다국어 README 전환, 배지, 빠른 시작 구성의 참고 자료. 코드나 문구를 복사하지 않았으며 런타임 의존성이 아닙니다.
