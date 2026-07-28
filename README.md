# WGS_WES_Practice

WGS(전장 유전체 시퀀싱)/WES(엑솜 시퀀싱) 기반 변이 분석 실습 모음.

## WGS/WES가 뭔지

사람의 DNA는 약 30억 개 염기쌍으로 이루어져 있고, 그 중 실제로 단백질을
만드는 부분(엑손, exon)은 전체의 1~2% 정도밖에 안 됩니다. 이 "어디까지
읽느냐"에 따라 시퀀싱 방식이 나뉩니다.

- **WGS (Whole Genome Sequencing)**: 게놈 전체를 다 읽음. 엑손뿐 아니라
  인트론, 유전자 사이 영역(intergenic region)까지 전부 포함.
- **WES (Whole Exome Sequencing)**: 엑손 부분만 골라서(exome capture)
  읽음. 전체 게놈의 1~2%만 보지만, 그 부분에 집중적으로 더 깊게 읽음.

## WGS vs WES 비교

| 항목 | WGS | WES |
|---|---|---|
| 시퀀싱 범위 | 게놈 전체 | 엑손(단백질 코딩 영역)만 |
| 비용 | 상대적으로 비쌈 | 상대적으로 저렴 |
| 커버리지 깊이 | 보통 30x 안팎 | 같은 비용이면 100x 이상도 가능 |
| 비-코딩 영역 변이 | 발견 가능 | 발견 불가 (애초에 안 읽음) |
| CNV/구조변이 탐지 | 유리 (전체를 고르게 봄) | 불리 (특정 영역만 봐서 경계 판단 어려움) |
| 단백질에 영향 주는 변이 | 발견 가능 | 발견 가능 (오히려 깊은 커버리지로 더 민감) |
| 임상 활용 | 연구, 신생아 스크리닝 등 | 유전질환 진단에서 흔히 사용 (저렴+충분) |

## 각각으로 할 수 있는 분석

두 데이터 다 "레퍼런스 게놈이랑 이 사람 DNA가 어디서 다른가"를 찾는 게
기본이지만, 그 위에서 갈 수 있는 방향이 여러 가지입니다.

### WGS/WES 공통으로 가능한 것
- **Germline variant calling** — 타고난(생식세포) SNP/indel 발견 (가장 기본)
- **Somatic variant calling** — 종양 조직 등에서 후천적으로 생긴 변이 발견
  (정상 조직과 비교하는 pair 분석)
- **Variant annotation** — 발견된 변이가 어떤 유전자에, 어떤 영향을
  주는지(아미노산 변화, 조기 종결 등) 주석 달기
- **집단유전학 분석** — 여러 샘플을 모아서 인구 집단 특성, 유연관계 분석

### WGS에서 더 유리하거나 WGS로만 가능한 것
- **CNV(카피수 변이) 탐지** — 특정 영역이 정상보다 많거나 적게 있는지
- **구조 변이(SV) 탐지** — 큰 규모의 역위, 전위, 결손/중복
- **비-코딩 영역 변이 분석** — 프로모터, 인핸서 등 유전자 발현 조절
  영역의 변이 (엑솜엔 아예 없는 영역)
- **미토콘드리아 DNA 분석** — 게놈 전체를 보다 보면 미토콘드리아 DNA도
  같이 커버됨

### WES가 실용적으로 유리한 것
- **비용 대비 유전질환 진단** — 알려진 유전질환 대부분이 코딩 영역
  변이에서 기인하므로, 저렴하게 깊은 커버리지로 진단 정확도 확보

## 기본 워크플로우: Germline Variant Calling (GATK Best Practices)

WGS든 WES든 뼈대는 거의 동일합니다. WES는 여기에 "엑솜 캡처 대상 영역"
관련 QC 단계가 하나 더 붙는 정도가 차이입니다.

raw fastq
│
▼
QC (FastQC) - 리드 품질 확인
│
▼
트리밍 (fastp) - 저품질/어댑터 제거
│
▼
정렬 (BWA-MEM) - 레퍼런스 게놈에 매핑
│
▼
정렬 후처리 (Mark Duplicates) - PCR 중복 리드 표시
│
▼
BQSR (Base Quality Score Recalibration) - 염기 품질 점수 보정
│
▼
변이 호출 (HaplotypeCaller) - 개별 샘플의 후보 변이 발견
│
▼
Joint Genotyping - 여러 샘플을 합쳐서 최종 변이 집합 결정
│
▼
변이 필터링 (VQSR 또는 hard filter) - 신뢰도 낮은 변이 걸러내기
│
▼
변이 주석 (VEP/ANNOVAR) - 변이의 기능적 의미 부여

**WES 전용 추가 단계**: 정렬 직후 "엑솜 캡처 대상 영역(target region)에
리드가 얼마나 잘 몰렸는지"(on-target rate) QC를 하나 더 거칩니다. 이게
낮으면 캡처 실험 자체가 실패한 것으로 봐야 합니다.

## 도구 (계획)

| 단계 | 도구 |
|---|---|
| QC/트리밍 | FastQC, fastp (RNA-seq 실습과 동일) |
| 정렬 | BWA-MEM (gold standard) |
| 변이 호출 파이프라인 | GATK (gold standard, Broad Institute 공식) |
| 변이 주석 | VEP 또는 ANNOVAR |

## 실습 목록

### 기초
- [ ] **germline_variant_calling** - GATK best practices로 생식세포 변이 호출

### 확장
- [ ] **somatic_variant_calling** - 종양/정상 쌍 비교 (Mutect2)
- [ ] **cnv_sv_detection** - 카피수 변이, 구조 변이 탐지
- [ ] **variant_annotation** - 변이 기능적 주석
- [ ] **population_genetics** - 여러 샘플 통합 집단유전학 분석

각 실습은 하위 폴더로 구성되며, 폴더 안에 README, ANALYSIS_LOG, scripts 등을
따로 둡니다.

## 참고

이전 실습(`rnaseq-lab`, `longread-seq-lab`)과 마찬가지로:
- 실제 공개 데이터(GIAB 벤치마크 샘플, 1000 Genomes 등)로 진행
- 표준/gold standard 도구 우선 사용
- 무거운 원본 데이터/중간 산출물은 git에서 제외, 가벼운 결과만 커밋
