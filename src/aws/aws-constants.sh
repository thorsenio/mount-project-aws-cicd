#!/usr/bin/env bash

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
