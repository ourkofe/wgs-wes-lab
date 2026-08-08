## 00. 데이터/설계
- 데이터: SEQC2 컨소시엄 HCC1395(종양)/HCC1395BL(정상) 매칭 유방암 세포주 쌍
  - SRR7890824(종양, 34x), SRR7890827(정상, 47x), Illumina HiSeq X WGS
  - fastq 합계 184.5GB - 지금까지 중 가장 큰 규모, chr20 등으로 축소 안 하고
    전체 게놈으로 진행 (리소스 크게 쓰는 실습 목표)
- 레퍼런스: germline_variant_calling의 GRCh38_no_alt.fasta 복사 재사용
- Truth set: SEQC2 공식 v1.2.1 (high-confidence_sSNV/sINDEL_in_HC_regions,
  High-Confidence_Regions bed) - SNV 39,447개, indel 1,602개

## 01. 다운로드
- ENA에서 wget으로 종양/정상 fastq 각각 다운로드, gzip 무결성 확인까지 완료
- 총 184.5GB 정상 완료

## 02. 도커 데몬 크래시 사건 (중요 트러블슈팅)
- BWA-MEM 정렬 도중 "Cannot connect to the Docker daemon" 에러로 전체 크래시
- 원인 조사 결과: 루트 파티션(/dev/sda6, 408GB)이 100% 가득 참
- 원인: 컨테이너가 -v로 명시 마운트 안 한 경로(특히 GATK/자바 도구의 기본
  tmp 경로, 컨테이너 stdout/stderr 로그)가 전부 호스트 루트 파티션
  (/var/lib/docker)에 쌓이고 있었음. 지난 여러 프로젝트(HG002, 네안데르탈인)
  에서 누적된 것으로 추정
- 확인: 사용자 홈 디렉토리(/BiO)는 전혀 문제 없었음 (du -sh ~/*로 확인),
  루트 파티션 문제는 도커 이미지(28.9GB)+임시파일 누적이 원인
- 관리자 조치로 루트 파티션 100%->32% 복구, 도커 데몬 재시작으로 정상화

## 03. 재발 방지 조치 (이후 모든 스크립트에 기본 적용)
- 모든 docker run에 다음 옵션 추가:
  - -v "$REPO_ROOT/tmp":/tmp (임시파일 사용자 디렉토리로)
  - -e TMPDIR=/tmp (환경변수로 명시)
  - --log-driver=none (컨테이너 stdout/stderr 로그 자체를 안 남김,
    우리는 어차피 nohup으로 호스트에 로그 저장하므로 실질적 손실 없음)
  - GATK(자바) 도구는 추가로 -Djava.io.tmpdir=/tmp, --tmp-dir /tmp 도 명시
- 이후 39시간짜리 Mutect2 등 대형 작업에서도 루트 파티션 완전히 안정
  (157G/41%로 고정 유지 확인)
- 참고: 도커 이미지 자체(28.9GB)는 사용자 권한으로 위치 변경 불가
  (관리자가 daemon.json의 data-root를 옮겨야 근본 해결)

## 04. BWA-MEM 정렬
- 종양/정상 각각 정렬, Read Group SM 태그로 HCC1395/HCC1395BL 구분
- 정상 샘플 정렬이 크래시로 한 번 처음부터 다시 진행 (03번 조치 반영 후 재시작)
- 최종 결과: normal.sorted.bam 78.3GB, tumor.sorted.bam 72.0GB
- 정상 샘플 정렬만 약 8~10시간+ 소요 (전체 게놈, 30-47x 커버리지)

## 05. MarkDuplicates
- 두 샘플 각각 처리, --VALIDATION_STRINGENCY LENIENT 적용
  (네안데르탈인 프로젝트에서 겪었던 BWA 출력물 SAM validation 에러 미리 방지)
- 결과: tumor.markdup.bam 85.8GB, normal.markdup.bam 93.1GB

## 06. Mutect2 변이 호출
- 종양+정상 BAM 동시 입력, -tumor/-normal로 샘플 구분
- 전체 게놈 대상, BQSR 없이 진행 (germline과 달리 somatic은 표준
  파이프라인에 BQSR이 필수 단계로 명시되지 않음)
- 소요시간 2,375분 (약 39.6시간) - 이번 실습 중 가장 오래 걸린 단계
- 결과: 439,985개 후보 변이 (raw, 필터링 전)

## 07. FilterMutectCalls
- Mutect2 자체 통계(.stats) 기반 필터링
- 129,060개(29.3%) PASS, 나머지는 base_qual/normal_artifact/strand_bias/
  clustered_events/weak_evidence 등으로 필터링됨
- 소요시간 3.9분 (가벼움)

## 08-09. SEQC2 truth set과 비교
- GATK SelectVariants --concordance/--discordance로 SNV/INDEL 각각 비교
- 1차: 전체 게놈 기준 (High-Confidence 영역 제한 없음)

| 지표 | SNV | INDEL |
|---|---|---|
| PASS 총 | 109,657 | 18,383 |
| Concordant | 34,803 | 1,428 |
| Precision | 31.7% | 7.8% |

- 2차: High-Confidence 영역(BED)으로 제한 (09번, 브랜치 스크립트로 분리)

| 지표 | SNV | INDEL |
|---|---|---|
| PASS 총 | 35,465 | 2,354 |
| Concordant | 34,803 | 1,427 |
| Discordant | 662 | 927 |
| **Precision** | **98.1%** | **60.6%** |
| **Recall** (vs truth 39,447/1,602) | **88.2%** | **89.1%** |

### 해석
- 1차(전체 게놈) precision이 낮았던 건 대부분 "진짜 오류"가 아니라
  "truth set이 커버 안 하는 영역이라 비교 자체가 불가능했던 것"이었음.
  High-Confidence 영역으로 제한하니 SNV precision이 31.7%->98.1%로 완전히
  뒤집힘 - 벤치마킹 시 "비교 가능한 영역"으로 제한하는 게 왜 중요한지
  직접 확인된 사례
- SNV는 germline(HG002 F1 99.25%)에 근접하는 수준(recall 88.2%,
  precision 98.1%)까지 나옴
- INDEL은 SNV보다 훨씬 어려움 (precision 60.6%) - 짧은 반복서열 근처에서
  정렬 자체가 애매해지기 쉬운 somatic indel calling의 알려진 특성과 일치

## 최종 결론
- Mutect2 + FilterMutectCalls 표준 파이프라인으로 SEQC2 공식 벤치마크
  기준 recall 88~89%, (HC 영역 기준) precision 98%(SNV)/61%(indel) 달성
- germline(HG002) 대비 somatic calling이 확실히 더 어려운 문제임을
  수치로 확인 (특히 indel)
- 부수적으로 얻은 값진 경험: 도커 인프라 관점에서 "컨테이너가 마운트
  안 된 경로에 뭘 쓰는지" 이해하고 통제하는 법 (tmp 마운트, 로그 드라이버,
  루트 파티션 문제 진단/해결까지)
- 이번 wgs-wes-lab 실습 시리즈(germline HG002 -> 고대DNA -> somatic) 완주
