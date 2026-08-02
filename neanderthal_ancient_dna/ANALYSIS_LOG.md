## 00. 데이터/레퍼런스 준비
- 데이터: ENA PRJEB21157 (Prüfer et al. 2017, Science) - Vindija 33.19 네안데르탈인
- run 5개 선정 (ERR2000715, 716, 718, 720, 722) - merged fastq만, 전체 992GB 중
  가장 큰 것들로 골라서 약 45GB 규모로 조절
  - 손상 패턴 분석/비교 관찰은 1개로도 충분하지만, 변이 호출까지 의미 있게
    하려면 커버리지가 필요해서 5개로 확대
- 레퍼런스: germline_variant_calling의 GRCh38_no_alt.fasta 심볼릭 링크로 재사용
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
  -> 해결: 심볼릭 링크 대신 실제 파일로 복사 (cp)

## 03. 정렬 (BWA aln)
- 리드 길이가 짧고 다양해서 BWA-MEM 대신 BWA aln 사용
- 고대 DNA 표준 파라미터: -l 1024 (seeding 사실상 비활성화), -n 0.01 (관대한 미스매치)
- Read Group을 run별로 지정 (SM:Vindija33.19 공통, ID는 run마다 다르게)
- 5개 run 순차 실행, run당 대략 40분 이상 소요 (ERR2000722 기준 Real time 2663초)
- 5개 run 전부 정상 완료 (.sorted.bam + .bai 5세트 확인)

## 04. mapDamage 손상 패턴 분석
- 이미지: quay.io/biocontainers/mapdamage2:2.2.3--py312h4711d71_0
- --no-stats 옵션으로 시각화만 (재보정은 생략)
- mapDamage는 싱글스레드 도구라 --cpus=4 줘도 실제로는 1코어만 사용 (정상 동작)
- 5개 run 전부 Successful run, Fragmisincorporation_plot.pdf 생성 확인

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

## 다음 계획 (선택)
- HG002(현생인류) 데이터로 동일한 mapDamage 분석 돌려서 대조군 비교
  (배경 수준 0.15%가 진짜 "정상"인지 직접 증명)
- 여유 있으면 변이 호출(GATK) 및 HG002와의 생물학적 차이 비교
