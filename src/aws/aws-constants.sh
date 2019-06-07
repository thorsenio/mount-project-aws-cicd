#!/usr/bin/env bash

AWS_GLOBAL_REGION='us-east-1'

# Route 53 hosted zone ID for Cloudfront, all regions
# https://docs.aws.amazon.com/general/latest/gr/rande.html#cf_region
CLOUDFRONT_HOSTED_ZONE_ID='Z2FDTNDATAQYW2'

# Route 53 hosted zone IDs for S3, by region
# https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
declare -A S3_HOSTED_ZONE_ID_REGION_MAP
S3_HOSTED_ZONE_ID_REGION_MAP=(
  ['ap-south-1']='Z11RGJOFQNVJUP'
  ['ap-northeast-1']='Z2M4EHUR26P7ZW'
  ['ap-northeast-2']='Z3W03O7B5YMIYP'
  ['ap-northeast-3']='Z2YQB5RD63NC85'
  ['ap-southeast-1']='Z3O0J2DXBE1FTB'
  ['ap-southeast-2']='Z1WCIGYICN2BYD'
  ['ca-central-1']='Z1QDHH18159H29'
  ['eu-central-1']='Z21DNDUVLTQW6Q'
  ['eu-north-1']='Z3BAZG2TWCNX0D'
  ['eu-west-1']='Z1BKCTXD74EZPE'
  ['eu-west-2']='Z3GKZC51ZF0DB4'
  ['eu-west-3']='Z3R1K369G5AVDG'
  ['us-east-1']='Z3AQBSTGFYJSTF'
  ['us-east-2']='Z2O1EMRO9K5GLX'
  ['us-west-1']='Z2F56UZL2M1ACD'
  ['us-west-2']='Z3BJ6K6RIION7M'
  ['sa-east-1']='Z7KQH4QJS55SO'
)

# These are the hosted zone IDs for application LBs and classic LBs
# For network LBs, see https://docs.aws.amazon.com/general/latest/gr/rande.html#elb_region
declare -A ELB_HOSTED_ZONE_ID_REGION_MAP
ELB_HOSTED_ZONE_ID_REGION_MAP=(
  ['ap-east-1']='Z3DQVH9N71FHZ0'
  ['ap-south-1']='ZP97RAFLXTNZK'
  ['ap-northeast-1']='Z14GRHDCWA56QT'
  ['ap-northeast-2']='ZWKZPGTI48KDX'
  ['ap-northeast-3']='Z5LXEXXYW11ES'
  ['ap-southeast-1']='Z1LMS91P8CMLE5'
  ['ap-southeast-2']='Z1GM3OXH4ZPM65'
  ['ca-central-1']='ZQSVJUPU6J1EY'
  ['eu-central-1']='Z215JYRZR1TBD5'
  ['eu-north-1']='Z23TAZ6LKFMNIO'
  ['eu-west-1']='Z32O12XQLNTSW2'
  ['eu-west-2']='ZHURV8PSTC4K8'
  ['eu-west-3']='Z3Q77PNBQS71R4'
  ['us-east-1']='Z35SXDOTRQ7X7K'
  ['us-east-2']='Z3AADJGX6KTTL2'
  ['us-west-1']='Z368ELLRRE2KJ0'
  ['us-west-2']='Z1H1FL5HABSF5'
  ['sa-east-1']='Z23TAZ6LKFMNIO'
)
