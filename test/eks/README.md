## about docs
- kube-proxy: helm chart가 없어서 aws add-on으로 설치
- coredns, vpc-cni의 경우 helm으로 관리하는 것이 좋을까, aws add-on으로 관리하는게 좋을까에 대한 고민
- eks managed node group의 node가 각 az에 프로비저닝되는 것을 보장하기 위해 az 별 mng를 관리하는게 좋을까?

#### grafana alloy
- `prometheus.exporter.cloudwatch` component는 prometheus community의 yace를 임배딩한 구성 요소로 동일한 동작(cloudwatch metric 수집)을 수행한다. 몇 가지 주의 사항이 있다.
    - aws 서비스가 제공하는 기본적인 metric은 보통 1분 주기의 metric을 제공한다.
    - cloudwatch의 metric 조회 `GetMetricData` 동작 수행 시 집계를 위한 period, statistics 필드가 필수다. cloudwatch의 원본 데이터를 그대로 수집하기 위해서는 원본 metric의 집계 주기와 period를 같은 값으로 설정하면된다. 이렇게하면 period 내 data point가 1개이기 때문에 어떤 statistics를 사용하더라도 동일 값이 조회될 것이다. yace는 수집된 metric 이름에 statistics를 suffix로 자동 추가한다.