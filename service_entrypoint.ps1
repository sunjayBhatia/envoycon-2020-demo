Start-Process -FilePath "python" -ArgumentList @("./service/main.py") -WorkingDirectory $pwd -RedirectStandardError './logs/serv-err.log' -RedirectStandardOutput './logs/serv-out.log'

$serviceName = "service$env:ServiceId"
.\envoy-static.exe --config-path .\envoy-config\bootstrap.yaml --log-path .\logs\envoy.log --service-cluster $serviceName --service-node $serviceName-0