# 작업 기록

## 00. 세팅
- 서버: cpu 128core, ram 503g, storage 87t (/BiO)
- 작업 위치: WGS_WES_Practice/germline_variant_calling
- rnaseq-lab, longread-seq-lab 다음 실습, 이번엔 발현량/isoform이 아니라
  DNA 변이(SNP/indel) 발견이 목표 - 완전히 다른 축의 분석

## 01. 데이터/도구 선정
- 데이터: GIAB HG002 (Ashkenazim trio 아들), NIST 공식 벤치마크 샘플
  - 정답 변이 목록이 있어서 파이프라인 정확도를 숫자로 검증 가능
- 범위: chr20만 (전체 WGS 300x 커버리지라 용량이 너무 커서)
- 도구: BWA-MEM(정렬) + GATK Best Practices(변이호출) + hap.py(검증)
  - BWA-MEM, GATK는 이 분야 국룰. 변이 호출기는 GATK가 표준이지만
    DeepVariant(딥러닝)가 정확도 경쟁에서 앞서는 경우도 많다고 알려짐

## 02. 레퍼런스 다운로드
- GIAB 권장 GRCh38 (ALT contig 없는 버전), 886MB 압축, 약 3.1GB 압축해제

## 03. HG002 chr20 데이터 확보
- 원본 300x 전체 BAM을 다 안 받고, samtools remote view로 chr20만 스트리밍 추출
- 중간에 SSL 인증서 에러 (컨테이너 내 CA 인증서 목록이 오래됨)
  -> 호스트의 /etc/ssl/certs를 컨테이너에 마운트해서 해결
- 최종 42GB (300x 커버리지라 예상(10~20GB)보다 훨씬 큼, 1억 2500만 리드)
- BAM -> paired-end fastq로 변환해서 재정렬 연습용으로 사용

## 04. GIAB truth set 다운로드
- HG002 GRCh38 v4.2.1 benchmark VCF + confident regions BED
- 순조롭게 다운로드됨

## 05. QC + 트리밍
- FastQC, fastp - bulk RNA-seq 때와 동일한 방식으로 문제없이 진행

## 06. BWA-MEM 정렬
- 인덱스 빌드 약 57분 (사람 전체 게놈이라 시간 걸림, STAR보다는 인덱스 자체는 가벼움)
- 정렬 약 49분 + sort/index
- Read Group(-R) 필수 - GATK 후속 단계가 샘플 메타데이터 요구
- 최종 BAM 11GB

## 07. MarkDuplicates
- broadinstitute/gatk:4.6.2.0 이미지 사용
- 약 15분 소요, 정상 완료 (Tool returned: 0)

## 08. known sites 다운로드 + 삽질
- 원래 계획: GCS(storage.googleapis.com)에서 dbSNP, Mills indels 다운로드
  -> 403 Forbidden 에러 (구글 정책 변경으로 추정)
- 해결: 같은 데이터의 AWS S3 미러(s3://broad-references) 이용
  - Broad Institute가 AWS Open Data Sponsorship Program으로 무료 배포 중
  - aws s3 cp --no-sign-request 로 정상 다운로드, 총 11GB

## 09. 시퀀스 딕셔너리(.dict) 생성
- GATK CreateSequenceDictionary, 몇 초 만에 완료

## 10. BQSR
- BaseRecalibrator + ApplyBQSR, 약 40분 소요
- 결과 BAM 인덱스 파일명이 samtools 관례(.bam.bai)와 달리 GATK 스타일(.bai)로
  생성됨 -> 심볼릭 링크로 양쪽 이름 다 대응하게 처리

## 11. HaplotypeCaller 변이 호출
- 약 2시간 23분 소요 (지금까지 단계 중 가장 오래 걸림)
- 총 132,247개 변이 검출 (SNP + indel)
- 필터링 전 상태 (FILTER 컬럼 전부 '.')

## 12. 변이 필터링 (hard filter)
- SNP/indel 따로 분리해서 각각 GATK 공식 권장 기준으로 필터링
  (QD, FS, MQ, MQRankSum, ReadPosRankSum, SOR)
- 다시 병합 -> 132,247개 중 107,085개(81%) PASS

## 13. hap.py 정확도 검증
- pkrusche/hap.py 이미지에서 --user 옵션 때문에 UID 조회 실패 에러
  -> 호스트의 /etc/passwd, /etc/group을 컨테이너에 마운트해서 해결

### 최종 결과 (PASS 기준)

| 유형 | Recall | Precision | F1-score |
|---|---|---|---|
| SNP | 98.59% | 99.91% | 99.25% |
| Indel | 99.40% | 99.74% | 99.57% |

목표(SNP F1 0.99 이상)를 정확히 달성. GATK Best Practices를 제대로
따르면 나오는 정상 범위의 정확도가 실제로 재현됨.

## 겪었던 삽질 총정리
1. 300x 커버리지 예상보다 큼 (10~20GB 추정 -> 실제 42GB)
2. GCS SSL 인증서 문제 -> 호스트 인증서 마운트로 해결
3. GCS 403 Forbidden (버킷 정책 변경 추정) -> AWS S3 미러로 우회
4. GATK 인덱스 파일명 관례가 samtools와 다름 (.bai vs .bam.bai)
5. hap.py 컨테이너에서 --user 옵션 쓸 때 UID 조회 실패 -> /etc/passwd 마운트

## 결론
- bulk RNA-seq(발현량) -> single-cell(세포 구분) -> long-read(isoform) ->
  variant calling(DNA 서열 자체 비교)까지, RNA-seq 로드맵과는 다른 축의
  분석을 완주
- 표준 파이프라인(BWA-MEM + GATK)이 국제 벤치마크 기준 정확도를 실제로
  달성하는 것을 직접 확인
- 다음 확장 후보: DeepVariant로 같은 데이터 재분석해서 GATK와 비교,
  또는 2단계(네안데르탈인 고대 DNA) 진행
