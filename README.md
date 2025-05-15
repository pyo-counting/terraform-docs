## Summary
- terraform apply, plan 명령어 사용 시 먼저 refresh 작업을 수행(in-memory)한다. refresh 작업은 현재 저장된 terraform state와 현재 상태의 실제 인프라와의 상태를 비교하는 과정이다. refresh 작업이 완료되면 사용자의 코드와 refresh 결과를 다시 한번 비교한 후 결과적으로 현재 코드 -> 실제 인프라 반영을 위한 변경 사항을 찾아낸다. 만약 state 파일에만 존재하는 사항이 있을 경우, 코드와 실제 인프라 사이에는 해당 사항이 없기 때문에 state 파일에서만 삭제되며 terraform plan, terraform apply 명령어 출력으로 확인되지 않는다. 이를 확인하기 위해서는 --refresh-only 명령어를 사용해 확인이 가능하다. ([Refresh state](https://developer.hashicorp.com/terraform/tutorials/state/refresh))
- wrapper module 내부에서 참조하는 경우 cycle 오류 발생할 수 있다. wrapper를 사용하는 것이 좋은지에 대한 고민 필요
- 1개의 alb를 공유하도록 k8s ing를 사용하는 경우 alb의 attribute를 변경하기 위해서 모든 k8s ing manifest를 변경해야하는 번거로움이 있음 -> ing resource가 아닌 tgb crd를 사용하는 것에 대한 고민 필요

## CLI
- terraform plan
    - `-refresh-only`:
    - `-refresh`:
    - `-destroy`: