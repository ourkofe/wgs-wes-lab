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

WGS든 WES든 뼈대는 거의 동일합니다.

1. raw fastq
2. QC (FastQC) — 리드 품질 확인
3. 트리밍 (fastp) — 저품질/어댑터 제거
4. 정렬 (BWA-MEM) — 레퍼런스 게놈에 매핑
5. 정렬 후처리 (MarkDuplicates) — PCR 중복 리드 표시
6. BQSR (Base Quality Score Recalibration) — 염기 품질 점수 보정
7. 변이 호출 (HaplotypeCaller) — 후보 변이 발견
8. 변이 필터링 (hard filter) — 신뢰도 낮은 변이 걸러내기
9. (선택) 변이 주석 (VEP/ANNOVAR) — 변이의 기능적 의미 부여

**실제로는 단일 샘플이면 Joint Genotyping은 생략 가능** (여러 샘플을 합쳐
서 유전형을 같이 결정하는 단계라, 샘플 하나만 볼 때는 필요 없음). 실습에서도
HG002 하나만 다룰 땐 이 단계 없이 진행함.

**WES라면 추가할 단계**: 정렬 직후 "엑솜 캡처 대상 영역(target region)에
리드가 얼마나 잘 몰렸는지"(on-target rate) QC를 하나 더 거침. 이게 낮으면
캡처 실험 자체가 실패한 것으로 봐야 함.

**Somatic(종양/정상)은 다른 갈래**: HaplotypeCaller 대신 Mutect2를 쓰고,
BQSR은 생략하는 게 일반적. 자세한 건 `somatic_variant_calling/` 참고.

## 도구

| 단계 | 도구 |
|---|---|
| QC/트리밍 | FastQC, fastp |
| 정렬 | BWA-MEM / BWA aln (짧은 리드용) |
| 변이 호출 (germline) | GATK HaplotypeCaller |
| 변이 호출 (somatic) | GATK Mutect2 |
| 정확도 검증 | hap.py (germline), GATK SelectVariants concordance (somatic, 고대DNA) |
| 고대 DNA 손상 분석 | mapDamage2 |
| 변이 주석 (예정) | VEP 또는 ANNOVAR |

## 실습 목록

### 완료
- [x] **germline_variant_calling** — GIAB HG002(chr20)로 GATK Best Practices
  완주. hap.py 검증 결과 SNP F1 99.25%, indel F1 99.57%
- [x] **neanderthal_ancient_dna** — Vindija 33.19(Pääbo, 2022 노벨상 연구
  데이터)로 고대 DNA 특화 분석. mapDamage로 deamination 패턴 확인,
  HG002와 변이 비교
- [x] **somatic_variant_calling** — SEQC2 HCC1395/HCC1395BL 전체 게놈으로
  Mutect2 완주. High-Confidence 영역 기준 SNV recall 88.2%/precision 98.1%,
  indel recall 89.1%/precision 60.6%

### 예정
- [ ] **cnv_sv_detection** — 카피수 변이, 구조 변이 탐지
- [ ] **variant_annotation** — 변이 기능적 주석 (VEP)
- [ ] **population_genetics** — 여러 샘플 통합 집단유전학 분석

각 실습은 하위 폴더로 구성되며, 폴더 안에 README, ANALYSIS_LOG, scripts 등을
따로 둡니다.

## 폴더 구조
'''
WGS_WES_Practice/
├── README.md - 이 파일
├── .gitignore
├── germline_variant_calling/
├── neanderthal_ancient_dna/
└── somatic_variant_calling/
'''

## 참고

이전 실습(`rnaseq-lab`, `longread-seq-lab`)과 마찬가지로:
- 실제 공개 데이터(GIAB, SEQC2, ENA 등)로 진행
- 표준/gold standard 도구 우선 사용
- 무거운 원본 데이터/중간 산출물은 git에서 제외, 가벼운 결과만 커밋

### 도커/공용 서버 운영 관련 교훈 (somatic_variant_calling에서 습득)

대용량 데이터를 다룰 때는 도커 컨테이너가 `-v`로 명시 마운트 안 한 경로
(임시 파일, 컨테이너 자체 로그)에 뭘 쓰는지 항상 주의해야 함. 이게 호스트
루트 파티션을 채워서 도커 데몬 자체가 죽는 사고로 이어질 수 있음. 이후
모든 스크립트에 다음을 기본 적용:
- `-v "$REPO_ROOT/tmp":/tmp`, `-e TMPDIR=/tmp` — 임시파일 격리
- `--log-driver=none` — 컨테이너 자체 로그 비활성화 (호스트에 별도 로그
  남기므로 실질적 손실 없음)
- GATK 등 자바 도구는 `-Djava.io.tmpdir=/tmp`, `--tmp-dir /tmp`도 추가
