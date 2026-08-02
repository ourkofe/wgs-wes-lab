# neanderthal_ancient_dna

Svante Pääbo(2022 노벨 생리의학상)의 네안데르탈인 게놈 프로젝트 데이터로,
고대 DNA(ancient DNA) 특화 분석을 실습. germline_variant_calling(GATK
표준 파이프라인)의 자연스러운 다음 단계.

## 배경: 고대 DNA가 일반 variant calling과 다른 점

germline_variant_calling에서는 살아있는 사람(HG002)의 깨끗한 DNA를 다뤘지만,
네안데르탈인 DNA는 수만 년 된 뼈에서 추출한 것이라 몇 가지 특수한 문제가 있음.

### 1. 화학적 손상 (deamination)
오래된 DNA는 자연적으로 화학적 손상을 입는데, 특히 시토신(C)이 우라실(U)로
변하는 deamination이 흔함. 시퀀싱하면 이게 T로 읽혀서, **리드 끝부분에서
C->T, G->A 치환이 인위적으로 몰리는 패턴**이 생김. 이걸 진짜 변이로 착각하면
안 되므로, mapDamage 같은 도구로 이 패턴을 확인해야 함.

### 2. 짧은 조각
오래될수록 DNA가 잘게 부서져서, 일반 시퀀싱보다 훨씬 짧은 조각들만 남음.
정렬 시 이 점을 감안한 파라미터 조정이 필요함.

### 3. 현생인류 오염
발굴, 취급, 실험 과정에서 현생인류 DNA가 섞여 들어갈 위험이 있음. 표준
분석에는 없는 오염도 검사가 고대 DNA 분석에서는 추가로 필요함 (이번 실습
에서는 범위 밖으로 남겨둠).

## 이번 실습 목표

1. 네안데르탈인 데이터를 짧은 조각/손상 패턴에 맞춘 방식으로 정렬
2. 손상 패턴을 mapDamage로 시각화/정량해서 "진짜 고대 DNA스러운" 특징 확인
3. (여유 있으면) 변이 호출 후 현생인류(HG002) 결과와 비교

## 데이터

- 출처: ENA study accession **PRJEB21157** (Prüfer et al. 2017, *Science*,
  "A high-coverage Neandertal genome from Vindija Cave in Croatia")
- 대상: Vindija 33.19 (여성, 약 5만 년 전, 30x 커버리지로 시퀀싱된 고품질 게놈)
- 사용 데이터: merged reads(겹치는 페어를 하나로 합친 형태) run 5개
  (ERR2000715, 716, 718, 720, 722) - 프로젝트 전체 287개 run(992GB) 중
  가장 큰 것들로 선정, 총 42GB
  - 손상 패턴 분석만 목적이면 1개 run으로도 충분하지만, 변이 호출까지
    의미 있게 하려면 커버리지가 필요해서 5개로 확대
- 레퍼런스: germline_variant_calling의 GRCh38_no_alt.fasta 재사용 (복사본,
  아래 참고)

## 워크플로우

1. raw fastq (네안데르탈인, merged reads)
2. QC (FastQC) — 리드 길이 분포 확인
3. 정렬 (BWA aln) — 짧은 고대 DNA 리드에 맞춘 파라미터
4. 손상 패턴 분석 (mapDamage) — deamination 패턴 시각화/정량
5. (선택) 변이 호출 (GATK) 및 HG002와 비교

## 도구

| 단계 | 도구 |
|---|---|
| QC | FastQC |
| 정렬 | BWA aln (`-l 1024 -n 0.01`, 고대 DNA 표준 파라미터) |
| 손상 패턴 분석 | mapDamage2 (`quay.io/biocontainers/mapdamage2:2.2.3--py312h4711d71_0`) |
| 변이 호출 (예정) | GATK (germline_variant_calling과 동일) |

### 참고: BWA-MEM 대신 BWA aln을 쓴 이유

QC에서 확인한 실제 리드 길이 분포(아래)를 보고 결정함. 리드가 짧고
다양해서, seed 기반인 BWA-MEM보다 짧은 리드에 강한 BWA aln + 관대한
파라미터가 더 적합하다고 판단.

## 레퍼런스 재사용 관련 참고

처음엔 germline_variant_calling의 레퍼런스를 심볼릭 링크로 재사용하려 했으나,
도커 볼륨 마운트 범위(`neanderthal_ancient_dna` 폴더까지만) 밖의 파일을
가리키는 링크라 컨테이너 안에서 인식이 안 됨. 실제 파일을 복사하는 방식으로
해결 (`ref/` 안에 fasta 관련 파일들 직접 복사, 약 6.5GB 중복 사용).

## 폴더 구조
neanderthal_ancient_dna/
├── README.md
├── ANALYSIS_LOG.md
├── docs/
├── config/
├── scripts/
├── data/ (원본 fastq, git 제외)
├── ref/ (레퍼런스 복사본, git 제외)
├── results/
│ ├── qc/fastqc/
│ ├── align/
│ └── mapdamage/
└── logs/

## 진행 상황

- [x] 배경 조사 및 설계
- [x] 데이터 다운로드 (5개 run, 42GB)
- [x] QC — 리드 길이 1-141bp, 최빈값 40-49bp 확인 (고대 DNA 특유 패턴)
- [x] 정렬 (BWA aln)
- [x] 손상 패턴 분석 (mapDamage) — 5개 run 모두 재현되는 C->T 손상 패턴 확인
- [ ] 변이 호출
- [ ] 결과 해석 (HG002와 비교)
