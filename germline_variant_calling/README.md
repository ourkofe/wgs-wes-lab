# germline_variant_calling

GATK Best Practices로 GIAB HG002 WGS 데이터에서 생식세포 변이(SNP/indel)를
호출하고, GIAB 공식 정답셋과 비교해서 파이프라인 정확도를 검증하는 실습.

## 배경: Variant Calling이 뭔지

사람의 DNA는 레퍼런스 게놈(GRCh38)과 개인마다 조금씩 다릅니다. 이 "다른
지점"을 찾아내는 게 variant calling이에요. 크게 두 종류로 나뉩니다.

- **SNP (Single Nucleotide Polymorphism)**: 염기 하나가 다른 것
- **Indel (Insertion/Deletion)**: 몇 개 염기가 끼워지거나 빠진 것

WGS/WES 데이터로 할 수 있는 분석 중 가장 기본이 되는 질문이고, 유전질환
진단, 집단유전학, 약물유전체 분석 등 대부분의 후속 분석이 여기서 출발합니다.

## 왜 이 데이터인가: GIAB HG002

[Genome in a Bottle (GIAB)](https://www.nist.gov/programs-projects/genome-bottle)는
NIST가 주도하는 컨소시엄으로, 특정 개인(HG002 등)을 여러 시퀀싱 플랫폼으로
반복 분석해서 "이 사람의 진짜 변이는 이렇다"는 **high-confidence 정답셋**을
공식적으로 배포합니다.

이게 이번 실습에서 중요한 이유는, bulk RNA-seq 때 논문 재현이나 single-cell
때 마커 유전자 검증처럼, **"내가 만든 결과가 얼마나 정확한지"를 숫자로
확인할 수 있는 기준**이 있다는 점이에요. 임의의 사람 데이터로 분석하면
결과가 맞는지 확인할 방법이 없는데, GIAB 데이터는 정답이 이미 있어서
검증까지 완결된 실습이 가능합니다.

## 분석 설계

### 목표
1. WGS 데이터에서 GATK Best Practices로 변이 호출
2. GIAB 공식 정답셋과 비교(hap.py)해서 precision/recall/F1 산출
3. 우리 파이프라인이 표준 수준의 정확도를 내는지 확인

### 범위 조절
사람 전체 WGS는 용량이 매우 크므로(수십~100GB대), 이번 실습은
**chr20 하나만** 대상으로 진행합니다. GIAB도 튜토리얼용으로 chr20 subset을
자주 제공하는 편이라, 규모 조절이 자연스러운 선택입니다.

### 도구 (gold standard 구성)

| 단계 | 도구 | 비고 |
|---|---|---|
| QC | FastQC | RNA-seq 실습과 동일 |
| 트리밍 | fastp | RNA-seq 실습과 동일 |
| 정렬 | BWA-MEM | short-read DNA 정렬의 사실상 유일한 표준 |
| 정렬 후처리 | Picard MarkDuplicates | GATK 계열 표준 도구 |
| 품질 재보정 | GATK BQSR | GATK 파이프라인 전제 조건 |
| 변이 호출 | GATK HaplotypeCaller | 이 분야 역사적 gold standard |
| 필터링 | GATK hard filter | 신뢰도 낮은 변이 제거 |
| 정확도 검증 | hap.py | GA4GH 표준 벤치마킹 도구 |

**참고**: 변이 호출기는 GATK HaplotypeCaller가 표준이지만, 최근 Google의
DeepVariant(딥러닝 기반)가 정확도 경쟁에서 앞서는 경우가 많다고 알려져
있습니다. 이번엔 표준 도구로 먼저 완주하고, 여유 있으면 DeepVariant로
같은 데이터를 재분석해 비교하는 것도 좋은 확장이 될 것 같습니다.

## 워크플로우
raw fastq (HG002, chr20 subset)
│
▼
QC (FastQC) - 리드 품질 확인
│
▼
트리밍 (fastp) - 저품질/어댑터 제거
│
▼
정렬 (BWA-MEM) - GRCh38에 매핑
│
▼
정렬 후처리 (MarkDuplicates) - PCR 중복 리드 표시
│
▼
BQSR - 염기 품질 점수 보정
│
▼
변이 호출 (HaplotypeCaller) - SNP/indel 발견
│
▼
변이 필터링 (hard filter) - 신뢰도 낮은 변이 제거
│
▼
정확도 검증 (hap.py) - GIAB 정답셋과 비교, precision/recall 산출

## 검증 기준

hap.py 결과에서 확인할 핵심 지표:

| 지표 | 의미 |
|---|---|
| Precision | 우리가 "변이다"라고 한 것 중 진짜 변이인 비율 |
| Recall (Sensitivity) | 진짜 변이 중 우리가 찾아낸 비율 |
| F1-score | Precision과 Recall의 조화평균 |

GATK Best Practices를 제대로 따르면 SNP는 F1 0.99 이상, indel은 그보다
약간 낮은 수준이 나오는 게 일반적으로 알려져 있습니다. 이 근처 수치가
나오는지가 이번 실습의 성공 기준입니다.

## 리소스 계획

| 단계 | cpus | memory | 비고 |
|---|---|---|---|
| BWA-MEM 정렬 | 16 | 32g | chr20만 대상이라 전체 게놈보다 훨씬 가벼움 |
| GATK 각 단계 | 8~16 | 16~32g | Java 기반이라 메모리 넉넉히 |

## 폴더 구조
germline_variant_calling/
├── README.md - 이 파일
├── ANALYSIS_LOG.md - 진행 기록
├── docs/
│ ├── analysis_design.md
│ └── commands_index.md
├── config/ - 샘플 정보
├── scripts/ - 단계별 스크립트
├── data/ - 원본 fastq (git 제외)
├── ref/ - 레퍼런스 게놈, GIAB 정답셋 (git 제외)
├── results/ - BAM, VCF, hap.py 결과 (무거운 것 제외하고 git 포함)
└── logs/ - 실행 로그

## 진행 상황

- [ ] 데이터/레퍼런스 다운로드
- [ ] QC + 트리밍
- [ ] BWA-MEM 정렬
- [ ] MarkDuplicates + BQSR
- [ ] HaplotypeCaller 변이 호출
- [ ] 필터링
- [ ] hap.py 정확도 검증

## 다음 단계 (2단계)

이 실습 완료 후, 같은 GATK 파이프라인을 **네안데르탈인 고대 DNA
(Svante Pääbo, 2022 노벨 생리의학상 연구)**에 적용해보는 실습으로 이어집니다.
고대 DNA는 화학적 손상 패턴 보정, 현생인류 오염 확인 등 표준 파이프라인에
없는 특수 단계가 추가로 필요해서, 이번 실습에서 기본기를 다진 다음
진행하는 게 자연스럽습니다.
