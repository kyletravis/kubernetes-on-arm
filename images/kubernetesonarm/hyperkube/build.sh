cd "$( dirname "${BASH_SOURCE[0]}" )"

cp ../_bin/latest/hyperkube .

docker build -t kubernetesonarm/hyperkube .