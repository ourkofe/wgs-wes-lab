## 00. 데이터/레퍼런스 준비
- 데이터: ENA PRJEB21157 (Prüfer et al. 2017, Science) - Vindija 33.19 네안데르탈인
- run 5개 선정 (ERR2000715, 716, 718, 720, 722) - merged fastq만, 전체 992GB 중
  가장 큰 것들로 골라서 약 45GB 규모로 조절
  - 손상 패턴 분석/비교 관찰은 1개로도 충분하지만, 변이 호출까지 의미 있게
    하려면 커버리지가 필요해서 5개로 확대
- 레퍼런스: germline_variant_calling의 GRCh38_no_alt.fasta 재사용 예정
  (구체적인 재사용 방식은 02번 참고 - 심볼릭 링크 시도했다가 문제 있어서 복사로 변경)
  (BQSR용 known sites는 이번엔 불필요 - 현생인류 오류패턴 기반이라 고대DNA엔 미적용)
- 다운로드 완료, 총 42GB

## 01. QC (FastQC)
- 5개 run 전부 FastQC 정상 완료
- Sequence Length Distribution에서 "warn" 발생, Sequence length 범위 1-141bp
  -> 일반 시퀀싱(HG002는 고정길이)과 다른 고대 DNA 특유의 패턴
- 길이 분포 확인: 최빈값이 40-49bp 구간(샘플당 약 2,700만 리드), 그 아래로도
  10-30bp 구간에 수십만~200만 리드씩 분포 -> 조각이 짧게 부서진 게 실제로 확인됨

## 02. 레퍼런스 재사용 이슈
- 심볼릭 링크(../../germline_variant_calling/ref/...)로 재사용 시도했으나
  bwa 컨테이너에서 "fail to locate the index" 에러
  -> 원인: 도커 볼륨 마운트가 neanderthal_ancient_dna 폴더까지만 되어 있어서,
     심볼릭 링크가 가리키는 상위 폴더(germline_variant_calling) 실제 파일이
     컨테이너 안에서 안 보였음
  -> 해결: 심볼릭 링크 대신 실제 파일로 복사 (cp), 약 6.5GB 중복 사용

## 03. 정렬 (BWA aln)
- 리드 길이가 짧고 다양해서 BWA-MEM 대신 BWA aln 사용
- 고대 DNA 표준 파라미터: -l 1024 (seeding 사실상 비활성화), -n 0.01 (관대한 미스매치)
- Read Group을 run별로 지정 (SM:Vindija33.19 공통, ID는 run마다 다르게)
- 5개 run 순차 실행, run당 대략 40분 이상 소요 (ERR2000722 기준 Real time 2663초)
- 5개 run 전부 정상 완료 (.sorted.bam + .bai 5세트 확인)

## 04. MarkDuplicates
- broadinstitute/gatk:4.6.2.0, 5개 run 각각 처리
- 기본 옵션으로 실행 시 에러 발생:
  "SAM validation error: INVALID_MAPPING_QUALITY: MAPQ should be 0 for
  unmapped read" -> BWA aln/samse 출력물에서 흔히 나타나는 사소한 포맷 결함
- --VALIDATION_STRINGENCY LENIENT 옵션 추가해서 해결 (심각한 손상이 아니라
  이 정도 규칙 위반은 무시하고 진행하도록 완화)
- 5개 run 전부 정상 완료 (.markdup.bam + .bai 5세트)
- 참고: mapDamage(05번)를 이 단계보다 먼저 돌렸음. 표준 순서는 정렬 ->
  중복제거 -> 손상분석이지만, MarkDuplicates가 중복 리드를 "제거"가 아니라
  "표시"만 하는 방식(REMOVE_DUPLICATES false)이라 순서를 바꿔도 mapDamage
  결론(재현되는 C->T 패턴)에는 영향 없다고 판단

## 05. mapDamage 손상 패턴 분석
- 이미지: quay.io/biocontainers/mapdamage2:2.2.3--py312h4711d71_0
- --no-stats 옵션으로 시각화만 (재보정은 생략)
- mapDamage는 싱글스레드 도구라 --cpus=4 줘도 실제로는 1코어만 사용 (정상 동작)
- 5개 run 전부 Successful run, Fragmisincorporation_plot.pdf 생성 확인
- sorted.bam(중복표시 전) 기준으로 실행함 (04번 참고)

### 결과 해석
- 초기 계산에서 컬럼 인덱싱 실수 (misincorporation.txt에서 T 총개수를 C>T로
  착각, 43%로 잘못 계산) -> 헤더 재확인 후 C>T가 11번째 컬럼임을 확인, 정정

- 5개 run 전체 C->T 비율 (3' 말단, chr1 기준)

| Pos | 범위 (5개 run) |
|---|---|
| 1 | 5.67~5.75% |
| 2 | 2.12~2.18% |
| 3 | 0.15~0.19% |

- 5개 run 모두 거의 동일한 패턴 -> 우연이 아니라 이 개체의 일관된 화학적
  특성으로 확인됨 (재현성 검증 완료)
- 배경 수준(0.15% 근처) 대비 1번 위치가 약 35배, 2번 위치가 약 13배 높음
- 5' 말단에서도 유사한 패턴의 C->T 상승 확인 (G->A는 이 위치에서 안 튐 ->
  merged read 특성상 3' 정보가 C->T 형태로 흡수된 것으로 추정)
- 이게 진짜 고대 DNA임을 보여주는 핵심 화학적 증거 - 이번 실습 핵심 목표 달성

## 06. 변이 호출 (HaplotypeCaller)
- 5개 markdup.bam을 하나의 샘플(-I 5번)로 합쳐서 chr20 대상으로 호출
- BQSR 생략 (00번에서 정한 대로, 현생인류 오류패턴 기반이라 고대DNA엔 부적합)
- 소요시간 10분 (HG002는 143분 - 커버리지 차이로 인한 것으로 추정)
- 필터링된 리드 비율 약 28% (HG002는 3.6%) -> 고대 DNA 특성상 매핑 품질
  낮은 리드가 더 많이 걸러진 것으로 추정
- 총 37,235개 변이 검출 (필터링 전 raw 상태 그대로)
- 참고: 이번엔 SNP/indel hard filter를 따로 안 거치고 raw VCF를 그대로
  비교에 사용 (이번 실습 목적이 "정확도 검증"이 아니라 "생물학적 관찰"이라
  판단, 대신 discordant 변이 해석 시 QUAL 값으로 신뢰도를 나눠서 봄)

## 07. HG002와 비교
- vindija_chr20.raw.vcf.gz (37,235개) vs HG002_chr20.final.vcf.gz (132,247개) 비교

| 구분 | 개수 | 비율 |
|---|---|---|
| 전체 Vindija 변이 | 37,235 | 100% |
| HG002와 concordant | 12,957 | 34.8% |
| HG002와 discordant | 24,278 | 65.2% |
| discordant 중 QUAL>100 | 8,131 | 21.8% |

### 해석
- 약 35% 겹침 -> 인류 공통 조상 유래 변이 또는 인류 전체에 흔한 다형성으로 추정
- discordant 65% 중 상당수(약 2/3)는 QUAL 100 미만 -> 낮은 커버리지(1-2x)로
  인한 노이즈 가능성 높음, 그대로 "네안데르탈인 특이 변이"로 해석하면 안 됨
- QUAL>100인 약 8,100개 정도가 상대적으로 신뢰할 만한 특이 변이 후보
- 주의: HG002 한 명과의 비교라서, discordant 변이 중 상당수는 "네안데르탈인
  특이"가 아니라 "이 특정 현생인류 개인에게 없을 뿐인 흔한 변이"일 수 있음
  (제대로 하려면 다수의 현생인류 참조 패널과 비교해야 함 - 이번 실습 범위 밖)

## 최종 결론
- 손상 패턴(mapDamage): 5개 run 모두 일관된 C->T deamination 확인, 진짜
  고대 DNA임을 화학적으로 증명
- 변이 비교: 네안데르탈인과 현생인류(HG002) 사이 약 1/3의 변이가 공유됨,
  나머지는 개체별/계통별 차이 또는 데이터 한계(낮은 커버리지)로 설명 가능
- 표준 GATK 파이프라인을 고대 DNA 특성(짧은 조각, BWA aln 파라미터, BQSR
  생략, VALIDATION_STRINGENCY 완화)에 맞게 조정해서 완주함
- 겪었던 주요 삽질: 레퍼런스 심볼릭 링크 도커 마운트 문제, MarkDuplicates
  SAM validation 에러, mapDamage 컬럼 인덱싱 계산 실수
- 이번 실습 목표(고대 DNA 특성 확인 + 현생인류와의 비교) 달성
